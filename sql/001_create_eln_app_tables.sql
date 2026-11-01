/*
  Клиника · ЭЛН — служебные таблицы приложения.
  Выполнять в целевой базе Медиалог только после согласования с DBA.
  Скрипт создаёт только dbo.ELN_AppData и dbo.ELN_AuditLog.
  Ни одна существующая таблица Медиалог не изменяется.
*/

IF OBJECT_ID(N'dbo.ELN_AppData', N'U') IS NULL
BEGIN
  CREATE TABLE dbo.ELN_AppData (
    RecordType NVARCHAR(16) NOT NULL,
    RecordId NVARCHAR(100) NOT NULL,
    PayloadJson NVARCHAR(MAX) NOT NULL,
    LocalStatus NVARCHAR(60) NOT NULL,
    CreatedAtUtc DATETIME2(3) NOT NULL
      CONSTRAINT DF_ELN_AppData_CreatedAtUtc DEFAULT SYSUTCDATETIME(),
    UpdatedAtUtc DATETIME2(3) NOT NULL
      CONSTRAINT DF_ELN_AppData_UpdatedAtUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_ELN_AppData PRIMARY KEY (RecordType, RecordId)
  );
END;

IF OBJECT_ID(N'dbo.ELN_AuditLog', N'U') IS NULL
BEGIN
  CREATE TABLE dbo.ELN_AuditLog (
    AuditId BIGINT IDENTITY(1,1) NOT NULL
      CONSTRAINT PK_ELN_AuditLog PRIMARY KEY,
    CreatedAtUtc DATETIME2(3) NOT NULL
      CONSTRAINT DF_ELN_AuditLog_CreatedAtUtc DEFAULT SYSUTCDATETIME(),
    Module NVARCHAR(24) NOT NULL,
    ActionName NVARCHAR(120) NOT NULL,
    Outcome NVARCHAR(60) NOT NULL,
    Details NVARCHAR(2000) NOT NULL
  );
END;
