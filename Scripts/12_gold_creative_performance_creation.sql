/*=========================================================
  MEKANISM MARKETING ANALYTICS

  CREATE TABLE:
  gold.creative_performance

  GRAIN:
  One row per
  Date + Campaign + Creative + Channel
  + Country + City + Device
=========================================================*/

USE mekanism_marketing_analytics;
GO

SET NOCOUNT ON;
GO


/*=========================================================
  1. DROP TABLE IF IT ALREADY EXISTS
=========================================================*/

DROP TABLE IF EXISTS gold.creative_performance;
GO


/*=========================================================
  2. CREATE CREATIVE PERFORMANCE TABLE
=========================================================*/

CREATE TABLE gold.creative_performance
(
    /* Technical key */

    creative_performance_key BIGINT IDENTITY(1,1) NOT NULL,


    /* Date information */

    date_key                 INT           NOT NULL,


    /* Campaign and creative information */

    campaign_id              NVARCHAR(7)   NOT NULL,
    creative_id              NVARCHAR(5)   NOT NULL,

    creative_name            NVARCHAR(150) NOT NULL,
    channel                  NVARCHAR(50)  NOT NULL,
    [format]                 NVARCHAR(100) NOT NULL,
    variant                  NVARCHAR(10)  NOT NULL,


    /* Geography and device */

    country                  NVARCHAR(50)  NOT NULL,
    city                     NVARCHAR(100) NOT NULL,
    device                   NVARCHAR(30)  NOT NULL,


    /* Base media measures */

    impressions              BIGINT        NOT NULL
        CONSTRAINT DF_gold_creative_impressions
        DEFAULT 0,

    clicks                   BIGINT        NOT NULL
        CONSTRAINT DF_gold_creative_clicks
        DEFAULT 0,

    spend                    DECIMAL(18,2) NOT NULL
        CONSTRAINT DF_gold_creative_spend
        DEFAULT 0,

    video_views              BIGINT        NOT NULL
        CONSTRAINT DF_gold_creative_video_views
        DEFAULT 0,

    engagements              BIGINT        NOT NULL
        CONSTRAINT DF_gold_creative_engagements
        DEFAULT 0,


    /* Calculated creative KPIs */

    actual_ctr               DECIMAL(18,6) NULL,

    actual_cpc               DECIMAL(18,4) NULL,

    actual_cpm               DECIMAL(18,4) NULL,

    engagement_rate          DECIMAL(18,6) NULL,

    video_view_rate          DECIMAL(18,6) NULL,


    /* Data lineage */

    load_timestamp           DATETIME2(0) NOT NULL
        CONSTRAINT DF_gold_creative_load_timestamp
        DEFAULT SYSDATETIME(),


    /*=====================================================
      PRIMARY KEY
    =====================================================*/

    CONSTRAINT PK_gold_creative_performance
        PRIMARY KEY (creative_performance_key),


    /*=====================================================
      PREVENT DUPLICATE RECORDS AT THE DEFINED GRAIN
    =====================================================*/

    CONSTRAINT UQ_gold_creative_performance_grain
        UNIQUE
        (
            date_key,
            campaign_id,
            creative_id,
            channel,
            country,
            city,
            device
        ),


    /*=====================================================
      DATE DIMENSION RELATIONSHIP
    =====================================================*/

    CONSTRAINT FK_gold_creative_performance_date
        FOREIGN KEY (date_key)
        REFERENCES gold.dim_date(date_key),


    /*=====================================================
      DATA-QUALITY CHECKS
    =====================================================*/

    CONSTRAINT CK_gold_creative_impressions
        CHECK (impressions >= 0),

    CONSTRAINT CK_gold_creative_clicks
        CHECK (clicks >= 0),

    CONSTRAINT CK_gold_creative_spend
        CHECK (spend >= 0),

    CONSTRAINT CK_gold_creative_video_views
        CHECK (video_views >= 0),

    CONSTRAINT CK_gold_creative_engagements
        CHECK (engagements >= 0),


    /* Clicks should not exceed impressions */

    CONSTRAINT CK_gold_creative_clicks_impressions
        CHECK (clicks <= impressions),


    /* CTR must be between 0% and 100% */

    CONSTRAINT CK_gold_creative_ctr
        CHECK
        (
            actual_ctr IS NULL
            OR actual_ctr BETWEEN 0 AND 1
        ),


    /* Cost-based KPIs cannot be negative */

    CONSTRAINT CK_gold_creative_cpc
        CHECK
        (
            actual_cpc IS NULL
            OR actual_cpc >= 0
        ),

    CONSTRAINT CK_gold_creative_cpm
        CHECK
        (
            actual_cpm IS NULL
            OR actual_cpm >= 0
        ),


    /* Engagement and video rates cannot be negative */

    CONSTRAINT CK_gold_creative_engagement_rate
        CHECK
        (
            engagement_rate IS NULL
            OR engagement_rate >= 0
        ),

    CONSTRAINT CK_gold_creative_video_view_rate
        CHECK
        (
            video_view_rate IS NULL
            OR video_view_rate >= 0
        )
);
GO


/*=========================================================
  3. CREATE SUPPORTING INDEX

  Helps when filtering reports by creative and date.
=========================================================*/

CREATE INDEX IX_gold_creative_performance_creative_date
ON gold.creative_performance
(
    creative_id,
    date_key
);
GO


/*=========================================================
  4. SUCCESS MESSAGE
=========================================================*/

PRINT '=================================================';
PRINT 'TABLE gold.creative_performance CREATED';
PRINT 'GRAIN: DATE + CAMPAIGN + CREATIVE + CHANNEL';
PRINT '       + COUNTRY + CITY + DEVICE';
PRINT '=================================================';
GO


/*=========================================================
  5. VERIFY TABLE STRUCTURE
=========================================================*/

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold'
  AND TABLE_NAME = 'creative_performance'
ORDER BY ORDINAL_POSITION;
GO
