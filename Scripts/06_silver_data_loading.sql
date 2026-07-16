/*=========================================================
  MEKANISM MARKETING ANALYTICS
  SILVER LAYER DATA CLEANING AND LOADING

  Main transformations:
  - Trim text values
  - Convert blank text to NULL
  - Standardize channel names
  - Standardize selected categories
  - Deduplicate by the correct business grain
  - Exclude invalid metric relationships
  - Validate campaign and creative relationships
  - Aggregate web and conversion data
=========================================================*/

USE mekanism_marketing_analytics;
GO

DECLARE
    @start_time DATETIME2,
    @end_time   DATETIME2,
    @row_count  INT;


/*=========================================================
  SILVER LAYER START
=========================================================*/

PRINT '#################################################';
PRINT 'LOADING SILVER LAYER';
PRINT '#################################################';
PRINT '';


/*=========================================================
  1. LOAD silver.dim_campaign
=========================================================*/

SET @start_time = GETDATE();

PRINT '------------------------------------------------';
PRINT 'LOADING DATA INTO silver.dim_campaign';
PRINT '------------------------------------------------';

BEGIN TRY

    TRUNCATE TABLE silver.dim_campaign;

    ;WITH cleaned_campaign AS
    (
        SELECT
            TRIM(campaign_id) AS campaign_id,
            TRIM(campaign_name) AS campaign_name,
            TRIM(client_name) AS client_name,

            CASE LOWER(TRIM(objective))
                WHEN 'awareness'     THEN 'Awareness'
                WHEN 'consideration' THEN 'Consideration'
                WHEN 'acquisition'   THEN 'Acquisition'
                WHEN 'engagement'    THEN 'Engagement'
                ELSE TRIM(objective)
            END AS objective,

            start_date,
            end_date,

            CASE
                WHEN budget >= 0 THEN budget
                ELSE NULL
            END AS budget,

            CASE LOWER(TRIM(market))
                WHEN 'us'     THEN 'US'
                WHEN 'usa'    THEN 'US'
                WHEN 'canada' THEN 'Canada'
                WHEN 'ca'     THEN 'Canada'
                ELSE NULLIF(TRIM(market), '')
            END AS market,

            ROW_NUMBER() OVER
            (
                PARTITION BY TRIM(campaign_id)
                ORDER BY start_date DESC, end_date DESC
            ) AS row_num
        FROM bronze.dim_campaign
        WHERE NULLIF(TRIM(campaign_id), '') IS NOT NULL
          AND NULLIF(TRIM(campaign_name), '') IS NOT NULL
          AND NULLIF(TRIM(client_name), '') IS NOT NULL
          AND NULLIF(TRIM(objective), '') IS NOT NULL
    )
    INSERT INTO silver.dim_campaign
    (
        campaign_id,
        campaign_name,
        client_name,
        objective,
        start_date,
        end_date,
        budget,
        market
    )
    SELECT
        campaign_id,
        campaign_name,
        client_name,
        objective,
        start_date,
        end_date,
        budget,
        market
    FROM cleaned_campaign
    WHERE row_num = 1
      AND (start_date IS NULL OR end_date IS NULL OR end_date >= start_date);

    SET @end_time = GETDATE();

    SELECT @row_count = COUNT(*)
    FROM silver.dim_campaign;

    PRINT 'DATA LOADED INTO silver.dim_campaign SUCCESSFULLY';
    PRINT 'LOADING TIME: '
        + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
        + ' seconds';
    PRINT 'TOTAL ROWS LOADED: '
        + CAST(@row_count AS NVARCHAR(20));

END TRY
BEGIN CATCH

    PRINT 'ERROR LOADING silver.dim_campaign';
    PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();

END CATCH;

PRINT '';


/*=========================================================
  2. LOAD silver.dim_creative
=========================================================*/

SET @start_time = GETDATE();

PRINT '------------------------------------------------';
PRINT 'LOADING DATA INTO silver.dim_creative';
PRINT '------------------------------------------------';

