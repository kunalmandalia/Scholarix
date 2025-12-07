import SwiftUI
import FirebaseAuth
import Firebase
import FirebaseFirestore
import Combine

@MainActor
class AcademicViewModel: ObservableObject {
    
    @Published var courses = [Course]()
    @Published var unweightedGPA: String = "0.00"
    @Published var weightedGPA: String = "0.00"
    @Published var deadlines = [Deadline]()
    @Published var searchText = ""
    @Published var errorMessage: String? // Added for error alerts
    
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
    
    // Helper for safe path construction: artifacts/{appId}/users/{userId}/...
    private func userDoc(_ userId: String) -> DocumentReference {
        return Firestore.firestore()
            .collection(Constants.Firestore.root).document(Constants.appId)
            .collection(Constants.Firestore.users).document(userId)
    }
    
    func fetchCourses() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        self.coursesListener = userDoc(userId).collection(Constants.Firestore.courses).addSnapshotListener { [weak self] qs, error in
            guard let self = self else { return }
            if let error = error {
                self.errorMessage = "Error fetching courses: \(error.localizedDescription)"
                return
            }
            guard let docs = qs?.documents else { return }
            self.courses = docs.compactMap { try? $0.data(as: Course.self) }
            self.calculateGPA() // Re-calculate whenever courses change
        }
    }
    
    func fetchDeadlines() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        self.deadlinesListener = userDoc(userId).collection(Constants.Firestore.deadlines).order(by: "dueDate").addSnapshotListener { [weak self] qs, error in
            guard let self = self else { return }
            if let error = error {
                self.errorMessage = "Error fetching deadlines: \(error.localizedDescription)"
                return
            }
            guard let docs = qs?.documents else { return }
            self.deadlines = docs.compactMap { try? $0.data(as: Deadline.self) }
        }
    }
    
    // Uses GPAService to perform calculation logic
    private func calculateGPA() {
        let (u, w) = GPAService.calculate(courses: courses)
        unweightedGPA = u
        weightedGPA = w
    }
    
    func detachListeners() {
        coursesListener?.remove()
        deadlinesListener?.remove()
    }
    
    // CRUD Operations
    func deleteCourse(course: Course) {
        guard let uid = Auth.auth().currentUser?.uid, let id = course.id else { return }
        userDoc(uid).collection(Constants.Firestore.courses).document(id).delete()
    }
    
    func deleteDeadline(deadline: Deadline) {
        guard let uid = Auth.auth().currentUser?.uid, let id = deadline.id else { return }
        userDoc(uid).collection(Constants.Firestore.deadlines).document(id).delete()
    }
    
    func updateCourse(course: Course) async throws {
        guard let uid = Auth.auth().currentUser?.uid, let id = course.id else { throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]) }
        try await userDoc(uid).collection(Constants.Firestore.courses).document(id).setData(from: course)
    }
    
    func updateDeadline(deadline: Deadline) async throws {
        guard let uid = Auth.auth().currentUser?.uid, let id = deadline.id else { throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]) }
        try await userDoc(uid).collection(Constants.Firestore.deadlines).document(id).setData(from: deadline)
    }
    
    func toggleCompletion(deadline: Deadline) {
        guard let uid = Auth.auth().currentUser?.uid, let id = deadline.id else { return }
        
        var updated = deadline
        updated.isCompleted.toggle()
        
        // Optimistic UI update
        if let index = deadlines.firstIndex(where: { $0.id == id }) {
            deadlines[index] = updated
        }
        
        Task {
            try? await userDoc(uid).collection(Constants.Firestore.deadlines).document(id).setData(from: updated)
        }
    }
}
