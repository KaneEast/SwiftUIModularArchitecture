//
//  StudentDetailView.swift
//  KanjiDemo - Student Detail View
//

import SwiftUI

struct StudentDetailView: View {
    let student: Student
    let router: ModuleRouter<StudentNavigationDestination>
    let onNavigateToClass: ((Class) -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Student Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(student.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Label(student.email, systemImage: "envelope")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Label("Grade \(student.grade)", systemImage: "graduationcap")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Enrolled Classes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Enrolled Classes (\(student.classes.count))")
                        .font(.headline)

                    if student.classes.isEmpty {
                        Text("No classes enrolled")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(student.classes, id: \.persistentModelID) { classItem in
                            Button(action: {
                                // Cross-module navigation - View directly calls the closure
                                onNavigateToClass?(classItem)
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(classItem.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(classItem.subject)
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

                // Exams Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exams (\(student.exams.count))")
                        .font(.headline)

                    Button(action: {
                        // View directly calls router - more direct!
                        router.presentSheet(.examList)
                    }) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.title3)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("View All Exams")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("See all exams for this student")
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
            .padding()
        }
        .navigationTitle("Student Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
