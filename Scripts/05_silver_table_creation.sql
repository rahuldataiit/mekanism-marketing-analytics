/*=========================================================
  MEKANISM MARKETING ANALYTICS
  SILVER LAYER TABLE CREATION
=========================================================*/

USE mekanism_marketing_analytics;
GO


/*=========================================================
  DROP EXISTING SILVER TABLES
  Drop fact and target tables before dimensions.
=========================================================*/

DROP TABLE IF EXISTS silver.campaign_targets;
DROP TABLE IF EXISTS silver.fact_conversions;
DROP TABLE IF EXISTS silver.fact_web_daily;
DROP TABLE IF EXISTS silver.fact_media_daily;
DROP TABLE IF EXISTS silver.dim_creative;
DROP TABLE IF EXISTS silver.dim_campaign;
GO

PRINT '------------------------------------------------';
PRINT 'EXISTING SILVER TABLES ARE DROPPED';
PRINT '------------------------------------------------';
GO


/*=========================================================
  1. CREATE silver.dim_campaign
=========================================================*/

CREATE TABLE silver.dim_campaign
(
    campaign_id   NVARCHAR(7)   PRIMARY KEY,
    campaign_name NVARCHAR(100) NOT NULL,
    client_name   NVARCHAR(100) NOT NULL,
    objective     NVARCHAR(50)  NOT NULL,
    start_date    DATE          NULL,
    end_date      DATE          NULL,
    budget        DECIMAL(12,2) NULL,
    market        NVARCHAR(50)  NULL,
    load_timestamp DATETIME2(0) NOT NULL
        CONSTRAINT DF_silver_dim_campaign_load_timestamp
        DEFAULT SYSDATETIME()
);
GO

PRINT 'TABLE silver.dim_campaign IS CREATED';
GO


/*=========================================================
  2. CREATE silver.dim_creative
=========================================================*/

CREATE TABLE silver.dim_creative
(
    creative_id   NVARCHAR(5)   PRIMARY KEY,
    campaign_id   NVARCHAR(7)   NOT NULL,
    channel       NVARCHAR(50)  NOT NULL,
    [format]      NVARCHAR(100) NOT NULL,
    creative_name NVARCHAR(150) NOT NULL,
    variant       NVARCHAR(10)  NOT NULL,
    load_timestamp DATETIME2(0) NOT NULL
        CONSTRAINT DF_silver_dim_creative_load_timestamp
        DEFAULT SYSDATETIME()
);
GO

PRINT 'TABLE silver.dim_creative IS CREATED';
GO


/*=========================================================
  3. CREATE silver.fact_media_daily
=========================================================*/

CREATE TABLE silver.fact_media_daily
(
    media_row_id  NVARCHAR(7)   PRIMARY KEY,
    [date]        DATE          NOT NULL,
    campaign_id   NVARCHAR(7)   NOT NULL,
    creative_id   NVARCHAR(5)   NOT NULL,
    channel       NVARCHAR(50)  NOT NULL,
    country       NVARCHAR(50)  NULL,
    city          NVARCHAR(100) NULL,
    device        NVARCHAR(30)  NULL,
    impressions   INT           NULL,
    clicks        INT           NULL,
    spend         DECIMAL(12,2) NULL,
    video_views   INT           NULL,
    engagements   INT           NULL,
    utm_source    NVARCHAR(100) NULL,
    utm_medium    NVARCHAR(100) NULL,
    utm_campaign  NVARCHAR(150) NULL,
    source_system NVARCHAR(100) NULL,
    load_timestamp DATETIME2(0) NOT NULL
        CONSTRAINT DF_silver_fact_media_load_timestamp
        DEFAULT SYSDATETIME()
);
GO

PRINT 'TABLE silver.fact_media_daily IS CREATED';
GO


/*=========================================================
  4. CREATE silver.fact_web_daily
=========================================================*/

CREATE TABLE silver.fact_web_daily
(
    web_key              BIGINT IDENTITY(1,1) PRIMARY KEY,
    [date]               DATE          NOT NULL,
    campaign_id          NVARCHAR(7)   NOT NULL,
    channel              NVARCHAR(50)  NOT NULL,
    country              NVARCHAR(50)  NULL,
    city                 NVARCHAR(100) NULL,
    device               NVARCHAR(30)  NULL,
    sessions             INT           NULL,
    bounce_rate          DECIMAL(7,4)  NULL,
    avg_session_seconds  DECIMAL(8,1)  NULL,
    utm_source           NVARCHAR(100) NULL,
    utm_medium           NVARCHAR(100) NULL,
    utm_campaign         NVARCHAR(150) NULL,
    source_system        NVARCHAR(100) NULL,
    load_timestamp       DATETIME2(0)  NOT NULL
        CONSTRAINT DF_silver_fact_web_load_timestamp
        DEFAULT SYSDATETIME()
);
GO

PRINT 'TABLE silver.fact_web_daily IS CREATED';
GO


/*=========================================================
  5. CREATE silver.fact_conversions
=========================================================*/

CREATE TABLE silver.fact_conversions
(
    conversion_key     BIGINT IDENTITY(1,1) PRIMARY KEY,
    [date]             DATE          NOT NULL,
    campaign_id        NVARCHAR(7)   NOT NULL,
    channel            NVARCHAR(50)  NOT NULL,
    country            NVARCHAR(50)  NULL,
    city               NVARCHAR(100) NULL,
    device             NVARCHAR(30)  NULL,
    conversion_type    NVARCHAR(30)  NULL,
    conversions        INT           NULL,
    revenue            DECIMAL(14,2) NULL,
    source_system      NVARCHAR(100) NULL,
    load_timestamp     DATETIME2(0)  NOT NULL
        CONSTRAINT DF_silver_fact_conversions_load_timestamp
        DEFAULT SYSDATETIME()
);
GO

PRINT 'TABLE silver.fact_conversions IS CREATED';
GO


/*=========================================================
  6. CREATE silver.campaign_targets
=========================================================*/

CREATE TABLE silver.campaign_targets
(
    campaign_id         NVARCHAR(7)   PRIMARY KEY,
    target_ctr          DECIMAL(9,6)  NULL,
    target_cpc          DECIMAL(12,2) NULL,
    target_cvr          DECIMAL(9,6)  NULL,
    target_cpa          DECIMAL(12,2) NULL,
    target_qa_pass_rate DECIMAL(9,6)  NULL,
    load_timestamp      DATETIME2(0)  NOT NULL
        CONSTRAINT DF_silver_campaign_targets_load_timestamp
        DEFAULT SYSDATETIME()
);
GO

PRINT 'TABLE silver.campaign_targets IS CREATED';
GO


/*=========================================================
  VERIFY SILVER TABLES
=========================================================*/

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'silver'
ORDER BY TABLE_NAME;
GO

PRINT '================================================';
PRINT 'ALL SILVER TABLES WERE CREATED SUCCESSFULLY';
PRINT '================================================';
GO
