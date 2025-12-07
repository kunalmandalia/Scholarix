import SwiftUI

struct AcademicView: View {
    @StateObject private var viewModel = AcademicViewModel()
    @EnvironmentObject var menuManager: MenuManager
    
    // REMOVED: All local theme state (The old @AppStorage("isDarkMode") variable).
    // Theme is now handled globally and inherited correctly.
    
    @State private var showingAddSheet = false
    @State private var selectedCourse: Course?
    @State private var selectedDeadline: Deadline?
    @State private var selectedTab = 0
    @State private var isListMode = false
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            // FIX: Removed ZStack. We use VStack as the main content container.
            VStack(spacing: 0) {
                
                // Picker is now fully contained in the main VStack
                Picker("View", selection: $selectedTab) {
                    Text("Courses").tag(0)
                    Text("Planner").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top)
                .background(Color(.systemGroupedBackground))
                
                if selectedTab == 0 {
                    coursesList
                } else {
                    plannerView
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea(.all, edges: .bottom))
            
            // --- Navigation Links (Hidden, must exist in the hierarchy) ---
            .background(
                NavigationLink(destination: EditCourseView(viewModel: viewModel, courseToEdit: selectedCourse ?? Course.placeholder()), tag: selectedCourse ?? Course.placeholder(), selection: $selectedCourse) { EmptyView() }
            )
            .background(
                Group {
                    if let deadline = selectedDeadline {
                        NavigationLink(destination: EditDeadlineView(viewModel: viewModel, deadlineToEdit: deadline), tag: deadline.id ?? "", selection: Binding(get: { selectedDeadline?.id }, set: { _ in self.selectedDeadline = nil })) { EmptyView() }
                    } else {
                        EmptyView()
                    }
                }
            )
            
            .navigationTitle("Academic Hub")
            .navigationBarTitleDisplayMode(.inline)
            
            // --- Bottom Action Bar is applied as a reliable OVERLAY ---
            .overlay(alignment: .bottom) {
                bottomActionBar
            }
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { menuManager.open() }) {
                        Image(systemName: "line.3.horizontal").font(.title2).foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if selectedTab == 1 {
                            Button(action: { withAnimation { isListMode.toggle() } }) {
                                Image(systemName: isListMode ? "calendar" : "list.bullet").font(.body)
                            }
                            .padding(.trailing, 8)
                        }
                        // FIX: Remove the 'isDarkMode: $isDarkMode' argument (Line 279)
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape.fill")
                        }
                    }
                }
            }
            // FIX for Blur/Transparency: Force the Navigation Bar to use material
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Material.ultraThin, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
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
    
    var coursesList: some View {
        List {
            Section {
                GPACard(weighted: viewModel.weightedGPA, unweighted: viewModel.unweightedGPA)
                    .listRowInsets(EdgeInsets())
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
        .padding(.bottom, 100) // IMPORTANT: Adds space for the persistent sticky footer
    }
    
    var plannerView: some View {
        Group {
            if isListMode {
                List {
                    if viewModel.filteredDeadlines.isEmpty {
                        Text("No upcoming items").foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.filteredDeadlines) { deadline in
                            HStack {
                                Button(action: { withAnimation { viewModel.toggleCompletion(deadline: deadline) } }) {
                                    Image(systemName: deadline.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(deadline.isCompleted ? .green : .secondary)
                                }
                                VStack(alignment: .leading) {
                                    Text(deadline.title).strikethrough(deadline.isCompleted)
                                    Text(deadline.dueDate, style: .date).font(.caption).foregroundColor(.secondary)
                                }
                            }
                            .swipeActions(edge: .leading) { Button { selectedDeadline = deadline } label: { Label("Edit", systemImage: "pencil") }.tint(.orange) }
                            .swipeActions(edge: .trailing) { Button(role: .destructive) { viewModel.deleteDeadline(deadline: deadline) } label: { Label("Delete", systemImage: "trash") } }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .padding(.bottom, 100) // IMPORTANT: Adds space for the persistent sticky footer
            } else {
                CalendarView(
                    deadlines: viewModel.filteredDeadlines,
                    selectedDeadline: $selectedDeadline,
                    onDelete: { viewModel.deleteDeadline(deadline: $0) },
                    onToggle: { viewModel.toggleCompletion(deadline: $0) }
                )
            }
        }
    }
    
    var bottomActionBar: some View {
        VStack {
            // Content of the sticky bar
            if isSearching {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray)
                    TextField("Search...", text: $viewModel.searchText).submitLabel(.done)
                    Button(action: { withAnimation { isSearching = false; viewModel.searchText = "" } }) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Material.regular)
                .cornerRadius(25)
                .padding()
            } else {
                ZStack {
                    HStack {
                        Spacer()
                        Button(action: { withAnimation { isSearching = true } }) {
                            Image(systemName: "magnifyingglass")
                                .padding(12)
                                .background(.ultraThinMaterial) // Should render perfectly now
                                .clipShape(Circle())
                        }
                    }
                    Button(action: { showingAddSheet = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text(selectedTab == 0 ? "Add Course" : "Add Task")
                        }
                        .foregroundColor(Color.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 56)
                        .background(Color.blue)
                        .clipShape(Capsule())
                        .shadow(radius: 5)
                    }
                }
                .padding()
            }
            // Ensure padding is applied to lift the bar off the bottom edge
            .padding(.bottom, 8)
        }
        // Apply the Material background to the VStack containing the buttons
        .background(Material.bar)
    }
}

struct GPACard: View {
    let weighted: String
    let unweighted: String
    
    var body: some View {
        HStack(spacing: 0) {
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
            
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 1, height: 40)
                .padding(.horizontal, 20)
            
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
        .background(Theme.brandGradient)
        .cornerRadius(20)
        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}
