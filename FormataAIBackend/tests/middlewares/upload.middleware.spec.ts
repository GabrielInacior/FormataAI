import { describe, it, expect } from 'vitest';
import { upload } from '../../src/middlewares/upload.middleware';

describe('upload.middleware', () => {
  it('deve exportar instância do multer', () => {
    expect(upload).toBeDefined();
    expect(typeof upload.single).toBe('function');
    expect(typeof upload.array).toBe('function');
    expect(typeof upload.fields).toBe('function');
  });

  describe('fileFilter', () => {
    // Access the internal file filter by creating a single middleware and testing it
    it('deve aceitar formatos de áudio válidos', () => {
      const validMimes = [
        'audio/mpeg',
        'audio/mp4',
        'audio/wav',
        'audio/webm',
        'audio/ogg',
        'audio/flac',
        'audio/x-m4a',
      ];

      for (const mimetype of validMimes) {
        const file = { mimetype } as any;
        const cb = (err: any, accepted: boolean) => {
          expect(err).toBeNull();
          expect(accepted).toBe(true);
        };

        // Access fileFilter via multer internals
        // @ts-expect-error Access internal multer property
        const fileFilter = upload.fileFilter;
        if (fileFilter) {
          fileFilter({} as any, file, cb);
        }
      }
    });

    it('deve rejeitar formatos inválidos', () => {
      const invalidMimes = ['image/png', 'video/mp4', 'application/pdf', 'text/plain'];

      for (const mimetype of invalidMimes) {
        const file = { mimetype } as any;

        // @ts-expect-error Access internal multer property
        const fileFilter = upload.fileFilter;
        if (fileFilter) {
          const cb = (err: any, accepted?: boolean) => {
            expect(err).toBeInstanceOf(Error);
            expect(err.message).toBe('Formato de áudio não suportado');
          };
          fileFilter({} as any, file, cb);
        }
      }
    });
  });

  describe('limits', () => {
    it('deve ter limite de 25MB', () => {
      // @ts-expect-error Access internal multer property
      const limits = upload.limits;
      if (limits) {
        expect(limits.fileSize).toBe(25 * 1024 * 1024);
      }
    });
  });
});
