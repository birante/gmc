// Runs before every test file (before the app's env module is imported).
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET ??= 'test-secret-test-secret-test-secret-123456';
process.env.CORS_ORIGINS ??= 'http://localhost:5173';

// Integration tests need a real PostgreSQL: TEST_DATABASE_URL (preferred) or DATABASE_URL.
const dbUrl = process.env.TEST_DATABASE_URL ?? process.env.DATABASE_URL;
process.env.VAXTRACK_HAS_DB = dbUrl ? '1' : '';
// Unit tests never open a connection, but the env schema requires a value.
process.env.DATABASE_URL = dbUrl ?? 'postgresql://unused:unused@localhost:5432/unused';
