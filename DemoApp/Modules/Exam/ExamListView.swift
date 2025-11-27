//
//  ExamListView.swift
//  DemoApp - Exam List View
//
//  Purpose: Displays list of exams with search and filter capabilities
//

import SwiftUI

struct ExamListView: View {
    let viewModel: ExamViewModel
    let navigation: NavigationBuilder<ExamNavigationDestination>

    var body: some View {
        VStack(spacing: 0) {
            searchBar.padding()
            filterBar.padding(.horizontal)
            Divider()

            if viewModel.isLoadingData {
                ProgressView("Loading exams...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredExams.isEmpty {
                ContentUnavailableView(
                    "No Exams",
                    systemImage: "doc.text",
                    description: Text("No exams found")
                )
            } else {
                List {
                    ForEach(viewModel.filteredExams, id: \.persistentModelID) { exam in
                        ExamRow(exam: exam) {
                            navigation.push(.examDetail(exam))
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Exams")
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
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

            TextField("Search exams", text: $vm.searchText)
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

    private var filterBar: some View {
        @Bindable var vm = viewModel
        return HStack(spacing: 12) {
            Button {
                vm.showUpcomingOnly.toggle()
                if vm.showUpcomingOnly {
                    vm.showPastOnly = false
                }
            } label: {
                Label("Upcoming", systemImage: "calendar.badge.clock")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(vm.showUpcomingOnly ? Color.blue : Color(.systemGray5))
                    .foregroundColor(vm.showUpcomingOnly ? .white : .primary)
                    .cornerRadius(8)
            }

            Button {
                vm.showPastOnly.toggle()
                if vm.showPastOnly {
                    vm.showUpcomingOnly = false
                }
            } label: {
                Label("Past", systemImage: "calendar.badge.checkmark")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(vm.showPastOnly ? Color.blue : Color(.systemGray5))
                    .foregroundColor(vm.showPastOnly ? .white : .primary)
                    .cornerRadius(8)
            }

            Spacer()
        }
    }
}

struct ExamRow: View {
    let exam: Exam
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exam.title)
                        .font(.headline)

                    HStack(spacing: 8) {
                        Text(exam.subject)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text(exam.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if exam.isUpcoming {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text("Upcoming")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }

                    Text("\(exam.students.count) students • Max score: \(exam.maxScore)")
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
