//
//  ClassListView.swift
//  KanjiDemo - Class List View
//

import SwiftUI

struct ClassListView: View {
    let viewModel: ClassViewModel
    let navigation: NavigationBuilder<ClassNavigationDestination>

    var body: some View {
        VStack(spacing: 0) {
            searchBar.padding()
            Divider()

            if viewModel.isLoadingData {
                ProgressView("Loading classes...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredClasses.isEmpty {
                ContentUnavailableView(
                    "No Classes",
                    systemImage: "book.closed",
                    description: Text("No classes found")
                )
            } else {
                List {
                    ForEach(viewModel.filteredClasses, id: \.persistentModelID) { classItem in
                        ClassRow(classItem: classItem) {
                            navigation.push(.classDetail(classItem))
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Classes")
    }

    private var searchBar: some View {
        @Bindable var vm = viewModel
        return HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search classes", text: $vm.searchText)
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

struct ClassRow: View {
    let classItem: Class
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(classItem.title)
                        .font(.headline)
                    Text("\(classItem.subject) • Room \(classItem.room) • \(classItem.students.count) students")
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
