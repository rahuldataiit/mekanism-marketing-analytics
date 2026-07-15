/*=========================================================
  MEKANISM MARKETING ANALYTICS
  DATABASE AND SCHEMA SETUP
=========================================================*/

USE master;
GO


/*=========================================================
  CREATE DATABASE
=========================================================*/

IF DB_ID(N'mekanism_marketing_analytics') IS NULL
BEGIN
    CREATE DATABASE mekanism_marketing_analytics;

    PRINT '------------------------------------------------';
    PRINT 'DATABASE mekanism_marketing_analytics IS CREATED';
    PRINT '------------------------------------------------';
END
ELSE
BEGIN
    PRINT '-----------------------------------------------------';
    PRINT 'DATABASE mekanism_marketing_analytics ALREADY EXISTS';
    PRINT '-----------------------------------------------------';
END;
GO


/*=========================================================
  SWITCH TO PROJECT DATABASE
=========================================================*/

USE mekanism_marketing_analytics;
GO

PRINT '------------------------------------------------';
PRINT 'USING DATABASE mekanism_marketing_analytics';
PRINT '------------------------------------------------';
GO


/*=========================================================
  CREATE BRONZE SCHEMA
=========================================================*/

IF SCHEMA_ID(N'bronze') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA bronze AUTHORIZATION dbo;');

    PRINT '--------------------------------';
    PRINT 'SCHEMA bronze IS CREATED';
    PRINT '--------------------------------';
END
ELSE
BEGIN
    PRINT '--------------------------------';
    PRINT 'SCHEMA bronze ALREADY EXISTS';
    PRINT '--------------------------------';
END;
GO


/*=========================================================
  CREATE SILVER SCHEMA
=========================================================*/

IF SCHEMA_ID(N'silver') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA silver AUTHORIZATION dbo;');

    PRINT '--------------------------------';
    PRINT 'SCHEMA silver IS CREATED';
    PRINT '--------------------------------';
END
ELSE
BEGIN
    PRINT '--------------------------------';
    PRINT 'SCHEMA silver ALREADY EXISTS';
    PRINT '--------------------------------';
END;
GO


/*=========================================================
  CREATE GOLD SCHEMA
=========================================================*/

IF SCHEMA_ID(N'gold') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA gold AUTHORIZATION dbo;');

    PRINT '--------------------------------';
    PRINT 'SCHEMA gold IS CREATED';
    PRINT '--------------------------------';
END
ELSE
BEGIN
    PRINT '--------------------------------';
    PRINT 'SCHEMA gold ALREADY EXISTS';
    PRINT '--------------------------------';
END;
GO


/*=========================================================
  VERIFY DATABASE SCHEMAS
=========================================================*/

SELECT
    name AS schema_name
FROM sys.schemas
WHERE name IN ('bronze', 'silver', 'gold')
ORDER BY name;
GO

PRINT '================================================';
PRINT 'DATABASE AND SCHEMA SETUP COMPLETED SUCCESSFULLY';
PRINT '================================================';
GO