BEGIN TRY

    TRUNCATE TABLE silver.dim_creative;

    ;WITH cleaned_creative AS
    (
        SELECT
            TRIM(cr.creative_id) AS creative_id,
            TRIM(cr.campaign_id) AS campaign_id,

            CASE LOWER(TRIM(cr.channel))
                WHEN 'ppc'                  THEN 'Paid Search'
                WHEN 'paid search'          THEN 'Paid Search'
                WHEN 'paid social'          THEN 'Paid Social'
                WHEN 'display'              THEN 'Programmatic Display'
                WHEN 'programmatic display' THEN 'Programmatic Display'
                WHEN 'youtube'              THEN 'Online Video'
                WHEN 'online video'         THEN 'Online Video'
                WHEN 'organic-social'       THEN 'Organic Social'
                WHEN 'organic social'       THEN 'Organic Social'
                ELSE TRIM(cr.channel)
            END AS channel,

            TRIM(cr.[format]) AS [format],
            TRIM(cr.creative_name) AS creative_name,
            UPPER(TRIM(cr.variant)) AS variant,

            ROW_NUMBER() OVER
            (
                PARTITION BY TRIM(cr.creative_id)
                ORDER BY TRIM(cr.campaign_id), TRIM(cr.creative_name)
            ) AS row_num
        FROM bronze.dim_creative AS cr
        INNER JOIN silver.dim_campaign AS ca
            ON TRIM(cr.campaign_id) = ca.campaign_id
        WHERE NULLIF(TRIM(cr.creative_id), '') IS NOT NULL
          AND NULLIF(TRIM(cr.campaign_id), '') IS NOT NULL
          AND NULLIF(TRIM(cr.channel), '') IS NOT NULL
          AND NULLIF(TRIM(cr.[format]), '') IS NOT NULL
          AND NULLIF(TRIM(cr.creative_name), '') IS NOT NULL
          AND NULLIF(TRIM(cr.variant), '') IS NOT NULL
    )
    INSERT INTO silver.dim_creative
    (
        creative_id,
        campaign_id,
        channel,
        [format],
        creative_name,
        variant
    )
    SELECT
        creative_id,
        campaign_id,
        channel,
        [format],
        creative_name,
        variant
    FROM cleaned_creative
    WHERE row_num = 1;

    SET @end_time = GETDATE();

    SELECT @row_count = COUNT(*)
    FROM silver.dim_creative;

    PRINT 'DATA LOADED INTO silver.dim_creative SUCCESSFULLY';
    PRINT 'LOADING TIME: '
        + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
        + ' seconds';
    PRINT 'TOTAL ROWS LOADED: '
        + CAST(@row_count AS NVARCHAR(20));

END TRY
BEGIN CATCH

    PRINT 'ERROR LOADING silver.dim_creative';
    PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();

END CATCH;

PRINT '';


/*=========================================================
  3. LOAD silver.fact_media_daily
=========================================================*/

SET @start_time = GETDATE();

PRINT '------------------------------------------------';
PRINT 'LOADING DATA INTO silver.fact_media_daily';
PRINT '------------------------------------------------';

