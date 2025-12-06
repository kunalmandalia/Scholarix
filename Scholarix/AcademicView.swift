import SwiftUI
import FirebaseAuth
import Firebase
import FirebaseFirestore
import Combine

// --- 1. The ViewModel ---
@MainActor
class AcademicViewModel: ObservableObject {
    
    @Published var courses = [Course]()
    @Published var unweightedGPA: String = "0.00"
    @Published var weightedGPA: String = "0.00"
    @Published var deadlines = [Deadline]()
    
    // --- Search Logic ---
    @Published var searchText = ""
    
    // --- App ID for Firestore Path Compliance ---
    private let appId = "scholarix-app"
    
    var filteredCourses: [Course] {
        if searchText.isEmpty { return courses }
        return courses.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.courseLevel.localizedCaseInsensitiveContains(searchText) }
    }
    
    var filteredDeadlines: [Deadline] {
        if searchText.isEmpty { return deadlines }
        return deadlines.filter { $0.title.localizedCaseInsensitiveContains(searchText) || $0.type.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var coursesListener: ListenerRegistration?
    private var deadlinesListener: ListenerRegistration?
    
    // Helper for the base user path: artifacts/{appId}/users/{userId}
    private func userDoc(_ userId: String) -> DocumentReference {
        return Firestore.firestore()
            .collection("artifacts").document(appId)
            .collection("users").document(userId)
    }
    
    func fetchCourses() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        self.coursesListener = userDoc(userId).collection("courses").addSnapshotListener { qs, error in
            if let error = error { print("Error fetching courses: \(error.localizedDescription)"); return }
            guard let docs = qs?.documents else { return }
            self.courses = docs.compactMap { try? $0.data(as: Course.self) }
            self.calculateGPA()
        }
    }
    
    func fetchDeadlines() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        self.deadlinesListener = userDoc(userId).collection("deadlines").order(by: "dueDate").addSnapshotListener { qs, error in
            if let error = error { print("Error fetching deadlines: \(error.localizedDescription)"); return }
            guard let docs = qs?.documents else { return }
            self.deadlines = docs.compactMap { try? $0.data(as: Deadline.self) }
        }
    }
    
    private func calculateGPA() {
        let (u, w) = GPAService.calculate(courses: courses)
        unweightedGPA = u
        weightedGPA = w
    }
    
    func detachListeners() { coursesListener?.remove(); deadlinesListener?.remove() }
    
    // CRUD wrappers
    func deleteCourse(course: Course) {
        guard let uid = Auth.auth().currentUser?.uid, let id = course.id else { return }
        userDoc(uid).collection("courses").document(id).delete()
    }
    
    func deleteDeadline(deadline: Deadline) {
        guard let uid = Auth.auth().currentUser?.uid, let id = deadline.id else { return }
        userDoc(uid).collection("deadlines").document(id).delete()
    }
    
    func updateCourse(course: Course) async throws {
        guard let uid = Auth.auth().currentUser?.uid, let id = course.id else { return }
        try await userDoc(uid).collection("courses").document(id).setData(from: course)
    }
    
    func updateDeadline(deadline: Deadline) async throws {
        guard let uid = Auth.auth().currentUser?.uid, let id = deadline.id else { return }
        try await userDoc(uid).collection("deadlines").document(id).setData(from: deadline)
    }
    
    // --- Toggle Completion Logic ---
    func toggleCompletion(deadline: Deadline) {
        guard let uid = Auth.auth().currentUser?.uid, let id = deadline.id else { return }
        
        var updated = deadline
        updated.isCompleted.toggle()
        
        // Optimistic UI update
        if let index = deadlines.firstIndex(where: { $0.id == id }) {
            deadlines[index] = updated
        }
        
        Task {
            try? await userDoc(uid).collection("deadlines").document(id).setData(from: updated)
        }
    }
}

// --- 2. The View ---
struct AcademicView: View {
    @StateObject private var viewModel = AcademicViewModel()
    @EnvironmentObject var menuManager: MenuManager
    
    // --- Dark Mode State (Global Application) ---
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    @State private var showingAddSheet = false
    @State private var selectedCourse: Course?
    @State private var selectedDeadline: Deadline?
    @State private var selectedTab = 0
    
