import multer from 'multer';

const storage = multer.memoryStorage();

export const upload = multer({
  storage,
  limits: {
    fileSize: 25 * 1024 * 1024, // 25MB
  },
  fileFilter: (_req, file, cb) => {
    const allowedMimes = [
      'audio/mpeg',
      'audio/mp4',
      'audio/wav',
      'audio/x-wav',
      'audio/wave',
      'audio/webm',
      'audio/ogg',
      'audio/opus',              // WhatsApp voice messages (.opus)
      'audio/flac',
      'audio/x-flac',
      'audio/x-m4a',
      'audio/aac',               // AAC files
      'audio/x-aac',
      'video/mp4',               // Some audio-in-video containers
      'video/webm',
      'video/ogg',
      'application/octet-stream', // Generic binary (MIME não determinado pelo cliente)
    ];

    const mime = file.mimetype.split(';')[0].trim(); // ignora parâmetros como "; codecs=opus"
    if (allowedMimes.includes(mime)) {
      cb(null, true);
    } else {
      cb(new Error('Formato de áudio não suportado'));
    }
  },
});