BEGIN TRY

    TRUNCATE TABLE silver.fact_media_daily;

    ;WITH cleaned_media AS
    (
        SELECT
            TRIM(m.media_row_id) AS media_row_id,
            m.[date],
            TRIM(m.campaign_id) AS campaign_id,
            TRIM(m.creative_id) AS creative_id,

            CASE LOWER(TRIM(m.channel_raw))
                WHEN 'ppc'                  THEN 'Paid Search'
                WHEN 'paid search'          THEN 'Paid Search'
                WHEN 'paid social'          THEN 'Paid Social'
                WHEN 'display'              THEN 'Programmatic Display'
                WHEN 'programmatic display' THEN 'Programmatic Display'
                WHEN 'youtube'              THEN 'Online Video'
                WHEN 'online video'         THEN 'Online Video'
                WHEN 'organic-social'       THEN 'Organic Social'
                WHEN 'organic social'       THEN 'Organic Social'
                ELSE TRIM(m.channel_raw)
            END AS channel,

            NULLIF(TRIM(m.country), '') AS country,
            NULLIF(TRIM(m.city), '') AS city,
            NULLIF(TRIM(m.device), '') AS device,
            m.impressions,
            m.clicks,
            m.spend,
            m.video_views,
            m.engagements,
            NULLIF(TRIM(m.utm_source), '') AS utm_source,
            NULLIF(TRIM(m.utm_medium), '') AS utm_medium,
            NULLIF(TRIM(m.utm_campaign), '') AS utm_campaign,
            NULLIF(TRIM(m.source_system), '') AS source_system
        FROM bronze.fact_media_daily_raw AS m
        WHERE NULLIF(TRIM(m.media_row_id), '') IS NOT NULL
          AND m.[date] IS NOT NULL
          AND NULLIF(TRIM(m.campaign_id), '') IS NOT NULL
          AND NULLIF(TRIM(m.creative_id), '') IS NOT NULL
    ),
    validated_media AS
    (
        SELECT
            m.*
        FROM cleaned_media AS m
        INNER JOIN silver.dim_campaign AS ca
            ON m.campaign_id = ca.campaign_id
        INNER JOIN silver.dim_creative AS cr
            ON m.creative_id = cr.creative_id
           AND m.campaign_id = cr.campaign_id
        WHERE (m.impressions IS NULL OR m.impressions >= 0)
          AND (m.clicks IS NULL OR m.clicks >= 0)
          AND (m.spend IS NULL OR m.spend >= 0)
          AND (m.video_views IS NULL OR m.video_views >= 0)
          AND (m.engagements IS NULL OR m.engagements >= 0)
          AND
          (
              m.clicks IS NULL
              OR m.impressions IS NULL
              OR m.clicks <= m.impressions
          )
          AND (ca.start_date IS NULL OR m.[date] >= ca.start_date)
          AND (ca.end_date IS NULL OR m.[date] <= ca.end_date)
    ),
    ranked_media AS
    (
        SELECT
            *,
            ROW_NUMBER() OVER
            (
                PARTITION BY
                    [date],
                    campaign_id,
                    creative_id,
                    channel,
                    country,
                    city,
                    device
                ORDER BY
                    CASE
                        WHEN utm_source IS NOT NULL
                         AND utm_medium IS NOT NULL
                        THEN 0
                        ELSE 1
                    END,
                    media_row_id
            ) AS row_num
        FROM validated_media
    )
    INSERT INTO silver.fact_media_daily
    (
        media_row_id,
        [date],
        campaign_id,
        creative_id,
        channel,
        country,
        city,
        device,
        impressions,
        clicks,
        spend,
        video_views,
        engagements,
        utm_source,
        utm_medium,
        utm_campaign,
        source_system
    )
    SELECT
        media_row_id,
        [date],
        campaign_id,
        creative_id,
        channel,
        country,
        city,
        device,
        impressions,
        clicks,
        spend,
        video_views,
        engagements,
        utm_source,
        utm_medium,
        utm_campaign,
        source_system
    FROM ranked_media
    WHERE row_num = 1;

    SET @end_time = GETDATE();

    SELECT @row_count = COUNT(*)
    FROM silver.fact_media_daily;

    PRINT 'DATA LOADED INTO silver.fact_media_daily SUCCESSFULLY';
    PRINT 'LOADING TIME: '
        + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
        + ' seconds';
    PRINT 'TOTAL ROWS LOADED: '
        + CAST(@row_count AS NVARCHAR(20));

END TRY
BEGIN CATCH

    PRINT 'ERROR LOADING silver.fact_media_daily';
    PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();

END CATCH;

PRINT '';


/*=========================================================
  4. LOAD silver.fact_web_daily

  Web data is aggregated to:
  date + campaign + channel + country + city + device.

  Bounce rate and average session duration are weighted
  by sessions when session values are available.
=========================================================*/

SET @start_time = GETDATE();

PRINT '------------------------------------------------';
PRINT 'LOADING DATA INTO silver.fact_web_daily';
PRINT '------------------------------------------------';

