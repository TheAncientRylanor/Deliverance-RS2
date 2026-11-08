using Deliverance.Model.Exceptions;
using Microsoft.AspNetCore.Http;

namespace Deliverance.Services
{
    public static class ImageService
    {
        private const string UserProfilesFolder = "userProfiles";
        private const string ContactProfilesFolder = "contactProfiles";
        private static readonly string[] AllowedExtensions = { ".jpg", ".jpeg", ".png", ".webp" };

        /// <summary>
        /// Saves an image under wwwroot/{baseFolder}/{subFolder?}/{id}.ext.
        /// Use for both user profile images (baseFolder: userProfiles, no subFolder)
        /// and contact images (baseFolder: contactProfiles, subFolder: userId).
        /// </summary>
        public static async Task<string> SaveImageAsync(
            IFormFile image,
            Guid id,
            string baseFolder,
            string webRootPath,
            string? subFolder = null)
        {
            if (image is null || image.Length == 0)
                throw new BusinessException("No image file was provided.");

            var extension = Path.GetExtension(image.FileName).ToLowerInvariant();
            if (!AllowedExtensions.Contains(extension))
                throw new BusinessException($"Images must be {string.Join(", ", AllowedExtensions)}; '{extension}' is not allowed.");

            var folderPath = BuildFolderPath(webRootPath, baseFolder, subFolder);
            Directory.CreateDirectory(folderPath);
            DeleteExistingImage(id, baseFolder, webRootPath, subFolder);

            var fileName = $"{id}{extension}";
            var filePath = Path.Combine(folderPath, fileName);

            await using var stream = new FileStream(filePath, FileMode.Create);
            await image.CopyToAsync(stream);

            return BuildWebPath(baseFolder, subFolder, fileName);
        }

        public static string? GetImagePath(
            Guid id,
            string baseFolder,
            string webRootPath,
            string? subFolder = null)
        {
            var folderPath = BuildFolderPath(webRootPath, baseFolder, subFolder);
            if (!Directory.Exists(folderPath))
                return null;

            var match = AllowedExtensions
                .Select(ext => Path.Combine(folderPath, $"{id}{ext}"))
                .FirstOrDefault(File.Exists);

            if (match is null)
                return null;

            var fileName = Path.GetFileName(match);
            return BuildWebPath(baseFolder, subFolder, fileName);
        }

        public static async Task<(byte[] Bytes, string ContentType)?> GetImageBytesAsync(
            Guid id,
            string baseFolder,
            string webRootPath,
            string? subFolder = null)
        {
            var folderPath = BuildFolderPath(webRootPath, baseFolder, subFolder);
            var match = AllowedExtensions
                .Select(ext => Path.Combine(folderPath, $"{id}{ext}"))
                .FirstOrDefault(File.Exists);

            if (match is null)
                return null;

            var bytes = await File.ReadAllBytesAsync(match);
            var contentType = Path.GetExtension(match).ToLowerInvariant() switch
            {
                ".jpg" or ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                ".webp" => "image/webp",
                _ => "application/octet-stream"
            };

            return (bytes, contentType);
        }

        public static void DeleteExistingImage(
            Guid id,
            string baseFolder,
            string webRootPath,
            string? subFolder = null)
        {
            var folderPath = BuildFolderPath(webRootPath, baseFolder, subFolder);
            if (!Directory.Exists(folderPath))
                return;

            foreach (var ext in AllowedExtensions)
            {
                var existing = Path.Combine(folderPath, $"{id}{ext}");
                if (File.Exists(existing))
                    File.Delete(existing);
            }
        }

        public static Task<string> SaveUserImageAsync(IFormFile image, Guid userId, string webRootPath) =>
            SaveImageAsync(image, userId, UserProfilesFolder, webRootPath);

        public static Task<string> SaveContactImageAsync(
            IFormFile image, Guid contactId, Guid userId, string webRootPath) =>
            SaveImageAsync(image, contactId, ContactProfilesFolder, webRootPath, subFolder: userId.ToString());

        private static string BuildFolderPath(string webRootPath, string baseFolder, string? subFolder) =>
            subFolder is null
                ? Path.Combine(webRootPath, baseFolder)
                : Path.Combine(webRootPath, baseFolder, subFolder);

        private static string BuildWebPath(string baseFolder, string? subFolder, string fileName) =>
            subFolder is null
                ? $"/{baseFolder}/{fileName}"
                : $"/{baseFolder}/{subFolder}/{fileName}";
    }
}