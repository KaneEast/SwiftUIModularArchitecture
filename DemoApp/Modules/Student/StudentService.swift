//
//  StudentService.swift
//  KanjiDemo - Student Business Logic Service
//
//  集中管理 Student 相关的核心业务逻辑
//

import Foundation
import Combine

/// Student 模块的核心业务逻辑服务
/// 职责：封装和组织 Student 相关的所有业务操作
public final class StudentService {
    private let repository: StudentRepository
    private let apiService: RandomUserAPIService

    public init(repository: StudentRepository, apiService: RandomUserAPIService) {
        self.repository = repository
        self.apiService = apiService
    }

    // MARK: - Core Business Logic

    /// 获取所有学生（响应式）
    public func observeStudents() -> AnyPublisher<[Student], Never> {
        return repository.observeAll()
    }

    /// 从网络获取随机学生并保存到数据库
    public func fetchAndSaveRandomStudents(count: Int) async throws -> [Student] {
        // 1. 调用 API
        let randomUsers = try await apiService.fetchRandomUsers(count: count)

        // 2. 转换数据
        let students = randomUsers.map { user in
            Student(
                name: "\(user.name.first) \(user.name.last)",
                email: user.email,
                grade: Int.random(in: 9...12)
            )
        }

        // 3. 保存到数据库
        for student in students {
            try repository.create(student)
        }

        return students
    }

    /// 删除学生（业务规则：同时从所有班级中移除）
    public func deleteStudent(_ student: Student) throws {
        // 业务逻辑：删除前检查
        guard !student.classes.isEmpty else {
            try repository.delete(student)
            return
        }

        // 先从所有班级中移除
        student.classes.removeAll()

        // 再删除学生
        try repository.delete(student)
    }

    /// 将学生加入班级（业务规则：检查重复、容量限制等）
    public func enrollStudent(_ student: Student, in classItem: Class) throws {
        // 业务规则：检查是否已经加入
        guard !student.classes.contains(classItem) else {
            throw StudentServiceError.alreadyEnrolled
        }

        // 业务规则：检查班级容量（示例）
        guard classItem.students.count < 30 else {
            throw StudentServiceError.classIsFull
        }

        // 执行加入
        student.classes.append(classItem)
        try repository.update(student)
    }

    /// 搜索学生（业务逻辑：支持模糊搜索）
    public func searchStudents(by query: String, from students: [Student]) -> [Student] {
        guard !query.isEmpty else { return students }

        return students.filter { student in
            student.name.localizedCaseInsensitiveContains(query) ||
            student.email.localizedCaseInsensitiveContains(query)
        }
    }
}

// MARK: - Errors

public enum StudentServiceError: LocalizedError {
    case alreadyEnrolled
    case classIsFull

    public var errorDescription: String? {
        switch self {
        case .alreadyEnrolled:
            return "Student is already enrolled in this class"
        case .classIsFull:
            return "Class has reached maximum capacity"
        }
    }
}
