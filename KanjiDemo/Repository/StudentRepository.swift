//
//  StudentRepository.swift
//  KanjiDemo - Student Repository
//

import Foundation
import SwiftData

public class StudentRepository: BaseRepository<Student> {
    
    public func fetchByGrade(_ grade: Int) throws -> [Student] {
        let predicate = #Predicate<Student> { $0.grade == grade }
        let sortBy = [SortDescriptor(\Student.name, order: .forward)]
        return try fetch(predicate: predicate, sortBy: sortBy)
    }
    
    public func fetchByName(_ name: String) throws -> Student? {
        let predicate = #Predicate<Student> { $0.name == name }
        return try fetch(predicate: predicate).first
    }
    
    // Fetch students enrolled in a specific class
    // Note: SwiftData doesn't support direct relationship predicates yet,
    // so we use the relationship property on Class instead
    public func fetchStudentsInClass(_ classItem: Class) -> [Student] {
        // More efficient: use the bidirectional relationship
        // Class already has .students populated by SwiftData
        return classItem.students.sorted { $0.name < $1.name }
    }
}
