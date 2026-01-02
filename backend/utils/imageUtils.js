const cloudinary = require('../config/cloudinary');

/**
 * Extracts public ID from Cloudinary URL and deletes the image
 * @param {string} imageUrl - Full Cloudinary URL
 */
const deleteImage = async (imageUrl) => {
    if (!imageUrl) return;

    try {
        // Check if it's a Cloudinary URL
        if (!imageUrl.includes('cloudinary.com')) return;

        // Extract public ID
        // Example: https://res.cloudinary.com/cloud_name/image/upload/v1234567890/folder/filename.jpg
        // We need 'folder/filename' (without extension)

        // Split by '/' and find the index of 'upload'
        const parts = imageUrl.split('/');
        const uploadIndex = parts.indexOf('upload');

        if (uploadIndex === -1) return;

        // The public ID starts after 'v<version>' if it exists, or directly after 'upload'
        // Usually it's: .../upload/v<version>/<public_id>.<ext> or .../upload/<public_id>.<ext>

        // Let's look for the part that might be the version (starts with 'v' and is numeric)
        let publicIdParts = parts.slice(uploadIndex + 1);

        // If first part is a version (e.g. v162...), skip it
        if (publicIdParts[0].match(/^v\d+$/)) {
            publicIdParts = publicIdParts.slice(1);
        }

        // Join the rest back together
        let publicIdWithExt = publicIdParts.join('/');

        // Remove extension
        const dotIndex = publicIdWithExt.lastIndexOf('.');
        if (dotIndex === -1) return; // Should have an extension

        const publicId = publicIdWithExt.substring(0, dotIndex);

        if (publicId) {
            console.log(`Deleting image from Cloudinary: ${publicId}`);
            await cloudinary.uploader.destroy(publicId);
        }
    } catch (error) {
        console.error('Error deleting image from Cloudinary:', error);
        // We don't throw here to avoid failing the main operation (e.g. deleting user)
        // just because image deletion failed.
    }
};

module.exports = {
    deleteImage
};
