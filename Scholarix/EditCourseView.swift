import SwiftUI
import FirebaseFirestore
import Combine

struct EditCourseView: View {
    // This connects to the "brain" on the Academic Hub
    // Updated to use AcademicViewModel
    @ObservedObject var viewModel: AcademicViewModel
    
    // This is the original, unchanged course
    private var originalCourse: Course
    
    // --- Editable Fields ---
    @State private var courseName: String
    @State private var gradeString: String
    @State private var gradeLevel: Int
    @State private var courseLevel: String
    @State private var credits: Double
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isSaving = false
    @State private var errorMessage = ""
    @State private var showingErrorAlert = false
    
    let gradeLevels = [9, 10, 11, 12]
    let courseLevels = ["Regular", "Honors", "AP", "IB"]
    
    // The initializer populates our @State variables
    init(viewModel: AcademicViewModel, courseToEdit: Course) {
        self.viewModel = viewModel
        self.originalCourse = courseToEdit
        
        // Initialize all @State variables from the course
        _courseName = State(initialValue: courseToEdit.name)
        _gradeLevel = State(initialValue: courseToEdit.gradeLevel)
        _courseLevel = State(initialValue: courseToEdit.courseLevel)
        _credits = State(initialValue: courseToEdit.credits)
        
        if let grade = courseToEdit.gradePercent {
            _gradeString = State(initialValue: String(format: "%.1f", grade))
        } else {
            _gradeString = State(initialValue: "")
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Course Details")) {
                // The UI fields now bind to our new @State variables
                TextField("Course Name", text: $courseName)
                
                TextField("Grade (%)", text: $gradeString)
                    .keyboardType(.decimalPad)
                    .onChange(of: gradeString) { _, newValue in
                        // Filter input to allow only numbers and one decimal
                        let filtered = newValue.filter { "0123456789.".contains($0) }
                        if filtered.components(separatedBy: ".").count - 1 > 1 {
                            self.gradeString = String(filtered.dropLast())
                        } else {
                            self.gradeString = filtered
                        }
                    }
                
                Picker("Grade Level", selection: $gradeLevel) {
                    ForEach(gradeLevels, id: \.self) { level in
                        Text("\(level)th Grade").tag(level)
                    }
                }
                
                Picker("Course Level", selection: $courseLevel) {
                    ForEach(courseLevels, id: \.self) { level in
                        Text(level).tag(level)
                    }
                }
            }
            
            Section(header: Text("Credits")) {
                Stepper(value: $credits, in: 0...5, step: 0.5) {
                    Text("\(credits, specifier: "%.1f") credits")
                }
            }
        }
        .navigationTitle("Edit Course")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    updateCourse()
                }
                .disabled(isSaving || courseName.isEmpty || gradeString.isEmpty)
            }
        }
        .alert(isPresented: $showingErrorAlert) {
            Alert(title: Text("Error Updating Course"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func updateCourse() {
        Task {
            await MainActor.run { self.isSaving = true }
            
            // 1. Create an updated 'Course' object from our @State variables
            // We use the original 'id' and 'createdAt'
            var updatedCourse = originalCourse
            updatedCourse.name = courseName
            updatedCourse.gradeLevel = gradeLevel
            updatedCourse.courseLevel = courseLevel
            updatedCourse.credits = credits
            
            if let gradeValue = Double(gradeString) {
                updatedCourse.gradePercent = gradeValue
            } else {
                updatedCourse.gradePercent = nil
            }
            
            do {
                // 2. Call the update function in our view model
                try await viewModel.updateCourse(course: updatedCourse)
                
                // 3. If successful, dismiss the view
                self.isSaving = false
                await MainActor.run { presentationMode.wrappedValue.dismiss() }
            } catch {
                // 4. If it fails, show an error
                self.isSaving = false
                self.errorMessage = error.localizedDescription
                self.showingErrorAlert = true
            }
        }
    }
}

