/*=========================================================
  MEKANISM MARKETING ANALYTICS
  GOLD CAMPAIGN DAILY PERFORMANCE TABLE
=========================================================*/

USE mekanism_marketing_analytics;
GO


/*=========================================================
  DROP TABLE IF IT ALREADY EXISTS
=========================================================*/

DROP TABLE IF EXISTS gold.campaign_daily_performance;
GO


/*=========================================================
  CREATE TABLE
=========================================================*/

CREATE TABLE gold.campaign_daily_performance
(
    performance_key BIGINT IDENTITY(1,1) NOT NULL,

    date_key        INT           NOT NULL,
    campaign_id     NVARCHAR(7)   NOT NULL,
    channel         NVARCHAR(50)  NOT NULL,
    country         NVARCHAR(50)  NOT NULL,
    city            NVARCHAR(100) NOT NULL,
    device          NVARCHAR(30)  NOT NULL,

    /* Media performance */

    impressions     BIGINT        NOT NULL
        CONSTRAINT DF_gold_campaign_daily_impressions
        DEFAULT 0,

    clicks          BIGINT        NOT NULL
        CONSTRAINT DF_gold_campaign_daily_clicks
        DEFAULT 0,

    spend           DECIMAL(18,2) NOT NULL
        CONSTRAINT DF_gold_campaign_daily_spend
        DEFAULT 0,

    video_views     BIGINT        NOT NULL
        CONSTRAINT DF_gold_campaign_daily_video_views
        DEFAULT 0,

    engagements     BIGINT        NOT NULL
        CONSTRAINT DF_gold_campaign_daily_engagements
        DEFAULT 0,

    /* Website performance */

    sessions        BIGINT        NOT NULL
        CONSTRAINT DF_gold_campaign_daily_sessions
        DEFAULT 0,

    bounce_rate     DECIMAL(9,6)  NULL,

    avg_session_seconds DECIMAL(12,2) NULL,

    /* Conversion performance */

    conversions     BIGINT        NOT NULL
        CONSTRAINT DF_gold_campaign_daily_conversions
        DEFAULT 0,

    revenue         DECIMAL(18,2) NOT NULL
        CONSTRAINT DF_gold_campaign_daily_revenue
        DEFAULT 0,

    /* Data lineage */

    load_timestamp  DATETIME2(0)  NOT NULL
        CONSTRAINT DF_gold_campaign_daily_load_timestamp
        DEFAULT SYSDATETIME(),

    /* Primary key */

    CONSTRAINT PK_gold_campaign_daily_performance
        PRIMARY KEY (performance_key),

    /* Prevent duplicate reporting-grain records */

    CONSTRAINT UQ_gold_campaign_daily_performance_grain
        UNIQUE
        (
            date_key,
            campaign_id,
            channel,
            country,
            city,
            device
        ),

    /* Date relationship */

    CONSTRAINT FK_gold_campaign_daily_date
        FOREIGN KEY (date_key)
        REFERENCES gold.dim_date(date_key),

    /* Validation rules */

    CONSTRAINT CK_gold_campaign_daily_impressions
        CHECK (impressions >= 0),

    CONSTRAINT CK_gold_campaign_daily_clicks
        CHECK (clicks >= 0),

    CONSTRAINT CK_gold_campaign_daily_spend
        CHECK (spend >= 0),

    CONSTRAINT CK_gold_campaign_daily_video_views
        CHECK (video_views >= 0),

    CONSTRAINT CK_gold_campaign_daily_engagements
        CHECK (engagements >= 0),

    CONSTRAINT CK_gold_campaign_daily_sessions
        CHECK (sessions >= 0),

    CONSTRAINT CK_gold_campaign_daily_conversions
        CHECK (conversions >= 0),

    CONSTRAINT CK_gold_campaign_daily_revenue
        CHECK (revenue >= 0),

    CONSTRAINT CK_gold_campaign_daily_click_relationship
        CHECK (clicks <= impressions),

    CONSTRAINT CK_gold_campaign_daily_bounce_rate
        CHECK
        (
            bounce_rate IS NULL
            OR bounce_rate BETWEEN 0 AND 1
        ),

    CONSTRAINT CK_gold_campaign_daily_session_duration
        CHECK
        (
            avg_session_seconds IS NULL
            OR avg_session_seconds >= 0
        )
);
GO


PRINT '#################################################';
PRINT 'TABLE gold.campaign_daily_performance IS CREATED';
PRINT '#################################################';
GO


/*=========================================================
  VERIFY TABLE STRUCTURE
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
  AND TABLE_NAME = 'campaign_daily_performance'
ORDER BY ORDINAL_POSITION;
GO

/*=========================================================
  MEKANISM MARKETING ANALYTICS

  POPULATE:
  gold.campaign_daily_performance
=========================================================*/

USE mekanism_marketing_analytics;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
    @start_time     DATETIME2 = SYSDATETIME(),
    @end_time       DATETIME2,
    @inserted_rows  INT;

