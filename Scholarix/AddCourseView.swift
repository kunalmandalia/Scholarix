import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddCourseView: View {
    @Binding var isPresented: Bool
    
    // --- Data Storage ---
    @State private var courseName = ""
    @State private var gradePercentString = ""
    @State private var gradeLevel = 9
    @State private var courseLevel = "Regular"
    @State private var credits = 3.0
    
    // --- State for UX ---
    @State private var isSaving = false
    @State private var showingErrorAlert = false
    @State private var alertMessage = ""
    @State private var gradeError: String? = nil
    
    let gradeLevels = [9, 10, 11, 12]
    let courseLevels = ["Regular", "Honors", "AP", "IB"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) { // Main Container
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // Header Illustration
                            HStack {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading) {
                                    Text("New Course")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("Add details to track your progress")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top)
                            
                            // Section 1: Course Info Card
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
                                        TextField("Course Name (e.g. Algebra II)", text: $courseName)
                                            .autocapitalization(.words)
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
                            
                            // Section 2: Performance Card
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
                                            TextField("95.0", text: $gradePercentString)
                                                .keyboardType(.decimalPad)
                                                .multilineTextAlignment(.trailing)
                                                .frame(width: 80)
                                                .padding(8)
                                                .background(Color(.systemGray6))
                                                .cornerRadius(8)
                                                .onChange(of: gradePercentString) { _, newValue in
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
                            
                            Spacer(minLength: 100) // Space for bottom button
                        }
                        .padding(.vertical)
                    }
                    
                    // --- Bottom Action Button ---
                    VStack {
                        Button(action: saveCourse) {
                            Text("Save Course")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    (isSaving || courseName.isEmpty || gradePercentString.isEmpty || gradeError != nil)
                                    ? Color.gray
                                    : Color.blue
                                )
                                .cornerRadius(15)
                                .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isSaving || courseName.isEmpty || gradePercentString.isEmpty || gradeError != nil)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .background(
                        LinearGradient(colors: [Color(.systemGroupedBackground).opacity(0), Color(.systemGroupedBackground)], startPoint: .top, endPoint: .bottom)
                    )
                }
                
                // Moved Overlay INSIDE ZStack
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .disabled(isSaving)
                }
                // Removed Save button from here
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .disabled(isSaving) // Disable interaction while saving
        }
        .navigationViewStyle(.stack)
    }
    
    // --- Helper Functions ---
    
    private func validateGrade(_ value: String) {
        if value.isEmpty {
            gradeError = nil // Allow empty while typing, but Save button will be disabled
        } else if Double(value) == nil {
            gradeError = "Invalid number"
        } else if let num = Double(value), (num < 0 || num > 110) { // Basic range check
            gradeError = "Grade must be between 0 and 110"
        } else {
            gradeError = nil
        }
    }
    
    private func saveCourse() {
        // Final Validation
        guard !courseName.isEmpty else { return }
        guard let gradeValue = Double(gradePercentString) else {
            gradeError = "Invalid number"
            return
        }
        
        isSaving = true
        
        // Haptic Feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        
        // Auth Check
        guard let userId = Auth.auth().currentUser?.uid else {
            alertMessage = "You must be logged in to save."
            showingErrorAlert = true
            isSaving = false
            return
        }
        
        // Data Preparation
        let newCourse = Course(
            id: nil, // Firestore will generate this
            name: courseName.trimmingCharacters(in: .whitespacesAndNewlines),
            gradeLevel: gradeLevel,
            courseLevel: courseLevel,
            credits: credits,
            gradePercent: gradeValue,
            createdAt: Timestamp(date: Date())
        )
        
        // Firestore Save
        let db = Firestore.firestore()
        let docRef = db.collection(Constants.Firestore.root).document(Constants.appId)
            .collection(Constants.Firestore.users).document(userId)
            .collection(Constants.Firestore.courses).document()
            
        do {
            try docRef.setData(from: newCourse) { error in
                DispatchQueue.main.async {
                    isSaving = false
                    
                    if let error = error {
                        alertMessage = "Failed to save: \(error.localizedDescription)"
                        showingErrorAlert = true
                        
                        // Error Haptic
                        let errorGen = UINotificationFeedbackGenerator()
                        errorGen.notificationOccurred(.error)
                    } else {
                        // Success!
                        generator.impactOccurred()
                        isPresented = false
                    }
                }
            }
        } catch {
            isSaving = false
            alertMessage = "Encoding error: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
}
