import Foundation
import FirebaseFirestore

struct GPAService {
    
    static func calculate(courses: [Course]) -> (unweighted: String, weighted: String) {
        let gradedCourses = courses.filter { $0.gradePercent != nil }
        
        var totalUnweightedPoints: Double = 0
        var totalWeightedPoints: Double = 0
        var totalCredits: Double = 0
        
        guard !gradedCourses.isEmpty else {
            return ("0.00", "0.00")
        }
        
        for course in gradedCourses {
            let grade = course.gradePercent!
            let credits = course.credits
            
            let (u, w) = gradePoints(grade: grade, level: course.courseLevel)
            
            totalUnweightedPoints += (u * credits)
            totalWeightedPoints += (w * credits)
            totalCredits += credits
        }
        
        if totalCredits > 0 {
            let uwGPA = String(format: "%.2f", totalUnweightedPoints / totalCredits)
            let wGPA = String(format: "%.2f", totalWeightedPoints / totalCredits)
            return (uwGPA, wGPA)
        } else {
            return ("0.00", "0.00")
        }
    }
    
    private static func gradePoints(grade: Double, level: String) -> (unweighted: Double, weighted: Double) {
        var unweightedPoint: Double = 0.0
        
        // FIX: Check if the grade is on a 4.0 scale (e.g., user entered "3.8" or "4.0")
        if grade <= 5.0 && grade >= 0.0 {
            // Assume the user entered the points directly
            unweightedPoint = grade
        } else {
            // Assume 100-point scale
            if grade >= 93.0 { unweightedPoint = 4.0 }
            else if grade >= 90.0 { unweightedPoint = 3.7 }
            else if grade >= 87.0 { unweightedPoint = 3.3 }
            else if grade >= 83.0 { unweightedPoint = 3.0 }
            else if grade >= 80.0 { unweightedPoint = 2.7 }
            else if grade >= 77.0 { unweightedPoint = 2.3 }
            else if grade >= 73.0 { unweightedPoint = 2.0 }
            else if grade >= 70.0 { unweightedPoint = 1.7 }
            else if grade >= 67.0 { unweightedPoint = 1.3 }
            else if grade >= 65.0 { unweightedPoint = 1.0 }
            else { unweightedPoint = 0.0 }
        }
        
        let weightedPoint: Double
        switch level {
        case "Honors":
            weightedPoint = unweightedPoint + 0.5
        case "AP", "IB":
            weightedPoint = unweightedPoint + 1.0
        default:
            weightedPoint = unweightedPoint
        }
        
        return (unweightedPoint, weightedPoint)
    }
}
