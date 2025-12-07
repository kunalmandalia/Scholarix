import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddDeadlineView: View {
    @Binding var isPresented: Bool
    let courses: [Course]
    
    // Storing all the task details
    @State private var title = ""
    @State private var type = "Homework"
    @State private var dueDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600) // Default +1 hour
    @State private var isAllDay = false
    @State private var selectedCourseId: String = ""
    @State private var priority = "Medium"
    @State private var details = ""
    
    // Saving state
    @State private var isSaving = false
    @State private var showingErrorAlert = false
    @State private var alertMessage = ""
    
    let types = ["Homework", "Test", "Project", "Essay", "Application", "Event", "Club", "Sport"]
    let priorities = ["Low", "Medium", "High"]
    
    // Helper: Is this an event with a duration?
    var isEvent: Bool { ["Event", "Club", "Sport"].contains(type) }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // Header
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading) {
                                    Text("New Task")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("Add to your schedule")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top)
                            
                            // Details Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("TASK DETAILS")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 0) {
                                    // Title
                                    HStack {
                                        Image(systemName: "pencil.and.outline")
                                            .foregroundColor(.gray)
                                        TextField("Title", text: $title)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                    
                                    Divider().padding(.leading)
                                    
                                    // Type
                                    HStack {
                                        Image(systemName: "tag")
                                            .foregroundColor(.gray)
                                        Text("Type")
                                        Spacer()
                                        Picker("Type", selection: $type) {
                                            ForEach(types, id: \.self) { Text($0).tag($0) }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .accentColor(.blue)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                    
                                    // Event Options
                                    if isEvent {
                                        Divider().padding(.leading)
                                        Toggle(isOn: $isAllDay) {
                                            HStack {
                                                Image(systemName: "clock")
                                                    .foregroundColor(.gray)
                                                Text("All-day")
                                            }
                                        }
                                        .padding()
                                        .background(Color(.secondarySystemGroupedBackground))
                                    }
                                    
                                    Divider().padding(.leading)
                                    
                                    // Date Logic
                                    if isEvent {
                                        if isAllDay {
                                            DatePicker("Date", selection: $dueDate, displayedComponents: [.date])
                                                .padding()
                                                .background(Color(.secondarySystemGroupedBackground))
                                        } else {
                                            DatePicker("Starts", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                                .padding()
                                                .background(Color(.secondarySystemGroupedBackground))
                                                .onChange(of: dueDate) { _, newDate in
                                                    if newDate > endDate {
                                                        endDate = newDate.addingTimeInterval(3600)
                                                    }
                                                }
                                            
                                            Divider().padding(.leading)
                                            
                                            DatePicker("Ends", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                                                .padding()
                                                .background(Color(.secondarySystemGroupedBackground))
                                        }
                                    } else {
                                        // Non-Events (Deadlines) just need one date
                                        // Customized label based on type
                                        let label = (type == "Test" || type == "Essay") ? "Date & Time" : "Due Date"
                                        
                                        DatePicker(label, selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                            .padding()
                                            .background(Color(.secondarySystemGroupedBackground))
                                    }
                                }
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                .padding(.horizontal)
                            }
                            
                            // Additional Info
                            VStack(alignment: .leading, spacing: 16) {
                                Text("ADDITIONAL INFO")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 0) {
                                    // Course (only relevant for school work)
                                    if !isEvent {
                                        HStack {
                                            Image(systemName: "book.closed")
                                                .foregroundColor(.gray)
                                            Text("Course")
                                            Spacer()
                                            Picker("Course", selection: $selectedCourseId) {
                                                Text("None").tag("")
                                                ForEach(courses) { course in
                                                    Text(course.name).tag(course.id ?? "")
                                                }
                                            }
                                            .pickerStyle(MenuPickerStyle())
                                            .accentColor(.blue)
                                        }
                                        .padding()
                                        .background(Color(.secondarySystemGroupedBackground))
                                        
                                        Divider().padding(.leading)
                                    }
                                    
                                    // Priority
                                    HStack {
                                        Image(systemName: "flag")
                                            .foregroundColor(.gray)
                                            .padding(.trailing, 2)
                                        Text("Priority")
                                        Spacer()
                                        Picker("Priority", selection: $priority) {
                                            ForEach(priorities, id: \.self) { Text($0).tag($0) }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .accentColor(.blue)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                    
                                    Divider().padding(.leading)
                                    
                                    // Details
                                    HStack {
                                        Image(systemName: "text.alignleft")
                                            .foregroundColor(.gray)
                                        TextField("Details", text: $details)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                }
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                .padding(.horizontal)
                            }
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.vertical)
                    }
                    
                    // --- Bottom Action Button ---
                    VStack {
                        Button(action: addDeadline) {
                            Text("Add Task")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    (title.isEmpty || isSaving) ? Color.gray : Color.blue
                                )
                                .cornerRadius(15)
                                .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(title.isEmpty || isSaving)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .background(
                        LinearGradient(colors: [Color(.systemGroupedBackground).opacity(0), Color(.systemGroupedBackground)], startPoint: .top, endPoint: .bottom)
                    )
                }
                
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView().padding().background(Material.regular).cornerRadius(10)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }.disabled(isSaving)
                }
                // Removed Add from toolbar
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: { Text(alertMessage) }
        }
        .navigationViewStyle(.stack)
    }
    
    private func addDeadline() {
        guard let userId = Auth.auth().currentUser?.uid else {
            alertMessage = "Not logged in"
            showingErrorAlert = true
            return
        }
        
        // Validate Time (only for Events)
        if isEvent && !isAllDay && endDate < dueDate {
            alertMessage = "End time cannot be before start time."
            showingErrorAlert = true
            let errorGen = UINotificationFeedbackGenerator()
            errorGen.notificationOccurred(.error)
            return
        }
        
        isSaving = true
        let finalEndDate = (isEvent && !isAllDay) ? endDate : nil
        
        let newDeadline = Deadline(
            id: nil, title: title, type: type, dueDate: dueDate, endDate: finalEndDate,
            isAllDay: isEvent ? isAllDay : false, isCompleted: false, details: details.isEmpty ? nil : details,
            courseId: selectedCourseId.isEmpty ? nil : selectedCourseId, priority: priority
        )
        
        let db = Firestore.firestore()
        let docRef = db.collection(Constants.Firestore.root).document(Constants.appId)
            .collection(Constants.Firestore.users).document(userId)
            .collection(Constants.Firestore.deadlines).document()
            
        try? docRef.setData(from: newDeadline) { error in
            DispatchQueue.main.async {
                isSaving = false
                if let error = error {
                    alertMessage = error.localizedDescription
                    showingErrorAlert = true
                    let errorGen = UINotificationFeedbackGenerator()
                    errorGen.notificationOccurred(.error)
                } else {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    isPresented = false
                }
            }
        }
    }
}
