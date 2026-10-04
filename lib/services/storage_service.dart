/// Placeholder for future local/remote storage operations.
///
/// Currently all data is stored in-memory via [AppProvider].
/// When FastAPI + PostgreSQL integration happens, implement this
/// with HTTP calls or local SQLite persistence.
abstract class StorageService {
  Future<void> initialize();
  Future<void> dispose();
}

/// In-memory stub used during frontend-only development.
class InMemoryStorageService implements StorageService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}
}
