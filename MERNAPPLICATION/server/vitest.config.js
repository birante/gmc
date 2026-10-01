import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    env: { NODE_ENV: 'test', JWT_SECRET: 'test-secret' },
    hookTimeout: 120000,
    testTimeout: 30000,
    fileParallelism: false,
  },
});
