//
//  ExamDetailView.swift
//  DemoApp - Exam Detail View
//
//  Purpose: Displays exam details with cross-module navigation to students and class
//

import SwiftUI

struct ExamDetailView: View {
    let exam: Exam
    let onStudentTap: (Student) -> Void
    let onClassTap: (Class) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Exam Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(exam.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Label(exam.subject, systemImage: "book")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Label(exam.formattedDate, systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Label("Max Score: \(exam.maxScore)", systemImage: "star")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Status badge
                    if exam.isUpcoming {
                        Label("Upcoming", systemImage: "clock.badge.exclamationmark")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .cornerRadius(6)
                    } else if exam.isPast {
                        Label("Past", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray)
                            .cornerRadius(6)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Associated Class
                if let classItem = exam.classItem {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Class")
                            .font(.headline)

                        Button(action: { onClassTap(classItem) }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(classItem.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("\(classItem.subject) • Room \(classItem.room)")
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

                // Registered Students
                VStack(alignment: .leading, spacing: 12) {
                    Text("Registered Students (\(exam.students.count))")
                        .font(.headline)

                    if exam.students.isEmpty {
                        Text("No students registered")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(exam.students.sorted { $0.name < $1.name }, id: \.persistentModelID) { student in
                            Button(action: { onStudentTap(student) }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(student.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("Grade \(student.grade) • \(student.email)")
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
        .navigationTitle("Exam Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
