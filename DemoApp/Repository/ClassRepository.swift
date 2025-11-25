//
//  ClassRepository.swift
//  KanjiDemo - Class Repository
//

import Foundation
import SwiftData

public class ClassRepository: BaseRepository<Class>, ClassRepositoryProtocol {
    
    public func fetchBySubject(_ subject: String) throws -> [Class] {
        let predicate = #Predicate<Class> { $0.subject == subject }
        let sortBy = [SortDescriptor(\Class.title, order: .forward)]
        return try fetch(predicate: predicate, sortBy: sortBy)
    }
    
    public func fetchByTitle(_ title: String) throws -> Class? {
        let predicate = #Predicate<Class> { $0.title == title }
        return try fetch(predicate: predicate).first
    }
    
    // Fetch classes that a specific student is enrolled in
    public func fetchClassesForStudent(_ student: Student) throws -> [Class] {
        let allClasses = try fetchAll()
        return allClasses.filter { classItem in
            classItem.students.contains(where: { $0.persistentModelID == student.persistentModelID })
        }
    }
}