BEGIN TRY

    TRUNCATE TABLE silver.fact_web_daily;

    ;WITH cleaned_web AS
    (
        SELECT
            w.[date],
            TRIM(w.campaign_id) AS campaign_id,

            CASE LOWER(TRIM(w.channel_raw))
                WHEN 'ppc'                  THEN 'Paid Search'
                WHEN 'paid search'          THEN 'Paid Search'
                WHEN 'paid social'          THEN 'Paid Social'
                WHEN 'display'              THEN 'Programmatic Display'
                WHEN 'programmatic display' THEN 'Programmatic Display'
                WHEN 'youtube'              THEN 'Online Video'
                WHEN 'online video'         THEN 'Online Video'
                WHEN 'organic-social'       THEN 'Organic Social'
                WHEN 'organic social'       THEN 'Organic Social'
                ELSE TRIM(w.channel_raw)
            END AS channel,

            NULLIF(TRIM(w.country), '') AS country,
            NULLIF(TRIM(w.city), '') AS city,
            NULLIF(TRIM(w.device), '') AS device,
            w.sessions,
            w.bounce_rate,
            w.avg_session_seconds,
            NULLIF(TRIM(w.utm_source), '') AS utm_source,
            NULLIF(TRIM(w.utm_medium), '') AS utm_medium,
            NULLIF(TRIM(w.utm_campaign), '') AS utm_campaign,
            NULLIF(TRIM(w.source_system), '') AS source_system
        FROM bronze.fact_web_daily_raw AS w
        WHERE w.[date] IS NOT NULL
          AND NULLIF(TRIM(w.campaign_id), '') IS NOT NULL
          AND (w.sessions IS NULL OR w.sessions >= 0)
          AND (w.bounce_rate IS NULL OR w.bounce_rate BETWEEN 0 AND 1)
          AND
          (
              w.avg_session_seconds IS NULL
              OR w.avg_session_seconds >= 0
          )
    ),
    validated_web AS
    (
        SELECT
            w.*
        FROM cleaned_web AS w
        INNER JOIN silver.dim_campaign AS ca
            ON w.campaign_id = ca.campaign_id
        WHERE (ca.start_date IS NULL OR w.[date] >= ca.start_date)
          AND (ca.end_date IS NULL OR w.[date] <= ca.end_date)
    )
    INSERT INTO silver.fact_web_daily
    (
        [date],
        campaign_id,
        channel,
        country,
        city,
        device,
        sessions,
        bounce_rate,
        avg_session_seconds,
        utm_source,
        utm_medium,
        utm_campaign,
        source_system
    )
    SELECT
        [date],
        campaign_id,
        channel,
        country,
        city,
        device,

        SUM(sessions) AS sessions,

        CAST
        (
            COALESCE
            (
                SUM
                (
                    CASE
                        WHEN sessions > 0 AND bounce_rate IS NOT NULL
                        THEN CAST(bounce_rate AS DECIMAL(18,6))
                           * CAST(sessions AS DECIMAL(18,6))
                    END
                )
                /
                NULLIF
                (
                    SUM
                    (
                        CASE
                            WHEN sessions > 0 AND bounce_rate IS NOT NULL
                            THEN CAST(sessions AS DECIMAL(18,6))
                        END
                    ),
                    0
                ),
                AVG(CAST(bounce_rate AS DECIMAL(18,6)))
            )
            AS DECIMAL(7,4)
        ) AS bounce_rate,

        CAST
        (
            COALESCE
            (
                SUM
                (
                    CASE
                        WHEN sessions > 0
                         AND avg_session_seconds IS NOT NULL
                        THEN CAST(avg_session_seconds AS DECIMAL(18,6))
                           * CAST(sessions AS DECIMAL(18,6))
                    END
                )
                /
                NULLIF
                (
                    SUM
                    (
                        CASE
                            WHEN sessions > 0
                             AND avg_session_seconds IS NOT NULL
                            THEN CAST(sessions AS DECIMAL(18,6))
                        END
                    ),
                    0
                ),
                AVG(CAST(avg_session_seconds AS DECIMAL(18,6)))
            )
            AS DECIMAL(8,1)
        ) AS avg_session_seconds,

        MAX(utm_source) AS utm_source,
        MAX(utm_medium) AS utm_medium,
        MAX(utm_campaign) AS utm_campaign,
        MAX(source_system) AS source_system
    FROM validated_web
    GROUP BY
        [date],
        campaign_id,
        channel,
        country,
        city,
        device;

    SET @end_time = GETDATE();

    SELECT @row_count = COUNT(*)
    FROM silver.fact_web_daily;

    PRINT 'DATA LOADED INTO silver.fact_web_daily SUCCESSFULLY';
    PRINT 'LOADING TIME: '
        + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
        + ' seconds';
    PRINT 'TOTAL ROWS LOADED: '
        + CAST(@row_count AS NVARCHAR(20));

END TRY
BEGIN CATCH

    PRINT 'ERROR LOADING silver.fact_web_daily';
    PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();

END CATCH;

PRINT '';


/*=========================================================
  5. LOAD silver.fact_conversions

  Conversion data is aggregated to:
  date + campaign + channel + country + city + device
  + conversion type.
=========================================================*/

SET @start_time = GETDATE();

PRINT '------------------------------------------------';
PRINT 'LOADING DATA INTO silver.fact_conversions';
PRINT '------------------------------------------------';

