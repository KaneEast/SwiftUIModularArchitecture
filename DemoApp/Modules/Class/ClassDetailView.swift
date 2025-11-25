//
//  ClassDetailView.swift
//  KanjiDemo - Class Detail View
//

import SwiftUI

struct ClassDetailView: View {
    let classItem: Class
    let onStudentTap: (Student) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Class Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(classItem.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Label(classItem.subject, systemImage: "book")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Label("Room \(classItem.room)", systemImage: "building.2")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Enrolled Students
                VStack(alignment: .leading, spacing: 12) {
                    Text("Enrolled Students (\(classItem.students.count))")
                        .font(.headline)

                    if classItem.students.isEmpty {
                        Text("No students enrolled")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(classItem.students, id: \.persistentModelID) { student in
                            Button(action: { onStudentTap(student) }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(student.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("Grade \(student.grade)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Class Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
