﻿using Chats.BE.Controllers.Admin.Common;
using Chats.BE.Controllers.Admin.InitialConfigs.Dtos;
using Chats.BE.DB;
using Microsoft.AspNetCore.Mvc;

namespace Chats.BE.Controllers.Admin.InitialConfigs;

[Route("api/admin/user-config"), AuthorizeAdmin]
public class InititalConfigController(ChatsDB db) : ControllerBase
{
    [HttpGet]
    public UserInitialConfigDto[] GetUserInitialConfigs()
    {
        UserInitialConfigDto[] data = db.UserInitialConfigs
            .OrderByDescending(x => x.UpdatedAt)
            .Select(x => new UserInitialConfigDtoTemp()
            {
                Id = x.Id,
                Name = x.Name,
                LoginType = x.LoginType ?? "-",
                Models = x.Models,
                Price = x.Price,
                InvitationCodeId = x.InvitationCodeId,
                InvitationCode = x.InvitationCode!.Value ?? "-",
            })
            .AsEnumerable()
            .Select(x => x.ToDto())
            .ToArray();
        return data;
    }

    [HttpPut]
    public async Task<ActionResult> UpdateInitialConfig([FromBody] UserInitialConfigUpdateRequest req, CancellationToken cancellationToken)
    {
        UserInitialConfig? existingConfig = await db.UserInitialConfigs.FindAsync([req.Id], cancellationToken);
        if (existingConfig == null)
        {
            return NotFound();
        }

        req.ApplyTo(existingConfig);
        if (db.ChangeTracker.HasChanges())
        {
            existingConfig.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync(cancellationToken);
        }

        return NoContent();
    }

    [HttpDelete]
    public async Task<ActionResult> DeleteInitialConfig(Guid id, CancellationToken cancellationToken)
    {
        UserInitialConfig? existingConfig = await db.UserInitialConfigs.FindAsync([id], cancellationToken);
        if (existingConfig == null)
        {
            return NotFound();
        }

        db.UserInitialConfigs.Remove(existingConfig);
        await db.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    [HttpPost]
    public async Task CreateInitialConfig([FromBody] UserInitialConfigCreateRequest req, CancellationToken cancellationToken)
    {
        UserInitialConfig newOne = new()
        {
            CreatedAt = DateTime.UtcNow, 
            UpdatedAt = DateTime.UtcNow, 
        };

        req.ApplyTo(newOne);
        await db.UserInitialConfigs.AddAsync(newOne, cancellationToken);
        await db.SaveChangesAsync(cancellationToken);
    }
}
