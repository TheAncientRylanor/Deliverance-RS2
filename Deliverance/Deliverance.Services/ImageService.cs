using Deliverance.Model.Exceptions;
using Microsoft.AspNetCore.Http;

namespace Deliverance.Services;

public static class ImageService
{
    public const long MaxImageBytes = 5 * 1024 * 1024;
    private const string UserProfilesFolder = "userProfiles";

    private sealed record ImageFormat(string Extension, string ContentType, string[] Extensions, string[] ContentTypes);

    private static readonly ImageFormat Jpeg = new(".jpg", "image/jpeg", [".jpg", ".jpeg"], ["image/jpeg", "image/jpg", "image/pjpeg"]);
    private static readonly ImageFormat Png = new(".png", "image/png", [".png"], ["image/png"]);
    private static readonly ImageFormat Webp = new(".webp", "image/webp", [".webp"], ["image/webp"]);
    private static readonly ImageFormat[] Formats = [Jpeg, Png, Webp];
    private static readonly string[] AllowedExtensions = Formats.SelectMany(f => f.Extensions).ToArray();

    public static async Task<string> SaveUserImageAsync(IFormFile image, Guid userId, string storageRoot)
    {
        var format = await ValidateAsync(image);

        var folderPath = Path.Combine(storageRoot, UserProfilesFolder);
        Directory.CreateDirectory(folderPath);
        DeleteExistingImage(userId, folderPath);

        var fileName = $"{userId}{format.Extension}";
        await using (var stream = new FileStream(Path.Combine(folderPath, fileName), FileMode.Create))
        {
            await image.CopyToAsync(stream);
        }

        return $"{UserProfilesFolder}/{fileName}";
    }

    public static (string FilePath, string ContentType)? FindUserImage(Guid userId, string storageRoot)
    {
        var folderPath = Path.Combine(storageRoot, UserProfilesFolder);
        foreach (var format in Formats)
        {
            foreach (var extension in format.Extensions)
            {
                var path = Path.Combine(folderPath, $"{userId}{extension}");
                if (File.Exists(path))
                {
                    return (path, format.ContentType);
                }
            }
        }
        return null;
    }

    private static async Task<ImageFormat> ValidateAsync(IFormFile? image)
    {
        if (image is null || image.Length == 0)
        {
            throw new BusinessException("No image file was provided.");
        }

        if (image.Length > MaxImageBytes)
        {
            throw new BusinessException($"Images can be at most {MaxImageBytes / (1024 * 1024)} MB.");
        }

        var extension = Path.GetExtension(image.FileName).ToLowerInvariant();
        if (!AllowedExtensions.Contains(extension))
        {
            throw new BusinessException($"Images must be JPG, PNG or WebP; '{extension}' files are not allowed.");
        }

        var detected = await DetectFormatAsync(image)
            ?? throw new BusinessException("The file is not a valid JPG, PNG or WebP image.");
        var detectedName = detected.Extension.TrimStart('.').ToUpperInvariant();

        if (!detected.Extensions.Contains(extension))
        {
            throw new BusinessException($"The file's name ends in '{extension}', but its content is a {detectedName} image.");
        }

        var declared = image.ContentType?.Split(';')[0].Trim().ToLowerInvariant();
        if (!string.IsNullOrEmpty(declared) && declared != "application/octet-stream" && !detected.ContentTypes.Contains(declared))
        {
            throw new BusinessException($"The file was sent as '{declared}', but its content is a {detectedName} image.");
        }

        return detected;
    }

    private static async Task<ImageFormat?> DetectFormatAsync(IFormFile image)
    {
        var header = new byte[12];
        await using var stream = image.OpenReadStream();
        var read = await stream.ReadAtLeastAsync(header, header.Length, throwOnEndOfStream: false);

        if (read >= 3 && header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF)
        {
            return Jpeg;
        }
        if (read >= 8 && header.AsSpan(0, 8).SequenceEqual(new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A }))
        {
            return Png;
        }
        if (read >= 12 && header.AsSpan(0, 4).SequenceEqual("RIFF"u8) && header.AsSpan(8, 4).SequenceEqual("WEBP"u8))
        {
            return Webp;
        }
        return null;
    }

    private static void DeleteExistingImage(Guid userId, string folderPath)
    {
        foreach (var extension in AllowedExtensions)
        {
            var existing = Path.Combine(folderPath, $"{userId}{extension}");
            if (File.Exists(existing))
            {
                File.Delete(existing);
            }
        }
    }
}
