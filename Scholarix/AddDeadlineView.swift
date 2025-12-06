import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddDeadlineView: View {
    // MATCHES FIRESTORE RULES EXACTLY
    private let appId = "scholarix-app"
    
    @Binding var isPresented: Bool
    let courses: [Course]
    
    @State private var title = ""
    @State private var type = "Homework"
    @State private var dueDate = Date() // Serves as Start Date or Due Date
    @State private var endDate = Date().addingTimeInterval(3600) // End Date (+1hr default)
    @State private var isAllDay = false
    @State private var selectedCourseId: String = ""
    @State private var priority = "Medium"
    @State private var details = ""
    
    // State for error handling
    @State private var isSaving = false
    @State private var showingErrorAlert = false
    @State private var alertMessage = ""
    
    let types = ["Homework", "Test", "Project", "Essay", "Application", "Event", "Club", "Sport"]
    let priorities = ["Low", "Medium", "High"]
    
    // Helper: Determine if the selected type implies a duration (Event) or a specific time (Deadline)
    private var isEvent: Bool {
        return ["Event", "Club", "Sport"].contains(type)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    Picker("Type", selection: $type) {
                        ForEach(types, id: \.self) { Text($0) }
                    }
                    
                    // Conditional UI based on Type
                    if isEvent {
                        // Event Mode: Range or All-Day
                        Toggle("All-day", isOn: $isAllDay)
                        
                        if isAllDay {
                            DatePicker("Date", selection: $dueDate, displayedComponents: [.date])
                        } else {
                            DatePicker("Starts", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                .onChange(of: dueDate) { oldDate, newDate in
                                    // Automatically push end date if start date moves past it
                                    if newDate > endDate {
                                        endDate = newDate.addingTimeInterval(3600)
                                    }
                                }
                            DatePicker("Ends", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                        }
                    } else {
                        // Deadline Mode: Single point in time
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section(header: Text("Course (Optional)")) {
                    Picker("Course", selection: $selectedCourseId) {
                        Text("None").tag("")
                        ForEach(courses) { course in
                            Text(course.name).tag(course.id ?? "")
                        }
                    }
                }
                
                Section(header: Text("Additional Info")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(priorities, id: \.self) { Text($0) }
                    }
                    TextField("Details", text: $details)
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addDeadline()
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func addDeadline() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Validation: Only enforce end time check for non-all-day events
        if isEvent && !isAllDay && endDate < dueDate {
            alertMessage = "End time cannot be before start time."
            showingErrorAlert = true
            return
        }
        
        isSaving = true
        
        // Logic: If it's a deadline (not an event), treat it as having no end date (default duration logic will apply in view)
        let finalEndDate = (isEvent && !isAllDay) ? endDate : nil
        let finalIsAllDay = isEvent ? isAllDay : false
        
        let newDeadline = Deadline(
            id: nil,
            title: title,
            type: type,
            dueDate: dueDate,
            endDate: finalEndDate,
            isAllDay: finalIsAllDay,
            isCompleted: false,
            details: details.isEmpty ? nil : details,
            courseId: selectedCourseId.isEmpty ? nil : selectedCourseId,
            priority: priority
        )
        
        let db = Firestore.firestore()
        
        let docRef = db.collection("artifacts").document(appId)
            .collection("users").document(userId)
            .collection("deadlines").document()
            
        try? docRef.setData(from: newDeadline) { error in
            DispatchQueue.main.async {
                isSaving = false
                if let error = error {
                    alertMessage = "Failed to save: \(error.localizedDescription)"
                    showingErrorAlert = true
                } else {
                    isPresented = false
                }
            }
        }
    }
}
