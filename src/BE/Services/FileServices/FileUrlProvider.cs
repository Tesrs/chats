﻿using Chats.BE.Controllers.Chats.Messages.Dtos;
using Chats.BE.DB.Enums;
using Chats.BE.Services.UrlEncryption;
using OpenAI.Chat;

namespace Chats.BE.Services.FileServices;

public class FileUrlProvider(FileServiceFactory fileServiceFactory, IUrlEncryptionService urlEncryptionService)
{
    public async Task<ChatMessageContentPart> CreateOpenAIPart(DB.File file, CancellationToken cancellationToken)
    {
        DBFileServiceType fileServiceType = (DBFileServiceType)file.FileService.FileServiceTypeId;
        IFileService fs = fileServiceFactory.Create(fileServiceType, file.FileService.Configs);
        if (file.FileService.FileServiceTypeId == (byte)DBFileServiceType.Local)
        {
            MemoryStream ms = new();
            using Stream stream = await fs.Download(file.StorageKey, cancellationToken);
            await stream.CopyToAsync(ms, cancellationToken);
            ms.Position = 0;

            BinaryData binaryData = BinaryData.FromStream(ms);
            return ChatMessageContentPart.CreateImagePart(binaryData, file.FileContentType.ContentType);
        }
        else
        {
            Uri url = fs.CreateDownloadUrl(CreateDownloadUrlRequest.FromFile(file));
            return ChatMessageContentPart.CreateImagePart(url);
        }
    }

    public FileDto CreateFileDto(DB.File file)
    {
        DBFileServiceType fileServiceType = (DBFileServiceType)file.FileService.FileServiceTypeId;
        IFileService fs = fileServiceFactory.Create(fileServiceType, file.FileService.Configs);
        Uri downloadUrl = fs.CreateDownloadUrl(CreateDownloadUrlRequest.FromFile(file));

        return new FileDto
        {
            Id = urlEncryptionService.EncryptFileId(file.Id),
            Url = downloadUrl,
        };
    }
}