BEGIN TRY

    TRUNCATE TABLE silver.fact_conversions;

    ;WITH cleaned_conversions AS
    (
        SELECT
            c.[date],
            TRIM(c.campaign_id) AS campaign_id,

            CASE LOWER(TRIM(c.channel_raw))
                WHEN 'ppc'                  THEN 'Paid Search'
                WHEN 'paid search'          THEN 'Paid Search'
                WHEN 'paid social'          THEN 'Paid Social'
                WHEN 'display'              THEN 'Programmatic Display'
                WHEN 'programmatic display' THEN 'Programmatic Display'
                WHEN 'youtube'              THEN 'Online Video'
                WHEN 'online video'         THEN 'Online Video'
                WHEN 'organic-social'       THEN 'Organic Social'
                WHEN 'organic social'       THEN 'Organic Social'
                ELSE TRIM(c.channel_raw)
            END AS channel,

            NULLIF(TRIM(c.country), '') AS country,
            NULLIF(TRIM(c.city), '') AS city,
            NULLIF(TRIM(c.device), '') AS device,

            CASE LOWER(TRIM(c.conversion_type))
                WHEN 'lead'     THEN 'Lead'
                WHEN 'purchase' THEN 'Purchase'
                ELSE NULLIF(TRIM(c.conversion_type), '')
            END AS conversion_type,

            c.conversions,
            c.revenue,
            NULLIF(TRIM(c.source_system), '') AS source_system
        FROM bronze.fact_conversions_raw AS c
        WHERE c.[date] IS NOT NULL
          AND NULLIF(TRIM(c.campaign_id), '') IS NOT NULL
          AND (c.conversions IS NULL OR c.conversions >= 0)
          AND (c.revenue IS NULL OR c.revenue >= 0)
    ),
    validated_conversions AS
    (
        SELECT
            c.*
        FROM cleaned_conversions AS c
        INNER JOIN silver.dim_campaign AS ca
            ON c.campaign_id = ca.campaign_id
        WHERE (ca.start_date IS NULL OR c.[date] >= ca.start_date)
          AND (ca.end_date IS NULL OR c.[date] <= ca.end_date)
    )
    INSERT INTO silver.fact_conversions
    (
        [date],
        campaign_id,
        channel,
        country,
        city,
        device,
        conversion_type,
        conversions,
        revenue,
        source_system
    )
    SELECT
        [date],
        campaign_id,
        channel,
        country,
        city,
        device,
        conversion_type,
        SUM(conversions) AS conversions,
        SUM(revenue) AS revenue,
        MAX(source_system) AS source_system
    FROM validated_conversions
    GROUP BY
        [date],
        campaign_id,
        channel,
        country,
        city,
        device,
        conversion_type;

    SET @end_time = GETDATE();

    SELECT @row_count = COUNT(*)
    FROM silver.fact_conversions;

    PRINT 'DATA LOADED INTO silver.fact_conversions SUCCESSFULLY';
    PRINT 'LOADING TIME: '
        + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
        + ' seconds';
    PRINT 'TOTAL ROWS LOADED: '
        + CAST(@row_count AS NVARCHAR(20));

END TRY
BEGIN CATCH

    PRINT 'ERROR LOADING silver.fact_conversions';
    PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();

END CATCH;

PRINT '';


/*=========================================================
  6. LOAD silver.campaign_targets
=========================================================*/

SET @start_time = GETDATE();

PRINT '------------------------------------------------';
PRINT 'LOADING DATA INTO silver.campaign_targets';
PRINT '------------------------------------------------';

BEGIN TRY

    TRUNCATE TABLE silver.campaign_targets;

    ;WITH cleaned_targets AS
    (
        SELECT
            TRIM(t.campaign_id) AS campaign_id,

            CASE
                WHEN t.target_ctr BETWEEN 0 AND 1
                THEN t.target_ctr
                ELSE NULL
            END AS target_ctr,

            CASE
                WHEN t.target_cpc >= 0
                THEN t.target_cpc
                ELSE NULL
            END AS target_cpc,

            CASE
                WHEN t.target_cvr BETWEEN 0 AND 1
                THEN t.target_cvr
                ELSE NULL
            END AS target_cvr,

            CASE
                WHEN t.target_cpa >= 0
                THEN t.target_cpa
                ELSE NULL
            END AS target_cpa,

            CASE
                WHEN t.target_qa_pass_rate BETWEEN 0 AND 1
                THEN t.target_qa_pass_rate
                ELSE NULL
            END AS target_qa_pass_rate,

            ROW_NUMBER() OVER
            (
                PARTITION BY TRIM(t.campaign_id)
                ORDER BY TRIM(t.campaign_id)
            ) AS row_num
        FROM bronze.campaign_targets AS t
        INNER JOIN silver.dim_campaign AS ca
            ON TRIM(t.campaign_id) = ca.campaign_id
        WHERE NULLIF(TRIM(t.campaign_id), '') IS NOT NULL
    )
    INSERT INTO silver.campaign_targets
    (
        campaign_id,
        target_ctr,
        target_cpc,
        target_cvr,
        target_cpa,
        target_qa_pass_rate
    )
    SELECT
        campaign_id,
        target_ctr,
        target_cpc,
        target_cvr,
        target_cpa,
        target_qa_pass_rate
    FROM cleaned_targets
    WHERE row_num = 1;

    SET @end_time = GETDATE();

    SELECT @row_count = COUNT(*)
    FROM silver.campaign_targets;

    PRINT 'DATA LOADED INTO silver.campaign_targets SUCCESSFULLY';
    PRINT 'LOADING TIME: '
        + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
        + ' seconds';
    PRINT 'TOTAL ROWS LOADED: '
        + CAST(@row_count AS NVARCHAR(20));

