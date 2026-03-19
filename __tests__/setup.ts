/**
 * Global test configuration for Bun
 */

import { beforeAll, afterAll } from 'bun:test';

beforeAll(() => {
  process.env.DATABASE_URL = 'postgresql://test:test@localhost:5432/test_db';
  process.env.BETTER_AUTH_SECRET = 'test-secret-key-for-testing-only';
  process.env.BETTER_AUTH_URL = 'http://localhost:5023';
  process.env.NEXT_PUBLIC_BETTER_AUTH_URL = 'http://localhost:5023';
});

afterAll(() => {
  // Cleanup if needed
});
