import multer, { MulterError } from "multer";
import { Request, Response, NextFunction } from "express";

const storage = multer.memoryStorage();

const multerUpload = multer({
    storage,
    limits: {
        fileSize: 5 * 1024 * 1024, // Maksimal 5MB
    },
    fileFilter: (_req, file, cb) => {
        const allowedMimetypes = ["image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp"];
        const allowedExtensions = /\.(jpg|jpeg|png|gif|webp)$/i;

        const mimetypeOk = allowedMimetypes.includes(file.mimetype) || file.mimetype.startsWith("image/");
        const extnameOk = allowedExtensions.test(file.originalname);

        if (mimetypeOk || extnameOk) {
            cb(null, true);
        } else {
            cb(new Error("Hanya file gambar yang diperbolehkan!"));
        }
    },
}).single("image");

// Wrapped middleware that returns JSON errors instead of HTML
export const uploadSingleImage = (req: Request, res: Response, next: NextFunction) => {
    multerUpload(req, res, (err) => {
        if (!err) return next();

        if (err instanceof MulterError) {
            if (err.code === "LIMIT_FILE_SIZE") {
                return res.status(400).json({
                    success: false,
                    message: "Ukuran file terlalu besar. Maksimal 5MB.",
                });
            }
            return res.status(400).json({
                success: false,
                message: err.message,
            });
        }

        // fileFilter error (wrong mimetype, etc.)
        return res.status(400).json({
            success: false,
            message: err.message,
        });
    });
};
