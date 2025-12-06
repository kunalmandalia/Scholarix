import SwiftUI

struct CourseRowView: View {
    let course: Course
    // These lines are what fix the "Extra Arguments" error.
    // They tell the view to expect these two functions.
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.headline)
                
                HStack {
                    Text(course.courseLevel)
                    if let grade = course.gradePercent {
                        Text("•")
                        Text("\(grade, specifier: "%.1f")%")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // The Menu Button
            Menu {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding(8)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle()) // Makes the whole row tappable for swipes
    }
}