PRINT '=================================================';
PRINT 'LOADING gold.campaign_daily_performance';
PRINT '=================================================';


/*=========================================================
  BEGIN LOAD
=========================================================*/

BEGIN TRY

    BEGIN TRANSACTION;


    /*=====================================================
      1. REMOVE PREVIOUS GOLD DATA

      This makes the script reloadable.
    =====================================================*/

    TRUNCATE TABLE gold.campaign_daily_performance;


    /*=====================================================
      2. AGGREGATE ALL SILVER FACT TABLES
    =====================================================*/

    ;WITH media_aggregated AS
    (
        SELECT
            [date] AS activity_date,

            campaign_id,

            COALESCE
            (
                NULLIF(TRIM(channel), ''),
                'Unknown'
            ) AS channel,

            COALESCE
            (
                NULLIF(TRIM(country), ''),
                'Unknown'
            ) AS country,

            COALESCE
            (
                NULLIF(TRIM(city), ''),
                'Unknown'
            ) AS city,

            COALESCE
            (
                NULLIF(TRIM(device), ''),
                'Unknown'
            ) AS device,

            SUM(CAST(impressions AS BIGINT))
                AS impressions,

            SUM(CAST(clicks AS BIGINT))
                AS clicks,

            SUM(CAST(spend AS DECIMAL(18,2)))
                AS spend,

            SUM(CAST(video_views AS BIGINT))
                AS video_views,

            SUM(CAST(engagements AS BIGINT))
                AS engagements

        FROM silver.fact_media_daily

        GROUP BY
            [date],
            campaign_id,

            COALESCE
            (
                NULLIF(TRIM(channel), ''),
                'Unknown'
            ),

            COALESCE
            (
                NULLIF(TRIM(country), ''),
                'Unknown'
            ),

            COALESCE
            (
                NULLIF(TRIM(city), ''),
                'Unknown'
            ),

            COALESCE
            (
                NULLIF(TRIM(device), ''),
                'Unknown'
            )
    ),


    /*=====================================================
      3. AGGREGATE WEBSITE DATA

      Bounce rate and session duration use weighted averages.

      Example:

      Weighted Bounce Rate
      =
      SUM(Bounce Rate × Sessions)
      ÷
      SUM(Sessions)
    =====================================================*/

    web_aggregated AS
    (
        SELECT
            [date] AS activity_date,

            campaign_id,

            COALESCE
            (
                NULLIF(TRIM(channel), ''),
                'Unknown'
            ) AS channel,

            COALESCE
            (
                NULLIF(TRIM(country), ''),
                'Unknown'
            ) AS country,

            COALESCE
            (
                NULLIF(TRIM(city), ''),
                'Unknown'
            ) AS city,

            COALESCE
            (
                NULLIF(TRIM(device), ''),
                'Unknown'
            ) AS device,

            SUM(CAST(sessions AS BIGINT))
                AS sessions,


            /* Weighted bounce rate */

            CAST
            (
                SUM
                (
                    CAST(bounce_rate AS DECIMAL(28,10))
                    *
                    CAST(sessions AS DECIMAL(28,10))
                )
                /
                NULLIF
                (
                    SUM
                    (
                        CAST(sessions AS DECIMAL(28,10))
                    ),
                    0
                )

                AS DECIMAL(9,6)
            ) AS bounce_rate,


            /* Weighted average session duration */

            CAST
            (
                SUM
                (
                    CAST(avg_session_seconds AS DECIMAL(28,10))
                    *
                    CAST(sessions AS DECIMAL(28,10))
                )
                /
                NULLIF
                (
                    SUM
                    (
                        CAST(sessions AS DECIMAL(28,10))
                    ),
                    0
                )

                AS DECIMAL(12,2)
            ) AS avg_session_seconds

        FROM silver.fact_web_daily

        GROUP BY
            [date],
            campaign_id,

            COALESCE
            (
                NULLIF(TRIM(channel), ''),
                'Unknown'
            ),

            COALESCE
            (
                NULLIF(TRIM(country), ''),
                'Unknown'
            ),

            COALESCE
            (
                NULLIF(TRIM(city), ''),
                'Unknown'
            ),

            COALESCE
            (
                NULLIF(TRIM(device), ''),
                'Unknown'
            )
    ),


    /*=====================================================
      4. AGGREGATE CONVERSION DATA

      Conversion type is not part of this Gold table's grain,
      so all conversion types are summarized together.
    =====================================================*/

    conversions_aggregated AS
    (
        SELECT
            [date] AS activity_date,

            campaign_id,

            COALESCE
            (
                NULLIF(TRIM(channel), ''),
                'Unknown'
            ) AS channel,

            COALESCE
            (
                NULLIF(TRIM(country), ''),
                'Unknown'
            ) AS country,

            COALESCE
            (
                NULLIF(TRIM(city), ''),
                'Unknown'
            ) AS city,

            COALESCE
            (
                NULLIF(TRIM(device), ''),
                'Unknown'
            ) AS device,

            SUM(CAST(conversions AS BIGINT))
                AS conversions,

            SUM(CAST(revenue AS DECIMAL(18,2)))
                AS revenue

        FROM silver.fact_conversions

        GROUP BY
            [date],
            campaign_id,

            COALESCE
            (
                NULLIF(TRIM(channel), ''),
                'Unknown'
            ),

            COALESCE
            (
                NULLIF(TRIM(country), ''),
                'Unknown'
            ),

            COALESCE
            (
                NULLIF(TRIM(city), ''),
                'Unknown'
            ),

            COALESCE
            (
                NULLIF(TRIM(device), ''),
                'Unknown'
            )
    ),


    /*=====================================================
      5. CREATE A MASTER LIST OF REPORTING KEYS

      UNION removes duplicate combinations.

      This keeps records even when activity exists in only
      one source, such as:

      - Media activity with no website sessions
      - Website activity with no matching media record
      - Conversions with no matching media record
    =====================================================*/

    all_reporting_keys AS
    (
        SELECT
            activity_date,
            campaign_id,
            channel,
            country,
            city,
            device
        FROM media_aggregated

        UNION

        SELECT
            activity_date,
            campaign_id,
            channel,
            country,
            city,
            device
        FROM web_aggregated

        UNION

        SELECT
            activity_date,
            campaign_id,
            channel,
            country,
            city,
            device
        FROM conversions_aggregated
    )


    /*=====================================================
      6. INSERT THE COMBINED RESULTS INTO GOLD
    =====================================================*/

    INSERT INTO gold.campaign_daily_performance
    (
        date_key,
        campaign_id,
        channel,
        country,
        city,
        device,

        impressions,
        clicks,
        spend,
        video_views,
        engagements,

        sessions,
        bounce_rate,
        avg_session_seconds,

        conversions,
        revenue
    )

    SELECT
        d.date_key,

        k.campaign_id,
        k.channel,
        k.country,
        k.city,
        k.device,


        /* Media measures */

        COALESCE(m.impressions, 0)
            AS impressions,

        COALESCE(m.clicks, 0)
            AS clicks,

        COALESCE(m.spend, 0)
            AS spend,

        COALESCE(m.video_views, 0)
            AS video_views,

        COALESCE(m.engagements, 0)
            AS engagements,


        /* Website measures */

        COALESCE(w.sessions, 0)
            AS sessions,

        w.bounce_rate,

        w.avg_session_seconds,


        /* Conversion measures */

        COALESCE(c.conversions, 0)
            AS conversions,

        COALESCE(c.revenue, 0)
            AS revenue

    FROM all_reporting_keys AS k


    /* Connect the reporting date to the Date dimension */

    LEFT JOIN gold.dim_date AS d
        ON d.calendar_date = k.activity_date


    /* Add aggregated media values */

    LEFT JOIN media_aggregated AS m
        ON  m.activity_date = k.activity_date
        AND m.campaign_id   = k.campaign_id
        AND m.channel       = k.channel
        AND m.country       = k.country
        AND m.city          = k.city
        AND m.device        = k.device


    /* Add aggregated website values */

    LEFT JOIN web_aggregated AS w
        ON  w.activity_date = k.activity_date
        AND w.campaign_id   = k.campaign_id
        AND w.channel       = k.channel
        AND w.country       = k.country
        AND w.city          = k.city
        AND w.device        = k.device


    /* Add aggregated conversion values */

    LEFT JOIN conversions_aggregated AS c
        ON  c.activity_date = k.activity_date
        AND c.campaign_id   = k.campaign_id
        AND c.channel       = k.channel
        AND c.country       = k.country
        AND c.city          = k.city
        AND c.device        = k.device;


    SET @inserted_rows = @@ROWCOUNT;

    COMMIT TRANSACTION;


    /*=====================================================
      7. SUCCESS MESSAGE
    =====================================================*/

    SET @end_time = SYSDATETIME();

    PRINT '=================================================';
    PRINT 'GOLD TABLE LOADED SUCCESSFULLY';

    PRINT 'ROWS INSERTED: '
        + CAST(@inserted_rows AS NVARCHAR(20));

    PRINT 'LOAD TIME: '
        + CAST
        (
            DATEDIFF
            (
                SECOND,
                @start_time,
                @end_time
            )
            AS NVARCHAR(20)
        )
        + ' seconds';

    PRINT '=================================================';

END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT '=================================================';
    PRINT 'ERROR LOADING GOLD TABLE';
    PRINT 'ERROR NUMBER: '
        + CAST(ERROR_NUMBER() AS NVARCHAR(20));

    PRINT 'ERROR MESSAGE: '
        + ERROR_MESSAGE();

    PRINT '=================================================';

    THROW;

END CATCH;
GO