END TRY
BEGIN CATCH

    PRINT 'ERROR LOADING silver.campaign_targets';
    PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();

END CATCH;

PRINT '';


/*=========================================================
  VERIFY SILVER ROW COUNTS
=========================================================*/

PRINT '#################################################';
PRINT 'SILVER LAYER ROW-COUNT SUMMARY';
PRINT '#################################################';

SELECT
    'silver.dim_campaign' AS table_name,
    COUNT(*) AS total_rows
FROM silver.dim_campaign

UNION ALL

SELECT
    'silver.dim_creative',
    COUNT(*)
FROM silver.dim_creative

UNION ALL

SELECT
    'silver.fact_media_daily',
    COUNT(*)
FROM silver.fact_media_daily

UNION ALL

SELECT
    'silver.fact_web_daily',
    COUNT(*)
FROM silver.fact_web_daily

UNION ALL

SELECT
    'silver.fact_conversions',
    COUNT(*)
FROM silver.fact_conversions

UNION ALL

SELECT
    'silver.campaign_targets',
    COUNT(*)
FROM silver.campaign_targets;
GO


/*=========================================================
  BRONZE-TO-SILVER RECONCILIATION
=========================================================*/

SELECT
    'dim_campaign' AS dataset,
    (SELECT COUNT(*) FROM bronze.dim_campaign) AS bronze_rows,
    (SELECT COUNT(*) FROM silver.dim_campaign) AS silver_rows,
    (SELECT COUNT(*) FROM bronze.dim_campaign)
        - (SELECT COUNT(*) FROM silver.dim_campaign) AS row_difference

UNION ALL

SELECT
    'dim_creative',
    (SELECT COUNT(*) FROM bronze.dim_creative),
    (SELECT COUNT(*) FROM silver.dim_creative),
    (SELECT COUNT(*) FROM bronze.dim_creative)
        - (SELECT COUNT(*) FROM silver.dim_creative)

UNION ALL

SELECT
    'fact_media_daily',
    (SELECT COUNT(*) FROM bronze.fact_media_daily_raw),
    (SELECT COUNT(*) FROM silver.fact_media_daily),
    (SELECT COUNT(*) FROM bronze.fact_media_daily_raw)
        - (SELECT COUNT(*) FROM silver.fact_media_daily)

UNION ALL

SELECT
    'fact_web_daily',
    (SELECT COUNT(*) FROM bronze.fact_web_daily_raw),
    (SELECT COUNT(*) FROM silver.fact_web_daily),
    (SELECT COUNT(*) FROM bronze.fact_web_daily_raw)
        - (SELECT COUNT(*) FROM silver.fact_web_daily)

UNION ALL

SELECT
    'fact_conversions',
    (SELECT COUNT(*) FROM bronze.fact_conversions_raw),
    (SELECT COUNT(*) FROM silver.fact_conversions),
    (SELECT COUNT(*) FROM bronze.fact_conversions_raw)
        - (SELECT COUNT(*) FROM silver.fact_conversions)

UNION ALL

SELECT
    'campaign_targets',
    (SELECT COUNT(*) FROM bronze.campaign_targets),
    (SELECT COUNT(*) FROM silver.campaign_targets),
    (SELECT COUNT(*) FROM bronze.campaign_targets)
        - (SELECT COUNT(*) FROM silver.campaign_targets);
GO

PRINT '#################################################';
PRINT 'SILVER LAYER LOADING COMPLETED';
PRINT '#################################################';
GO