    // --- View Mode for Planner ---
    @State private var isListMode = false
    
    // Search UI State
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                
                // Navigation Links
                NavigationLink(destination: EditCourseView(viewModel: viewModel, courseToEdit: selectedCourse ?? Course.placeholder()), tag: selectedCourse ?? Course.placeholder(), selection: $selectedCourse) { EmptyView() }
                
                if let deadline = selectedDeadline {
                    NavigationLink(destination: EditDeadlineView(viewModel: viewModel, deadlineToEdit: deadline), tag: deadline.id ?? "", selection: Binding(get: { selectedDeadline?.id }, set: { _ in self.selectedDeadline = nil })) { EmptyView() }
                }
                
                VStack(spacing: 0) {
                    // Top Picker
                    Picker("View", selection: $selectedTab) {
                        Text("Courses").tag(0)
                        Text("Planner").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    if selectedTab == 0 {
                        // --- COURSES TAB ---
                        List {
                            Section {
                                GPACard(weighted: viewModel.weightedGPA, unweighted: viewModel.unweightedGPA)
                                    .listRowInsets(EdgeInsets()) // Remove default padding
                                    .listRowBackground(Color.clear)
                                    .padding(.bottom, 10)
                            }
                            
                            Section(header: Text("My Courses").font(.headline).foregroundColor(.primary)) {
                                if viewModel.filteredCourses.isEmpty && !viewModel.searchText.isEmpty {
                                    Text("No courses match \"\(viewModel.searchText)\"").foregroundColor(.gray)
                                } else if viewModel.courses.isEmpty {
                                    Text("No courses yet. Tap + to add one.").foregroundColor(.gray)
                                } else {
                                    ForEach(viewModel.filteredCourses) { course in
                                        CourseRowView(course: course, onEdit: { selectedCourse = course }, onDelete: { viewModel.deleteCourse(course: course) })
                                            .contentShape(Rectangle())
                                            .swipeActions(edge: .leading) {
                                                Button { selectedCourse = course } label: { Label("Edit", systemImage: "pencil") }.tint(.orange)
                                            }
                                            .swipeActions(edge: .trailing) {
                                                Button(role: .destructive) { viewModel.deleteCourse(course: course) } label: { Label("Delete", systemImage: "trash") }
                                            }
                                    }
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                        
                    } else {
                        // --- PLANNER TAB ---
                        if isListMode {
                            // List Mode
                            List {
                                if viewModel.filteredDeadlines.isEmpty {
                                    VStack(alignment: .center, spacing: 12) {
                                        Image(systemName: "calendar.badge.checkmark")
                                            .font(.system(size: 40))
                                            .foregroundColor(.secondary.opacity(0.5))
                                        Text("No upcoming items")
                                            .font(.headline)
                                        Text("Your schedule is clear!")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 60)
                                    .listRowBackground(Color.clear)
                                } else {
                                    ForEach(viewModel.filteredDeadlines) { deadline in
                                        HStack(alignment: .center, spacing: 12) {
                                            // Checkmark
                                            Button(action: {
                                                withAnimation {
                                                    viewModel.toggleCompletion(deadline: deadline)
                                                }
                                            }) {
                                                Image(systemName: deadline.isCompleted ? "checkmark.circle.fill" : "circle")
                                                    .font(.title2)
                                                    .foregroundColor(deadline.isCompleted ? .green : .secondary.opacity(0.7))
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(deadline.title)
                                                    .font(.headline)
                                                    .strikethrough(deadline.isCompleted, color: .secondary)
                                                    .foregroundColor(deadline.isCompleted ? .secondary : .primary)
                                                
                                                HStack {
                                                    if !deadline.isCompleted {
                                                        Text(deadline.type)
                                                            .font(.system(size: 10, weight: .bold))
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(colorForType(deadline.type).opacity(0.1))
                                                            .cornerRadius(4)
                                                            .foregroundColor(colorForType(deadline.type))
                                                    }
                                                    
                                                    Text(deadline.dueDate, style: .date)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.vertical, 4)
                                        .swipeActions(edge: .leading) { Button { selectedDeadline = deadline } label: { Label("Edit", systemImage: "pencil") }.tint(.orange) }
                                        .swipeActions(edge: .trailing) { Button(role: .destructive) { viewModel.deleteDeadline(deadline: deadline) } label: { Label("Delete", systemImage: "trash") } }
                                    }
                                }
                            }
                            .listStyle(InsetGroupedListStyle())
                        } else {
                            // Calendar Mode
                            CalendarView(
                                deadlines: viewModel.filteredDeadlines,
                                selectedDeadline: $selectedDeadline,
                                onDelete: { deadline in
                                    viewModel.deleteDeadline(deadline: deadline)
                                },
                                onToggle: { deadline in
                                    viewModel.toggleCompletion(deadline: deadline)
                                }
                            )
                        }
                    }
                }
                .navigationTitle("Academic Hub")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { menuManager.open() }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            if selectedTab == 1 {
                                Button(action: { withAnimation { isListMode.toggle() } }) {
                                    Image(systemName: isListMode ? "calendar" : "list.bullet")
                                        .font(.body)
                                }
                                .padding(.trailing, 8)
                            }
                            // PASSING BINDING TO SETTINGS
                            NavigationLink(destination: SettingsView(isDarkMode: $isDarkMode)) {
                                Image(systemName: "gearshape.fill")
                            }
                        }
                    }
                }
                
                // --- CUSTOM BOTTOM BAR ---
                VStack {
                    Spacer()
                    
                    if isSearching {
                        // Expanded Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(.gray)
                            TextField("Search...", text: $viewModel.searchText)
                                .submitLabel(.done)
                            
                            Button(action: {
                                withAnimation(.spring()) {
                                    isSearching = false
                                    viewModel.searchText = ""
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                            }
                        }
                        .padding(10)
                        .background(Material.regular) // Blurry background for better readability
                        .cornerRadius(25)
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        
                    } else {
                        // Centered Pill Button with Floating Search
                        ZStack(alignment: .center) {
                            // 1. Search Button (Floating Right)
                            HStack {
                                Spacer()
                                Button(action: {
                                    withAnimation(.spring()) {
                                        isSearching = true
                                    }
                                }) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.title3)
                                        .foregroundColor(.primary)
                                        .padding(12)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.1), radius: 5)
                                }
                            }
                            
                            // 2. Centered "Add" Pill Button
                            Button(action: { showingAddSheet = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                    Text(selectedTab == 0 ? "Add Course" : "Add Task")
                                        .fontWeight(.semibold)
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 56)
                                .background(
                                    LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .clipShape(Capsule())
                                .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        // --- GLOBAL DARK MODE APPLICATION ---
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .animation(.easeInOut(duration: 0.3), value: isDarkMode)
        // ------------------------------------
        .sheet(isPresented: $showingAddSheet) {
            if selectedTab == 0 {
                AddCourseView(isPresented: $showingAddSheet)
            } else {
                AddDeadlineView(isPresented: $showingAddSheet, courses: viewModel.courses)
            }
        }
        .onAppear {
            viewModel.fetchCourses()
            viewModel.fetchDeadlines()
        }
        .onDisappear {
            viewModel.detachListeners()
        }
    }
    
    private func colorForType(_ type: String) -> Color {
        switch type {
        case "Test": return .red; case "Project": return .purple; case "Essay": return .orange; case "Application": return .pink; case "Event": return .yellow; case "Club": return .mint; case "Sport": return .green; default: return .blue
        }
    }
}

// --- SUBVIEWS ---

// Modern GPA Card
struct GPACard: View {
    let weighted: String
    let unweighted: String
    
    var body: some View {
        HStack(spacing: 0) {
            // Weighted
            VStack(alignment: .leading, spacing: 4) {
                Text("Weighted GPA")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .textCase(.uppercase)
                
                Text(weighted)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 1, height: 40)
                .padding(.horizontal, 20)
            
            // Unweighted
            VStack(alignment: .leading, spacing: 4) {
                Text("Unweighted")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .textCase(.uppercase)
                
                Text(unweighted)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color(red: 0.3, green: 0.2, blue: 0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(20)
        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}
