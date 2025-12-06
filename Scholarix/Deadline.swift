import Foundation
import FirebaseFirestore

struct Deadline: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    
    var title: String
    var type: String
    var dueDate: Date        // Serves as Start Date
    var endDate: Date?       // New: End Date
    var isAllDay: Bool = false // New: All Day Flag
    var isCompleted: Bool
    var details: String?
    
    var courseId: String?
    var priority: String?
    
    // Hashable conformance
    static func == (lhs: Deadline, rhs: Deadline) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Duration helper
    var duration: TimeInterval {
        guard let end = endDate else { return 3600 } // Default 1 hour
        return end.timeIntervalSince(dueDate)
    }
}
