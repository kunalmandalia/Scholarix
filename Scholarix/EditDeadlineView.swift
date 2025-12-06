import SwiftUI
import FirebaseFirestore

struct EditDeadlineView: View {
    @ObservedObject var viewModel: AcademicViewModel
    private var originalDeadline: Deadline
    
    @State private var title: String
    @State private var type: String
    @State private var dueDate: Date
    @State private var details: String
    @State private var priority: String
    @State private var selectedCourseId: String
    
    @Environment(\.presentationMode) var presentationMode
    @State private var isSaving = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    // Options
    let types = ["Homework", "Test", "Project", "Essay", "Application", "Event", "Club", "Sport", "Other"]
    let priorities = ["Low", "Medium", "High"]
    
    var isEvent: Bool {
        return ["Event", "Club", "Sport", "Other"].contains(type)
    }
    
    init(viewModel: AcademicViewModel, deadlineToEdit: Deadline) {
        self.viewModel = viewModel
        self.originalDeadline = deadlineToEdit
        
        _title = State(initialValue: deadlineToEdit.title)
        _type = State(initialValue: deadlineToEdit.type)
        _dueDate = State(initialValue: deadlineToEdit.dueDate)
        _details = State(initialValue: deadlineToEdit.details ?? "")
        _priority = State(initialValue: deadlineToEdit.priority ?? "Medium")
        _selectedCourseId = State(initialValue: deadlineToEdit.courseId ?? "none")
    }
    
    var body: some View {
        Form {
            Section(header: Text("Details")) {
                TextField("Title", text: $title)
                
                Picker("Type", selection: $type) {
                    ForEach(types, id: \.self) { t in Text(t).tag(t) }
                }
                
                Picker("Priority", selection: $priority) {
                    ForEach(priorities, id: \.self) { p in Text(p).tag(p) }
                }
                
                // Only show Course Picker for academic tasks
                if !isEvent {
                    Picker("Assign to Course", selection: $selectedCourseId) {
                        Text("None").tag("none")
                        ForEach(viewModel.courses) { course in
                            Text(course.name).tag(course.id ?? "")
                        }
                    }
                }
                
                DatePicker(
                    isEvent ? "Date & Time" : "Due Date",
                    selection: $dueDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
            
            Section(header: Text("Notes")) {
                TextField("Additional details...", text: $details)
            }
        }
        .navigationTitle("Edit Deadline")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { updateDeadline() }
                    .disabled(isSaving || title.isEmpty)
            }
        }
        .alert(isPresented: $showingErrorAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func updateDeadline() {
        Task {
            await MainActor.run { isSaving = true }
            
            var updatedDeadline = originalDeadline
            updatedDeadline.title = title
            updatedDeadline.type = type
            updatedDeadline.dueDate = dueDate
            updatedDeadline.details = details
            updatedDeadline.priority = priority
            updatedDeadline.courseId = selectedCourseId == "none" ? nil : selectedCourseId
            
            do {
                try await viewModel.updateDeadline(deadline: updatedDeadline)
                await MainActor.run {
                    isSaving = false
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
    }
}
