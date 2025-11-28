//
//  StudentListView.swift
//  KanjiDemo - Student List View
//

import SwiftUI

struct StudentListView: View {
    let viewModel: StudentViewModel
    //let navigation: NavigationBuilder<StudentNavigationDestination>
    let router: ModuleRouter<StudentNavigationDestination>
    let onLogout: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            searchBar.padding()
            Divider()

            if viewModel.isLoadingData {
                ProgressView("Loading students...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredStudents.isEmpty {
                ContentUnavailableView(
                    "No Students",
                    systemImage: "person.2",
                    description: Text("No students found")
                )
            } else {
                List {
                    ForEach(viewModel.filteredStudents, id: \.persistentModelID) { student in
                        StudentRow(student: student) {
                            router.navigate(to: .studentDetail(student))
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Students")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.fetchRandomStudents(count: 5)
                } label: {
                    if viewModel.isLoadingFromAPI {
                        ProgressView()
                    } else {
                        Label("Fetch from API", systemImage: "arrow.down.circle")
                    }
                }
                .disabled(viewModel.isLoadingFromAPI)
            }

            // Logout button (if provided)
            if let onLogout {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onLogout()
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
        }
        .alert("API Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }

    private var searchBar: some View {
        @Bindable var vm = viewModel
        return HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search students", text: $vm.searchText)
                .textFieldStyle(.plain)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct StudentRow: View {
    let student: Student
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(student.name)
                        .font(.headline)
                    Text("Grade \(student.grade) • \(student.classes.count) classes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
