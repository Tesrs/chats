﻿/* 为了防止任何可能出现的数据丢失问题，您应该先仔细检查此脚本，然后再在数据库设计器的上下文之外运行此脚本。*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.Model SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.Chat SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
CREATE TABLE dbo.ChatSpan
	(
	ChatId int NOT NULL,
	SpanId tinyint NOT NULL,
	ModelId smallint NOT NULL,
	Temperature real NULL,
	EnableSearch bit NOT NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.ChatSpan ADD CONSTRAINT
	PK_ChatSpan PRIMARY KEY CLUSTERED 
	(
	ChatId,
	SpanId
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
CREATE NONCLUSTERED INDEX IX_ChatSpan_Model ON dbo.ChatSpan
	(
	ModelId
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE dbo.ChatSpan ADD CONSTRAINT
	FK_ChatSpan_Chat FOREIGN KEY
	(
	ChatId
	) REFERENCES dbo.Chat
	(
	Id
	) ON UPDATE  CASCADE 
	 ON DELETE  CASCADE 
	
GO
ALTER TABLE dbo.ChatSpan ADD CONSTRAINT
	FK_ChatSpan_Model FOREIGN KEY
	(
	ModelId
	) REFERENCES dbo.Model
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.ChatSpan SET (LOCK_ESCALATION = TABLE)
GO
COMMIT


-- 将数据从 Chat 表迁移到 ChatSpan 表
INSERT INTO dbo.ChatSpan (ChatId, SpanId, ModelId, Temperature, EnableSearch)
SELECT
    Id AS ChatId,
    0 AS SpanId, -- 所有记录的 SpanId 都填 0
    ModelId,
    Temperature,
    ISNULL(EnableSearch, 0) AS EnableSearch -- 确保 EnableSearch 不为 NULL，默认为 0
FROM
    dbo.Chat;


/* 为了防止任何可能出现的数据丢失问题，您应该先仔细检查此脚本，然后再在数据库设计器的上下文之外运行此脚本。*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.Chat
	DROP CONSTRAINT FK_Conversation2_Model
GO
ALTER TABLE dbo.Model SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
DROP INDEX IX_Conversation2_Model ON dbo.Chat
GO
ALTER TABLE dbo.Chat
	DROP COLUMN ModelId, Temperature, EnableSearch
GO
ALTER TABLE dbo.Chat SET (LOCK_ESCALATION = TABLE)
GO
COMMIT



/* 为了防止任何可能出现的数据丢失问题，您应该先仔细检查此脚本，然后再在数据库设计器的上下文之外运行此脚本。*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.ChatSpan SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.Message
	DROP CONSTRAINT FK_Message_Chat
GO
ALTER TABLE dbo.Chat SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.Message
	DROP CONSTRAINT FK_Message_ChatRole
GO
ALTER TABLE dbo.ChatRole SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.Message
	DROP CONSTRAINT FK_Message_UserModelUsage
GO
ALTER TABLE dbo.UserModelUsage SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
CREATE TABLE dbo.Tmp_Message
	(
	Id bigint NOT NULL IDENTITY (1, 1),
	ChatId int NOT NULL,
	SpanId tinyint NOT NULL,
	ParentId bigint NULL,
	ChatRoleId tinyint NOT NULL,
	UsageId bigint NULL,
	CreatedAt datetime2(7) NOT NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_Message SET (LOCK_ESCALATION = TABLE)
GO
ALTER TABLE dbo.Tmp_Message ADD CONSTRAINT
	DF_Message_SpanId DEFAULT 0 FOR SpanId
GO
SET IDENTITY_INSERT dbo.Tmp_Message ON
GO
IF EXISTS(SELECT * FROM dbo.Message)
	 EXEC('INSERT INTO dbo.Tmp_Message (Id, ChatId, ParentId, ChatRoleId, UsageId, CreatedAt)
		SELECT Id, ChatId, ParentId, ChatRoleId, UsageId, CreatedAt FROM dbo.Message WITH (HOLDLOCK TABLOCKX)')
GO
SET IDENTITY_INSERT dbo.Tmp_Message OFF
GO
ALTER TABLE dbo.Message
	DROP CONSTRAINT FK_Message_ParentMessage
GO
ALTER TABLE dbo.MessageContent
	DROP CONSTRAINT FK_MessageContent_Message
GO
DROP TABLE dbo.Message
GO
EXECUTE sp_rename N'dbo.Tmp_Message', N'Message', 'OBJECT' 
GO
ALTER TABLE dbo.Message ADD CONSTRAINT
	PK_Message PRIMARY KEY CLUSTERED 
	(
	Id
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
CREATE NONCLUSTERED INDEX IX_Message_ChatSpan ON dbo.Message
	(
	ChatId,
	SpanId
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX IX_Message_Usage ON dbo.Message
	(
	UsageId
	) WHERE ([UsageId] IS NOT NULL)
 WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE dbo.Message ADD CONSTRAINT
	FK_Message_UserModelUsage FOREIGN KEY
	(
	UsageId
	) REFERENCES dbo.UserModelUsage
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.Message ADD CONSTRAINT
	FK_Message_ChatRole FOREIGN KEY
	(
	ChatRoleId
	) REFERENCES dbo.ChatRole
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.Message ADD CONSTRAINT
	FK_Message_Chat FOREIGN KEY
	(
	ChatId
	) REFERENCES dbo.Chat
	(
	Id
	) ON UPDATE  CASCADE 
	 ON DELETE  CASCADE 
	
GO
ALTER TABLE dbo.Message ADD CONSTRAINT
	FK_Message_ParentMessage FOREIGN KEY
	(
	ParentId
	) REFERENCES dbo.Message
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.Message ADD CONSTRAINT
	FK_Message_ChatSpan FOREIGN KEY
	(
	ChatId,
	SpanId
	) REFERENCES dbo.ChatSpan
	(
	ChatId,
	SpanId
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.MessageContent ADD CONSTRAINT
	FK_MessageContent_Message FOREIGN KEY
	(
	MessageId
	) REFERENCES dbo.Message
	(
	Id
	) ON UPDATE  CASCADE 
	 ON DELETE  CASCADE 
	
GO
ALTER TABLE dbo.MessageContent SET (LOCK_ESCALATION = TABLE)
GO
COMMIT


ALTER TABLE dbo.FileImageInfo
	DROP CONSTRAINT PK__FileImag__6F0F98BF7788B2FE
ALTER TABLE dbo.FileImageInfo ADD CONSTRAINT
	PK_FileImageInfo PRIMARY KEY CLUSTERED 
	(
	FileId
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

/* 为了防止任何可能出现的数据丢失问题，您应该先仔细检查此脚本，然后再在数据库设计器的上下文之外运行此脚本。*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.FileService
	DROP CONSTRAINT FK_FileService_FileServiceType
GO
ALTER TABLE dbo.FileServiceType
	DROP CONSTRAINT PK__FileServ__3214EC07079F57F9
GO
ALTER TABLE dbo.FileServiceType ADD CONSTRAINT
	PK_FileServiceType PRIMARY KEY CLUSTERED 
	(
	Id
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE dbo.FileServiceType SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.FileService ADD CONSTRAINT
	FK_FileService_FileServiceType FOREIGN KEY
	(
	FileServiceTypeId
	) REFERENCES dbo.FileServiceType
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.FileService SET (LOCK_ESCALATION = TABLE)
GO
COMMIT


/* 为了防止任何可能出现的数据丢失问题，您应该先仔细检查此脚本，然后再在数据库设计器的上下文之外运行此脚本。*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.MessageContentBlob
	DROP CONSTRAINT PK__MessageC__3214EC070E90C6FD
GO
ALTER TABLE dbo.MessageContentBlob ADD CONSTRAINT
	PK_MessageContentBlob PRIMARY KEY CLUSTERED 
	(
	Id
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE dbo.MessageContentBlob SET (LOCK_ESCALATION = TABLE)
GO
COMMIT


/* 为了防止任何可能出现的数据丢失问题，您应该先仔细检查此脚本，然后再在数据库设计器的上下文之外运行此脚本。*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.MessageContentFile
	DROP CONSTRAINT PK__MessageC__3214EC07E339561A
GO
ALTER TABLE dbo.MessageContentFile ADD CONSTRAINT
	PK_MessageContentFile PRIMARY KEY CLUSTERED 
	(
	Id
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE dbo.MessageContentFile SET (LOCK_ESCALATION = TABLE)
GO
COMMIT

/* 为了防止任何可能出现的数据丢失问题，您应该先仔细检查此脚本，然后再在数据库设计器的上下文之外运行此脚本。*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.MessageContentText
	DROP CONSTRAINT PK__MessageC__3214EC07E9326D58
GO
ALTER TABLE dbo.MessageContentText ADD CONSTRAINT
	PK_MessageContentText PRIMARY KEY CLUSTERED 
	(
	Id
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE dbo.MessageContentText SET (LOCK_ESCALATION = TABLE)
GO
COMMIT



/* 为了防止任何可能出现的数据丢失问题，您应该先仔细检查此脚本，然后再在数据库设计器的上下文之外运行此脚本。*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.[User]
	DROP CONSTRAINT Users2_role_df
GO
ALTER TABLE dbo.[User]
	DROP CONSTRAINT Users2_enabled_df
GO
ALTER TABLE dbo.[User]
	DROP CONSTRAINT Users2_createdAt_df
GO
CREATE TABLE dbo.Tmp_User
	(
	Id int NOT NULL IDENTITY (1, 1),
	Avatar nvarchar(1000) NULL,
	UserName nvarchar(1000) NOT NULL,
	DisplayName nvarchar(1000) NOT NULL,
	PasswordHash varchar(1000) NULL,
	Email nvarchar(1000) NULL,
	Phone nvarchar(1000) NULL,
	Role nvarchar(1000) NOT NULL,
	Enabled bit NOT NULL,
	Provider varchar(1000) NULL,
	Sub nvarchar(1000) NULL,
	CreatedAt datetime2(7) NOT NULL,
	UpdatedAt datetime2(7) NOT NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_User SET (LOCK_ESCALATION = TABLE)
GO
ALTER TABLE dbo.Tmp_User ADD CONSTRAINT
	Users2_role_df DEFAULT ('-') FOR Role
GO
ALTER TABLE dbo.Tmp_User ADD CONSTRAINT
	Users2_enabled_df DEFAULT ((1)) FOR Enabled
GO
ALTER TABLE dbo.Tmp_User ADD CONSTRAINT
	Users2_createdAt_df DEFAULT (getdate()) FOR CreatedAt
GO
SET IDENTITY_INSERT dbo.Tmp_User ON
GO
IF EXISTS(SELECT * FROM dbo.[User])
	 EXEC('INSERT INTO dbo.Tmp_User (Id, Avatar, UserName, DisplayName, PasswordHash, Email, Phone, Role, Enabled, Provider, Sub, CreatedAt, UpdatedAt)
		SELECT Id, Avatar, Account, Username, CONVERT(varchar(1000), Password), Email, Phone, Role, Enabled, CONVERT(varchar(1000), Provider), Sub, CreatedAt, UpdatedAt FROM dbo.[User] WITH (HOLDLOCK TABLOCKX)')
GO
SET IDENTITY_INSERT dbo.Tmp_User OFF
GO
ALTER TABLE dbo.BalanceTransaction
	DROP CONSTRAINT FK_BalanceTransaction_UserId
GO
ALTER TABLE dbo.BalanceTransaction
	DROP CONSTRAINT FK_BalanceTransaction_CreditUserId
GO
ALTER TABLE dbo.Chat
	DROP CONSTRAINT FK_Chat_UserId
GO
ALTER TABLE dbo.SmsRecord
	DROP CONSTRAINT FK_SmsRecord_UserId
GO
ALTER TABLE dbo.UserApiKey
	DROP CONSTRAINT FK_UserApiKey_UserId
GO
ALTER TABLE dbo.UserModel
	DROP CONSTRAINT FK_UserModel_UserId
GO
ALTER TABLE dbo.UserInvitation
	DROP CONSTRAINT FK_UserInvitation_Users
GO
ALTER TABLE dbo.UserBalance
	DROP CONSTRAINT FK_UserBalance_UserId
GO
ALTER TABLE dbo.Prompt
	DROP CONSTRAINT FK_Prompt_CreateUserId
GO
ALTER TABLE dbo.UsageTransaction
	DROP CONSTRAINT FK_UsageTransaction_User
GO
ALTER TABLE dbo.[File]
	DROP CONSTRAINT FK_File_User
GO
DROP TABLE dbo.[User]
GO
EXECUTE sp_rename N'dbo.Tmp_User', N'User', 'OBJECT' 
GO
ALTER TABLE dbo.[User] ADD CONSTRAINT
	Users2_pkey PRIMARY KEY CLUSTERED 
	(
	Id
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.[File] ADD CONSTRAINT
	FK_File_User FOREIGN KEY
	(
	CreateUserId
	) REFERENCES dbo.[User]
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.[File] SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.UsageTransaction ADD CONSTRAINT
	FK_UsageTransaction_User FOREIGN KEY
	(
	CreditUserId
	) REFERENCES dbo.[User]
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.UsageTransaction SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.Prompt ADD CONSTRAINT
	FK_Prompt_CreateUserId FOREIGN KEY
	(
	CreateUserId
	) REFERENCES dbo.[User]
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.Prompt SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.UserBalance ADD CONSTRAINT
	FK_UserBalance_UserId FOREIGN KEY
	(
	UserId
	) REFERENCES dbo.[User]
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.UserBalance SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.UserInvitation ADD CONSTRAINT
	FK_UserInvitation_Users FOREIGN KEY
	(
	UserId
	) REFERENCES dbo.[User]
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.UserInvitation SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.UserModel ADD CONSTRAINT
	FK_UserModel_UserId FOREIGN KEY
	(
	UserId
	) REFERENCES dbo.[User]
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.UserModel SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.UserApiKey ADD CONSTRAINT
	FK_UserApiKey_UserId FOREIGN KEY
	(
	UserId
	) REFERENCES dbo.[User]
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.UserApiKey SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.SmsRecord ADD CONSTRAINT
	FK_SmsRecord_UserId FOREIGN KEY
	(
	UserId
	) REFERENCES dbo.[User]
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.SmsRecord SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.Chat ADD CONSTRAINT
	FK_Chat_UserId FOREIGN KEY
	(
	UserId
	) REFERENCES dbo.[User]
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.Chat SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.BalanceTransaction ADD CONSTRAINT
	FK_BalanceTransaction_UserId FOREIGN KEY
	(
	UserId
	) REFERENCES dbo.[User]
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.BalanceTransaction ADD CONSTRAINT
	FK_BalanceTransaction_CreditUserId FOREIGN KEY
	(
	CreditUserId
	) REFERENCES dbo.[User]
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.BalanceTransaction SET (LOCK_ESCALATION = TABLE)
GO
COMMIT



/* 为了防止任何可能出现的数据丢失问题，您应该先仔细检查此脚本，然后再在数据库设计器的上下文之外运行此脚本。*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.Message
	DROP CONSTRAINT FK_Message_ChatSpan
GO
ALTER TABLE dbo.ChatSpan SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.Message
	DROP CONSTRAINT FK_Message_Chat
GO
ALTER TABLE dbo.Chat SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.Message
	DROP CONSTRAINT FK_Message_ChatRole
GO
ALTER TABLE dbo.ChatRole SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.Message
	DROP CONSTRAINT FK_Message_UserModelUsage
GO
ALTER TABLE dbo.UserModelUsage SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.Message
	DROP CONSTRAINT DF_Message_SpanId
GO
CREATE TABLE dbo.Tmp_Message
	(
	Id bigint NOT NULL IDENTITY (1, 1),
	ChatId int NOT NULL,
	SpanId tinyint NULL,
	ParentId bigint NULL,
	ChatRoleId tinyint NOT NULL,
	UsageId bigint NULL,
	CreatedAt datetime2(7) NOT NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_Message SET (LOCK_ESCALATION = TABLE)
GO
SET IDENTITY_INSERT dbo.Tmp_Message ON
GO
IF EXISTS(SELECT * FROM dbo.Message)
	 EXEC('INSERT INTO dbo.Tmp_Message (Id, ChatId, SpanId, ParentId, ChatRoleId, UsageId, CreatedAt)
		SELECT Id, ChatId, SpanId, ParentId, ChatRoleId, UsageId, CreatedAt FROM dbo.Message WITH (HOLDLOCK TABLOCKX)')
GO
SET IDENTITY_INSERT dbo.Tmp_Message OFF
GO
ALTER TABLE dbo.Message
	DROP CONSTRAINT FK_Message_ParentMessage
GO
ALTER TABLE dbo.MessageContent
	DROP CONSTRAINT FK_MessageContent_Message
GO
DROP TABLE dbo.Message
GO
EXECUTE sp_rename N'dbo.Tmp_Message', N'Message', 'OBJECT' 
GO
ALTER TABLE dbo.Message ADD CONSTRAINT
	PK_Message PRIMARY KEY CLUSTERED 
	(
	Id
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
CREATE NONCLUSTERED INDEX IX_Message_ChatSpan ON dbo.Message
	(
	ChatId,
	SpanId
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX IX_Message_Usage ON dbo.Message
	(
	UsageId
	) WHERE ([UsageId] IS NOT NULL)
 WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE dbo.Message ADD CONSTRAINT
	FK_Message_UserModelUsage FOREIGN KEY
	(
	UsageId
	) REFERENCES dbo.UserModelUsage
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.Message ADD CONSTRAINT
	FK_Message_ChatRole FOREIGN KEY
	(
	ChatRoleId
	) REFERENCES dbo.ChatRole
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.Message ADD CONSTRAINT
	FK_Message_Chat FOREIGN KEY
	(
	ChatId
	) REFERENCES dbo.Chat
	(
	Id
	) ON UPDATE  CASCADE 
	 ON DELETE  CASCADE 
	
GO
ALTER TABLE dbo.Message ADD CONSTRAINT
	FK_Message_ParentMessage FOREIGN KEY
	(
	ParentId
	) REFERENCES dbo.Message
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.Message ADD CONSTRAINT
	FK_Message_ChatSpan FOREIGN KEY
	(
	ChatId,
	SpanId
	) REFERENCES dbo.ChatSpan
	(
	ChatId,
	SpanId
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.MessageContent ADD CONSTRAINT
	FK_MessageContent_Message FOREIGN KEY
	(
	MessageId
	) REFERENCES dbo.Message
	(
	Id
	) ON UPDATE  CASCADE 
	 ON DELETE  CASCADE 
	
GO
ALTER TABLE dbo.MessageContent SET (LOCK_ESCALATION = TABLE)
GO
COMMIT

update [Message] set [SpanId] = null where ChatRoleId = 2;