//
//  ClassService.swift
//  KanjiDemo - Class Business Logic Service
//

import Foundation
import Combine

public final class ClassService {
    private let repository: any ClassRepositoryProtocol

    public init(repository: any ClassRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Core Business Logic
    public func observeClasses() -> AnyPublisher<[Class], Never> {
        return repository.observeAll()
    }

    /// 创建新班级（业务规则：检查重复、验证数据）
    public func createClass(title: String, subject: String, room: String) throws {
        // 业务规则：验证标题不为空
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ClassServiceError.emptyTitle
        }

        // 业务规则：验证房间号格式（示例）
        guard !room.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ClassServiceError.emptyRoom
        }

        let newClass = Class(title: title, subject: subject, room: room)
        try repository.create(newClass)
    }

    /// 删除班级（业务规则：同时从所有学生中移除）
    public func deleteClass(_ classItem: Class) throws {
        // 业务逻辑：删除前移除所有学生关联
        if !classItem.students.isEmpty {
            classItem.students.removeAll()
        }

        try repository.delete(classItem)
    }

    /// 获取班级的学生列表
    public func getStudentsInClass(_ classItem: Class) -> [Student] {
        return classItem.students
    }

    /// 计算班级容量使用率
    public func getCapacityUsage(for classItem: Class, maxCapacity: Int = 30) -> Double {
        let currentCount = classItem.students.count
        return Double(currentCount) / Double(maxCapacity)
    }

    /// 检查班级是否已满
    public func isClassFull(_ classItem: Class, maxCapacity: Int = 30) -> Bool {
        return classItem.students.count >= maxCapacity
    }
}

// MARK: - Errors

public enum ClassServiceError: LocalizedError {
    case emptyTitle
    case emptyRoom
    case classFull

    public var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Class title cannot be empty"
        case .emptyRoom:
            return "Room number cannot be empty"
        case .classFull:
            return "Class has reached maximum capacity"
        }
    }
}
