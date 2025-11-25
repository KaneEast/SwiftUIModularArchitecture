# KanjiDemo Architecture Improvements Plan

## High Priority (Fixes)
1. **Fix memory leak in BaseRepository.observeAll()** - Restructure closure captures
2. **Add error handling in ViewModels** - Handle repository failures gracefully
3. **Optimize repository queries** - Use predicates instead of filtering in memory
4. **Add @MainActor annotations** - Fix concurrency warnings

## Medium Priority (Enhancements)
5. **Add loading states** - Show loading indicators during data fetch
6. **Add CRUD operations to ViewModels** - Enable delete/update/enroll operations
7. **Improve NetworkService** - Add retry logic, timeouts, cancellation
8. **Add protocols for repositories** - Enable dependency injection and testing

## Low Priority (Polish)
9. **Extract constants** - Remove hard-coded values (throttle, grade ranges)
10. **Add documentation** - Document complex reactive flows
11. **Simplify BaseRepository.observeAll()** - Break into smaller methods
12. **Add data validation** - Validate email format, grade ranges

Would you like me to implement any of these improvements?