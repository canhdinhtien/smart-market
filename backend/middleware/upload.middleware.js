const cloudinary = require('../config/cloudinary');
const multer = require('multer');

class CloudinaryStreamStorage {
    constructor(options) {
        this.options = options || {};
    }

    _handleFile(req, file, cb) {
        const stream = cloudinary.uploader.upload_stream(
            {
                folder: 'smart-market/profile-pics',
            },
            (error, result) => {
                if (error) {
                    return cb(error);
                }
                cb(null, {
                    path: result.secure_url,
                    filename: result.public_id,
                    size: result.bytes,
                });
            }
        );

        file.stream.pipe(stream);
    }

    _removeFile(req, file, cb) {
        if (file.filename) {
            cloudinary.uploader.destroy(file.filename, cb);
        } else {
            cb(null);
        }
    }
}

const storage = new CloudinaryStreamStorage();
const upload = multer({ storage: storage });

module.exports = upload;
