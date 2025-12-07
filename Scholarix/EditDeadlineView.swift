import SwiftUI
import FirebaseFirestore

struct EditDeadlineView: View {
    @ObservedObject var viewModel: AcademicViewModel
    private var originalDeadline: Deadline
    
    // Holding all the data so we can mess with it
    @State private var title: String
    @State private var type: String
    @State private var dueDate: Date
    @State private var endDate: Date
    @State private var isAllDay: Bool
    @State private var details: String
    @State private var priority: String
    @State private var selectedCourseId: String
    
    // Boring housekeeping stuff
    @Environment(\.presentationMode) var presentationMode
    @State private var isSaving = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    // The usual suspects for types and priorities
    let types = ["Homework", "Test", "Project", "Essay", "Application", "Event", "Club", "Sport", "Other"]
    let priorities = ["Low", "Medium", "High"]
    
    // Figuring out if this is a glorified party or actual work
    var isEvent: Bool {
        return ["Event", "Club", "Sport", "Other"].contains(type)
    }
    
    // Setting up the view with the old data. Don't mess this up.
    init(viewModel: AcademicViewModel, deadlineToEdit: Deadline) {
        self.viewModel = viewModel
        self.originalDeadline = deadlineToEdit
        
        _title = State(initialValue: deadlineToEdit.title)
        _type = State(initialValue: deadlineToEdit.type)
        _dueDate = State(initialValue: deadlineToEdit.dueDate)
        _endDate = State(initialValue: deadlineToEdit.endDate ?? deadlineToEdit.dueDate.addingTimeInterval(3600))
        _isAllDay = State(initialValue: deadlineToEdit.isAllDay)
        _details = State(initialValue: deadlineToEdit.details ?? "")
        _priority = State(initialValue: deadlineToEdit.priority ?? "Medium")
        _selectedCourseId = State(initialValue: deadlineToEdit.courseId ?? "none")
    }
    
    var body: some View {
        ZStack {
            // Background color. Because white is boring.
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Header. Look at that icon. Magnificent.
                        HStack {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                Text("Edit Task")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Update task details")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Section 1: The Main Stuff
                        VStack(alignment: .leading, spacing: 16) {
                            Text("TASK DETAILS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                // Title Input. Try to spell it right.
                                HStack {
                                    Image(systemName: "pencil.and.outline")
                                        .foregroundColor(.gray)
                                    TextField("Title", text: $title)
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                
                                Divider().padding(.leading)
                                
                                // Type Picker. Pick wisely.
                                HStack {
                                    Image(systemName: "tag")
                                        .foregroundColor(.gray)
                                    Text("Type")
                                    Spacer()
                                    Picker("Type", selection: $type) {
                                        ForEach(types, id: \.self) { t in Text(t).tag(t) }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .accentColor(.blue)
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                
                                // If it's an event, we show the all-day toggle. Fancy.
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
                                
                                // Date stuff. Time travel is still not supported.
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
                                    // Deadline-style due date
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
                        
                        // Section 2: Extra Details
                        VStack(alignment: .leading, spacing: 16) {
                            Text("ADDITIONAL INFO")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                // Don't need a course for a party, do we?
                                if !isEvent {
                                    HStack {
                                        Image(systemName: "book.closed")
                                            .foregroundColor(.gray)
                                        Text("Course")
                                        Spacer()
                                        Picker("Assign to Course", selection: $selectedCourseId) {
                                            Text("None").tag("none")
                                            ForEach(viewModel.courses) { course in
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
                                
                                // Is this important or are you procrastinating?
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
                                
                                // Any excuses go here.
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
                    Button(action: updateDeadline) {
                        Text("Save Changes")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                (isSaving || title.isEmpty) ? Color.gray : Color.blue
                            )
                            .cornerRadius(15)
                            .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(isSaving || title.isEmpty)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .background(
                    LinearGradient(colors: [Color(.systemGroupedBackground).opacity(0), Color(.systemGroupedBackground)], startPoint: .top, endPoint: .bottom)
                )
            }
            
            // Loading spinner. Stare at it.
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
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    // The magic button that makes it real.
    private func updateDeadline() {
        Task {
            await MainActor.run { isSaving = true }
            
            // Checking if you broke physics again.
            if isEvent && !isAllDay && endDate < dueDate {
                 errorMessage = "End time cannot be before start time."
                 showingErrorAlert = true
                 isSaving = false
                 
                 let errorGen = UINotificationFeedbackGenerator()
                 errorGen.notificationOccurred(.error)
                 return
             }
            
            var updatedDeadline = originalDeadline
            updatedDeadline.title = title
            updatedDeadline.type = type
            updatedDeadline.dueDate = dueDate
            updatedDeadline.endDate = (isEvent && !isAllDay) ? endDate : nil
            updatedDeadline.isAllDay = isEvent ? isAllDay : false
            updatedDeadline.details = details
            updatedDeadline.priority = priority
            updatedDeadline.courseId = selectedCourseId == "none" ? nil : selectedCourseId
            
            do {
                // Sending it to the cloud. Hope the internet works.
                try await viewModel.updateDeadline(deadline: updatedDeadline)
                
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                await MainActor.run {
                    isSaving = false
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                // Well, that failed.
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                    
                    let errorGen = UINotificationFeedbackGenerator()
                    errorGen.notificationOccurred(.error)
                }
            }
        }
    }
}
