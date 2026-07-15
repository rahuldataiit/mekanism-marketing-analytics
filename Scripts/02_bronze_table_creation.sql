/*=========================================================
  MEKANISM MARKETING ANALYTICS
  BRONZE LAYER TABLE CREATION
=========================================================*/

USE mekanism_marketing_analytics;
GO


/*=========================================================
  DROP EXISTING BRONZE TABLES

  Tables are dropped in dependency-safe order.
=========================================================*/

DROP TABLE IF EXISTS bronze.campaign_targets;
DROP TABLE IF EXISTS bronze.fact_conversions_raw;
DROP TABLE IF EXISTS bronze.fact_web_daily_raw;
DROP TABLE IF EXISTS bronze.fact_media_daily_raw;
DROP TABLE IF EXISTS bronze.dim_creative;
DROP TABLE IF EXISTS bronze.dim_campaign;
GO

PRINT '------------------------------------------------';
PRINT 'EXISTING BRONZE TABLES ARE DROPPED';
PRINT '------------------------------------------------';
GO


/*=========================================================
  1. CREATE bronze.dim_campaign
=========================================================*/

CREATE TABLE bronze.dim_campaign
(
    campaign_id   NVARCHAR(7)   PRIMARY KEY,
    campaign_name NVARCHAR(100) NOT NULL,
    client_name   NVARCHAR(100) NOT NULL,
    objective     NVARCHAR(50)  NOT NULL,
    start_date    DATE          NULL,
    end_date      DATE          NULL,
    budget        DECIMAL(12,2) NULL,
    market        NVARCHAR(50)  NULL
);
GO

PRINT '------------------------------------------------';
PRINT 'TABLE bronze.dim_campaign IS CREATED';
PRINT '------------------------------------------------';
GO


/*=========================================================
  2. CREATE bronze.dim_creative
=========================================================*/

CREATE TABLE bronze.dim_creative
(
    creative_id   NVARCHAR(5)   PRIMARY KEY,
    campaign_id   NVARCHAR(7)   NOT NULL,
    channel       NVARCHAR(50)  NOT NULL,
    [format]      NVARCHAR(100) NOT NULL,
    creative_name NVARCHAR(150) NOT NULL,
    variant       NVARCHAR(10)  NOT NULL
);
GO

PRINT '------------------------------------------------';
PRINT 'TABLE bronze.dim_creative IS CREATED';
PRINT '------------------------------------------------';
GO


/*=========================================================
  3. CREATE bronze.fact_media_daily_raw
=========================================================*/

CREATE TABLE bronze.fact_media_daily_raw
(
    media_row_id  NVARCHAR(7)   PRIMARY KEY,
    [date]        DATE          NOT NULL,
    campaign_id   NVARCHAR(7)   NOT NULL,
    creative_id   NVARCHAR(5)   NULL,
    channel_raw   NVARCHAR(50)  NULL,
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
    source_system NVARCHAR(100) NULL
);
GO

PRINT '------------------------------------------------';
PRINT 'TABLE bronze.fact_media_daily_raw IS CREATED';
PRINT '------------------------------------------------';
GO


/*=========================================================
  4. CREATE bronze.fact_web_daily_raw
=========================================================*/

CREATE TABLE bronze.fact_web_daily_raw
(
    web_row_id          NVARCHAR(7)   PRIMARY KEY,
    [date]              DATE          NOT NULL,
    campaign_id         NVARCHAR(7)   NOT NULL,
    channel_raw         NVARCHAR(50)  NULL,
    country             NVARCHAR(50)  NULL,
    city                NVARCHAR(100) NULL,
    device              NVARCHAR(30)  NULL,
    sessions            INT           NULL,
    bounce_rate         DECIMAL(7,4)  NULL,
    avg_session_seconds DECIMAL(8,1)  NULL,
    utm_source          NVARCHAR(100) NULL,
    utm_medium          NVARCHAR(100) NULL,
    utm_campaign        NVARCHAR(150) NULL,
    source_system       NVARCHAR(100) NULL
);
GO

PRINT '------------------------------------------------';
PRINT 'TABLE bronze.fact_web_daily_raw IS CREATED';
PRINT '------------------------------------------------';
GO


/*=========================================================
  5. CREATE bronze.fact_conversions_raw
=========================================================*/

CREATE TABLE bronze.fact_conversions_raw
(
    conversion_row_id NVARCHAR(7)   PRIMARY KEY,
    [date]            DATE          NOT NULL,
    campaign_id       NVARCHAR(7)   NOT NULL,
    channel_raw       NVARCHAR(50)  NULL,
    country           NVARCHAR(50)  NULL,
    city              NVARCHAR(100) NULL,
    device            NVARCHAR(30)  NULL,
    conversion_type   NVARCHAR(30)  NULL,
    conversions       INT           NULL,
    revenue           DECIMAL(14,2) NULL,
    source_system     NVARCHAR(100) NULL
);
GO

PRINT '------------------------------------------------';
PRINT 'TABLE bronze.fact_conversions_raw IS CREATED';
PRINT '------------------------------------------------';
GO


/*=========================================================
  6. CREATE bronze.campaign_targets
=========================================================*/

CREATE TABLE bronze.campaign_targets
(
    campaign_id         NVARCHAR(7)   PRIMARY KEY,
    target_ctr          DECIMAL(9,6)  NULL,
    target_cpc          DECIMAL(12,2) NULL,
    target_cvr          DECIMAL(9,6)  NULL,
    target_cpa          DECIMAL(12,2) NULL,
    target_qa_pass_rate DECIMAL(9,6)  NULL
);
GO

PRINT '------------------------------------------------';
PRINT 'TABLE bronze.campaign_targets IS CREATED';
PRINT '------------------------------------------------';
GO


/*=========================================================
  VERIFY BRONZE TABLES
=========================================================*/

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'bronze'
ORDER BY TABLE_NAME;
GO

PRINT '================================================';
PRINT 'ALL BRONZE TABLES WERE CREATED SUCCESSFULLY';
PRINT '================================================';
GO
