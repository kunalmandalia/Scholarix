import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct AddCourseView: View {
    // --- Configuration ---
    // This ID *must* match the one in your Firestore Rules exactly.
    private let appId = "scholarix-app"
    
    // --- 1. Data Storage ---
    @State private var courseName = ""
    @State private var gradePercentString = ""
    @State private var gradeLevel = 9
    @State private var courseLevel = "Regular"
    @State private var credits = 3.0
    
    // --- Arrays for our Pickers ---
    let gradeLevels = [9, 10, 11, 12]
    let courseLevels = ["Regular", "Honors", "AP", "IB"]
    
    // --- Use a Binding to control presentation ---
    @Binding var isPresented: Bool
    
    // --- State to prevent double-saving ---
    @State private var isSaving = false
    
    // --- State for error alerts ---
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingErrorAlert = false
    
    // --- State for inline grade validation ---
    @State private var gradeError: String? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Course Details")) {
                    TextField("Course Name (e.g., Algebra II)", text: $courseName)
                    
                    Picker("Grade Taken", selection: $gradeLevel) {
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
                
                Section(header: Text("Grade & Credits")) {
                    VStack(alignment: .leading) {
                        TextField("Grade (%)", text: $gradePercentString)
                            .keyboardType(.decimalPad)
                            .onChange(of: gradePercentString) { _, newValue in
                                // Validate as the user types
                                if !newValue.isEmpty && Double(newValue) == nil {
                                    gradeError = "Must be a valid number (e.g., 95.5)"
                                } else {
                                    gradeError = nil // Clear the error
                                }
                            }
                        
                        // Show the error message if it exists
                        if let gradeError = gradeError {
                            Text(gradeError)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, 2)
                        }
                    }
                    
                    Stepper("Amount of Credits: \(credits, specifier: "%.1f")", value: $credits, in: 0.0...5.0, step: 0.5)
                }
            }
            .navigationTitle("Add New Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCourse()
                    }
                    // Disable if name OR grade is empty, grade is invalid, or already saving
                    .disabled(courseName.isEmpty || gradePercentString.isEmpty || gradeError != nil || isSaving)
                }
            }
            .alert(isPresented: $showingErrorAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func saveCourse() {
        // Double-check validation
        if gradePercentString.isEmpty {
            showError(title: "Missing Grade", message: "Please enter a grade.")
            return
        }
        if !gradePercentString.isEmpty && Double(gradePercentString) == nil {
            showError(title: "Invalid Grade", message: "Please enter a valid number for the grade.")
            return
        }
        
        isSaving = true
        
        let db = Firestore.firestore()
        
        // Check Authentication
        guard let userId = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                showError(title: "Authentication Error", message: "You must be logged in to save a course.")
                isSaving = false
            }
            return
        }
        
        let gradeValue: Double? = Double(gradePercentString)
        
        // --- SECURE PATH CONSTRUCTION ---
        // Path: artifacts/{appId}/users/{userId}/courses/{courseId}
        let coursesCollection = db.collection("artifacts").document(appId)
            .collection("users").document(userId)
            .collection("courses")
        
        let newDocRef = coursesCollection.document()
        
        let data: [String: Any] = [
            "id": newDocRef.documentID,
            "name": self.courseName,
            "gradeLevel": self.gradeLevel,
            "courseLevel": self.courseLevel,
            "credits": self.credits,
            "gradePercent": gradeValue as Any,
            "createdAt": Timestamp(date: Date())
        ]
        
        print("Attempting to save to: \(newDocRef.path)")
        
        newDocRef.setData(data) { error in
            DispatchQueue.main.async {
                isSaving = false
                
                if let error = error {
                    print("Error saving course: \(error.localizedDescription)")
                    // Friendly error message for permissions
                    if error.localizedDescription.contains("permission") {
                        showError(title: "Permission Denied", message: "Database rules rejected the save. Check that your Firestore Rules include the path: artifacts/\(appId)/users/...")
                    } else {
                        showError(title: "Save Failed", message: error.localizedDescription)
                    }
                } else {
                    print("Successfully saved course!")
                    isPresented = false
                }
            }
        }
    }
    
    private func showError(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingErrorAlert = true
    }
}

