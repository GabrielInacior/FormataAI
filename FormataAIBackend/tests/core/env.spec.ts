import { describe, it, expect } from 'vitest';
import { env } from '../../src/core/env';

describe('env', () => {
  it('deve ter PORT como número', () => {
    expect(typeof env.PORT).toBe('number');
  });

  it('deve ter valores padrão para S3', () => {
    expect(env.AWS_REGION).toBeDefined();
    expect(env.S3_BUCKET_NAME).toBeDefined();
    expect(typeof env.S3_DIAS_EXPIRACAO).toBe('number');
  });

  it('deve ter NODE_ENV definido', () => {
    expect(env.NODE_ENV).toBeDefined();
  });

  it('deve ter JWT_SECRET definido', () => {
    expect(env.JWT_SECRET).toBeDefined();
    expect(env.JWT_SECRET.length).toBeGreaterThan(0);
  });

  it('deve ter JWT_EXPIRES_IN definido', () => {
    expect(env.JWT_EXPIRES_IN).toBeDefined();
  });
});
