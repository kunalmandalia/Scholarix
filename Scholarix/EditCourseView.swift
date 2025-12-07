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
    @State private var gradeError: String? = nil
    
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
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // Header
                            HStack {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)
                                    .padding()
                                    .background(Color.orange.opacity(0.1))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading) {
                                    Text("Edit Course")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("Update course details")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top)
                            
                            // Section 1: Course Info
                            VStack(alignment: .leading, spacing: 16) {
                                Text("COURSE DETAILS")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 0) {
                                    // Name Input
                                    HStack {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.gray)
                                        TextField("Course Name", text: $courseName)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                    
                                    Divider().padding(.leading)
                                    
                                    // Grade Level Picker
                                    HStack {
                                        Image(systemName: "graduationcap")
                                            .foregroundColor(.gray)
                                        Text("Grade Taken")
                                        Spacer()
                                        Picker("Grade Taken", selection: $gradeLevel) {
                                            ForEach(gradeLevels, id: \.self) { level in
                                                Text("\(level)th").tag(level)
                                            }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .accentColor(.blue)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                    
                                    Divider().padding(.leading)
                                    
                                    // Course Level Picker
                                    HStack {
                                        Image(systemName: "chart.bar")
                                            .foregroundColor(.gray)
                                        Text("Level")
                                        Spacer()
                                        Picker("Level", selection: $courseLevel) {
                                            ForEach(courseLevels, id: \.self) { level in
                                                Text(level).tag(level)
                                            }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .accentColor(.blue)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                }
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                .padding(.horizontal)
                            }
                            
                            // Section 2: Performance
                            VStack(alignment: .leading, spacing: 16) {
                                Text("PERFORMANCE")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 0) {
                                    // Grade Input
                                    VStack(alignment: .leading, spacing: 0) {
                                        HStack {
                                            Image(systemName: "percent")
                                                .foregroundColor(.gray)
                                            Text("Current Grade")
                                            Spacer()
                                            TextField("95.0", text: $gradeString)
                                                .keyboardType(.decimalPad)
                                                .multilineTextAlignment(.trailing)
                                                .frame(width: 80)
                                                .padding(8)
                                                .background(Color(.systemGray6))
                                                .cornerRadius(8)
                                                .onChange(of: gradeString) { _, newValue in
                                                    validateGrade(newValue)
                                                }
                                        }
                                        .padding()
                                        
                                        if let error = gradeError {
                                            Text(error)
                                                .font(.caption)
                                                .foregroundColor(.red)
                                                .padding(.leading)
                                                .padding(.bottom, 8)
                                        }
                                    }
                                    .background(Color(.secondarySystemGroupedBackground))
                                    
                                    Divider().padding(.leading)
                                    
                                    // Credits Stepper
                                    HStack {
                                        Image(systemName: "star.circle")
                                            .foregroundColor(.gray)
                                        Text("Credits")
                                        Spacer()
                                        
                                        HStack(spacing: 12) {
                                            Button(action: { if credits > 0 { credits -= 0.5 } }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.blue)
                                            }
                                            
                                            Text(String(format: "%.1f", credits))
                                                .font(.headline)
                                                .frame(width: 40)
                                                .multilineTextAlignment(.center)
                                            
                                            Button(action: { if credits < 10 { credits += 0.5 } }) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.blue)
                                            }
                                        }
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
                        Button(action: updateCourse) {
                            Text("Save Changes")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    (isSaving || courseName.isEmpty || gradeString.isEmpty || gradeError != nil)
                                    ? Color.gray
                                    : Color.blue
                                )
                                .cornerRadius(15)
                                .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isSaving || courseName.isEmpty || gradeString.isEmpty || gradeError != nil)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .background(
                        LinearGradient(colors: [Color(.systemGroupedBackground).opacity(0), Color(.systemGroupedBackground)], startPoint: .top, endPoint: .bottom)
                    )
                }
                
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                        ProgressView()
                            .padding()
                            .background(Material.regular)
                            .cornerRadius(10)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            // Removed Save from Toolbar
            .alert(isPresented: $showingErrorAlert) {
                Alert(title: Text("Error Updating Course"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func validateGrade(_ value: String) {
        if value.isEmpty {
            gradeError = nil
        } else if Double(value) == nil {
            gradeError = "Invalid number"
        } else if let num = Double(value), (num < 0 || num > 110) {
            gradeError = "Grade must be between 0 and 110"
        } else {
            gradeError = nil
        }
    }
    
    private func updateCourse() {
        Task {
            await MainActor.run { self.isSaving = true }
            
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
                try await viewModel.updateCourse(course: updatedCourse)
                
                // Haptic Feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                self.isSaving = false
                await MainActor.run { presentationMode.wrappedValue.dismiss() }
            } catch {
                self.isSaving = false
                self.errorMessage = error.localizedDescription
                self.showingErrorAlert = true
                
                let errorGen = UINotificationFeedbackGenerator()
                errorGen.notificationOccurred(.error)
            }
        }
    }
}
