import Foundation
import FirebaseFirestore

// --- We must add Hashable for the new navigation to work ---
struct Course: Codable, Identifiable, Hashable {
    
    @DocumentID var id: String?
    
    var name: String
    var gradeLevel: Int
    var courseLevel: String
    var credits: Double
    var gradePercent: Double?
    var createdAt: Timestamp?
    
    // --- THIS IS THE FIX ---
    // We must compare all fields, not just the ID.
    // This tells SwiftUI that the old and new courses are *not* equal,
    // which forces it to redraw the row.
    static func == (lhs: Course, rhs: Course) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.gradeLevel == rhs.gradeLevel &&
        lhs.courseLevel == rhs.courseLevel &&
        lhs.credits == rhs.credits &&
        lhs.gradePercent == rhs.gradePercent
    }
    
    // --- We must also update the hash function to match ---
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(gradeLevel)
        hasher.combine(courseLevel)
        hasher.combine(credits)
        hasher.combine(gradePercent)
    }
    
    // This gives the NavigationLink a non-optional value to work with.
    static func placeholder() -> Course {
        return Course(id: "placeholder", name: "", gradeLevel: 9, courseLevel: "Regular", credits: 0, gradePercent: nil, createdAt: nil)
    }
}

