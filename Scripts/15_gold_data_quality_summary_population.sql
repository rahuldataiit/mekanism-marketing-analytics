/*=========================================================
  POPULATE:
  gold.data_quality_summary

  RESULTS:
  1. Dataset-level quality summary
  2. Campaign-level quality summary
=========================================================*/

USE mekanism_marketing_analytics;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;


/*=========================================================
  1. REMOVE PREVIOUS QUALITY RESULTS
=========================================================*/

TRUNCATE TABLE gold.data_quality_summary;


/*=========================================================
  2. CREATE TEMPORARY MEDIA QUALITY RESULTS
=========================================================*/

DROP TABLE IF EXISTS #media_quality;

;WITH media_prepared AS
(
    SELECT
        ROW_NUMBER() OVER
        (
            ORDER BY (SELECT NULL)
        ) AS source_row_number,

        NULLIF(TRIM(m.media_row_id), '') AS media_row_id,
        m.[date],

        NULLIF(TRIM(m.campaign_id), '') AS campaign_id,
        NULLIF(TRIM(m.creative_id), '') AS creative_id,

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
            ELSE NULLIF(TRIM(m.channel_raw), '')
        END AS channel,

        NULLIF(TRIM(m.country), '') AS country,
        NULLIF(TRIM(m.city), '')    AS city,
        NULLIF(TRIM(m.device), '')  AS device,

        m.impressions,
        m.clicks,
        m.spend,
        m.video_views,
        m.engagements,

        NULLIF(TRIM(m.utm_source), '') AS utm_source,
        NULLIF(TRIM(m.utm_medium), '') AS utm_medium

    FROM bronze.fact_media_daily_raw AS m
),

media_flags AS
(
    SELECT
        m.*,

        ca.start_date,
        ca.end_date,

        CASE
            WHEN m.media_row_id IS NULL
              OR m.[date] IS NULL
              OR m.campaign_id IS NULL
              OR m.creative_id IS NULL
            THEN 1 ELSE 0
        END AS missing_key_flag,

        CASE
            WHEN m.impressions < 0
              OR m.clicks < 0
              OR m.spend < 0
              OR m.video_views < 0
              OR m.engagements < 0
              OR
              (
                  m.clicks IS NOT NULL
                  AND m.impressions IS NOT NULL
                  AND m.clicks > m.impressions
              )
            THEN 1 ELSE 0
        END AS invalid_metric_flag,

        CASE
            WHEN m.campaign_id IS NOT NULL
             AND ca.campaign_id IS NULL
            THEN 1 ELSE 0
        END AS unmatched_campaign_flag,

        CASE
            WHEN m.campaign_id IS NOT NULL
             AND m.creative_id IS NOT NULL
             AND cr.creative_id IS NULL
            THEN 1 ELSE 0
        END AS unmatched_creative_flag,

        CASE
            WHEN ca.campaign_id IS NOT NULL
             AND m.[date] IS NOT NULL
             AND
             (
                 (ca.start_date IS NOT NULL
                  AND m.[date] < ca.start_date)

                 OR

                 (ca.end_date IS NOT NULL
                  AND m.[date] > ca.end_date)
             )
            THEN 1 ELSE 0
        END AS invalid_date_flag

    FROM media_prepared AS m

    LEFT JOIN silver.dim_campaign AS ca
        ON ca.campaign_id = m.campaign_id

    LEFT JOIN silver.dim_creative AS cr
        ON cr.creative_id = m.creative_id
       AND cr.campaign_id = m.campaign_id
),

media_assessed AS
(
    SELECT
        *,

        CASE
            WHEN missing_key_flag = 0
             AND invalid_metric_flag = 0
             AND unmatched_campaign_flag = 0
             AND unmatched_creative_flag = 0
             AND invalid_date_flag = 0
            THEN 1
            ELSE 0
        END AS base_valid_flag

    FROM media_flags
),

media_ranked AS
(
    SELECT
        *,

        CASE
            WHEN base_valid_flag = 1
            THEN ROW_NUMBER() OVER
            (
                PARTITION BY
                    base_valid_flag,
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

                    media_row_id,
                    source_row_number
            )
        END AS duplicate_rank

    FROM media_assessed
)

SELECT
    campaign_id,

    missing_key_flag,
    invalid_metric_flag,
    invalid_date_flag,
    unmatched_campaign_flag,
    unmatched_creative_flag,

    CASE
        WHEN base_valid_flag = 1
         AND duplicate_rank > 1
        THEN 1
        ELSE 0
    END AS duplicate_flag,

    CASE
        WHEN base_valid_flag = 0
          OR duplicate_rank > 1
        THEN 1
        ELSE 0
    END AS row_failed

INTO #media_quality

FROM media_ranked;


/*=========================================================
  3. CREATE TEMPORARY WEB QUALITY RESULTS
=========================================================*/

DROP TABLE IF EXISTS #web_quality;

;WITH web_prepared AS
(
    SELECT
        w.[date],

        NULLIF(TRIM(w.campaign_id), '') AS campaign_id,

        w.sessions,
        w.bounce_rate,
        w.avg_session_seconds

    FROM bronze.fact_web_daily_raw AS w
),

web_assessed AS
(
    SELECT
        w.campaign_id,

        CASE
            WHEN w.[date] IS NULL
              OR w.campaign_id IS NULL
            THEN 1 ELSE 0
        END AS missing_key_flag,

        CASE
            WHEN w.sessions < 0
              OR
              (
                  w.bounce_rate IS NOT NULL
                  AND
                  (
                      w.bounce_rate < 0
                      OR w.bounce_rate > 1
                  )
              )
              OR w.avg_session_seconds < 0
            THEN 1 ELSE 0
        END AS invalid_metric_flag,

        CASE
            WHEN w.campaign_id IS NOT NULL
             AND ca.campaign_id IS NULL
            THEN 1 ELSE 0
        END AS unmatched_campaign_flag,

        CASE
            WHEN ca.campaign_id IS NOT NULL
             AND w.[date] IS NOT NULL
             AND
             (
                 (ca.start_date IS NOT NULL
                  AND w.[date] < ca.start_date)

                 OR

                 (ca.end_date IS NOT NULL
                  AND w.[date] > ca.end_date)
             )
            THEN 1 ELSE 0
        END AS invalid_date_flag

    FROM web_prepared AS w

    LEFT JOIN silver.dim_campaign AS ca
        ON ca.campaign_id = w.campaign_id
)

SELECT
    campaign_id,

    missing_key_flag,
    invalid_metric_flag,
    invalid_date_flag,
    unmatched_campaign_flag,

    CASE
        WHEN missing_key_flag = 1
          OR invalid_metric_flag = 1
          OR invalid_date_flag = 1
          OR unmatched_campaign_flag = 1
        THEN 1
        ELSE 0
    END AS row_failed

INTO #web_quality

FROM web_assessed;


/*=========================================================
  4. CREATE TEMPORARY CONVERSION QUALITY RESULTS
=========================================================*/

DROP TABLE IF EXISTS #conversion_quality;

;WITH conversion_prepared AS
(
    SELECT
        c.[date],

        NULLIF(TRIM(c.campaign_id), '') AS campaign_id,

        c.conversions,
        c.revenue

    FROM bronze.fact_conversions_raw AS c
),

conversion_assessed AS
(
    SELECT
        c.campaign_id,

        CASE
            WHEN c.[date] IS NULL
              OR c.campaign_id IS NULL
            THEN 1 ELSE 0
        END AS missing_key_flag,

        CASE
            WHEN c.conversions < 0
              OR c.revenue < 0
            THEN 1 ELSE 0
        END AS invalid_metric_flag,

        CASE
            WHEN c.campaign_id IS NOT NULL
             AND ca.campaign_id IS NULL
            THEN 1 ELSE 0
        END AS unmatched_campaign_flag,

        CASE
            WHEN ca.campaign_id IS NOT NULL
             AND c.[date] IS NOT NULL
             AND
             (
                 (ca.start_date IS NOT NULL
                  AND c.[date] < ca.start_date)

                 OR

                 (ca.end_date IS NOT NULL
                  AND c.[date] > ca.end_date)
             )
            THEN 1 ELSE 0
        END AS invalid_date_flag

    FROM conversion_prepared AS c

    LEFT JOIN silver.dim_campaign AS ca
        ON ca.campaign_id = c.campaign_id
)

SELECT
    campaign_id,

    missing_key_flag,
    invalid_metric_flag,
    invalid_date_flag,
    unmatched_campaign_flag,

    CASE
        WHEN missing_key_flag = 1
          OR invalid_metric_flag = 1
          OR invalid_date_flag = 1
          OR unmatched_campaign_flag = 1
        THEN 1
        ELSE 0
    END AS row_failed

INTO #conversion_quality

FROM conversion_assessed;


/*=========================================================
  5. INSERT DATASET-LEVEL QUALITY RESULTS
=========================================================*/

;WITH dataset_base AS
(
    /*---------------- MEDIA ----------------*/

    SELECT
        'Media' AS dataset_name,

        'bronze.fact_media_daily_raw'
            AS bronze_table_name,

        'silver.fact_media_daily'
            AS silver_table_name,

        COUNT_BIG(*) AS bronze_row_count,

        (
            SELECT COUNT_BIG(*)
            FROM silver.fact_media_daily
        ) AS silver_row_count,

        COUNT_BIG(*) AS rows_checked,

        SUM
        (
            CAST
            (
                CASE WHEN row_failed = 0
                     THEN 1 ELSE 0 END
                AS BIGINT
            )
        ) AS rows_passed,

        SUM(CAST(row_failed AS BIGINT))
            AS rows_failed,

        SUM(CAST(duplicate_flag AS BIGINT))
            AS duplicate_rows,

        SUM(CAST(missing_key_flag AS BIGINT))
            AS missing_key_rows,

        SUM(CAST(invalid_metric_flag AS BIGINT))
            AS invalid_metric_rows,

        SUM(CAST(invalid_date_flag AS BIGINT))
            AS invalid_date_rows,

        SUM(CAST(unmatched_campaign_flag AS BIGINT))
            AS unmatched_campaign_rows,

        SUM(CAST(unmatched_creative_flag AS BIGINT))
            AS unmatched_creative_rows

    FROM #media_quality


    UNION ALL


    /*---------------- WEB ----------------*/

    SELECT
        'Web',

        'bronze.fact_web_daily_raw',

        'silver.fact_web_daily',

        COUNT_BIG(*),

        (
            SELECT COUNT_BIG(*)
            FROM silver.fact_web_daily
        ),

        COUNT_BIG(*),

        SUM
        (
            CAST
            (
                CASE WHEN row_failed = 0
                     THEN 1 ELSE 0 END
                AS BIGINT
            )
        ),

        SUM(CAST(row_failed AS BIGINT)),

        0,

        SUM(CAST(missing_key_flag AS BIGINT)),

        SUM(CAST(invalid_metric_flag AS BIGINT)),

        SUM(CAST(invalid_date_flag AS BIGINT)),

        SUM(CAST(unmatched_campaign_flag AS BIGINT)),

        0

    FROM #web_quality


    UNION ALL


    /*---------------- CONVERSIONS ----------------*/

    SELECT
        'Conversions',

        'bronze.fact_conversions_raw',

        'silver.fact_conversions',

        COUNT_BIG(*),

        (
            SELECT COUNT_BIG(*)
            FROM silver.fact_conversions
        ),

        COUNT_BIG(*),

        SUM
        (
            CAST
            (
                CASE WHEN row_failed = 0
                     THEN 1 ELSE 0 END
                AS BIGINT
            )
        ),

        SUM(CAST(row_failed AS BIGINT)),

        0,

        SUM(CAST(missing_key_flag AS BIGINT)),

        SUM(CAST(invalid_metric_flag AS BIGINT)),

        SUM(CAST(invalid_date_flag AS BIGINT)),

        SUM(CAST(unmatched_campaign_flag AS BIGINT)),

        0

    FROM #conversion_quality
),

dataset_calculated AS
(
    SELECT
        *,

        CASE
            WHEN dataset_name IN ('Web', 'Conversions')
             AND rows_passed > silver_row_count
            THEN rows_passed - silver_row_count
            ELSE 0
        END AS consolidated_rows,

        CAST
        (
            CAST(rows_passed AS DECIMAL(38,10))
            /
            NULLIF
            (
                CAST(rows_checked AS DECIMAL(38,10)),
                0
            )
            AS DECIMAL(9,6)
        ) AS qa_pass_rate

    FROM dataset_base
)

INSERT INTO gold.data_quality_summary
(
    summary_date,
    summary_level,
    dataset_name,
    campaign_id,

    bronze_table_name,
    silver_table_name,

    bronze_row_count,
    silver_row_count,
    rows_checked,
    rows_passed,
    rows_failed,

    duplicate_rows,
    missing_key_rows,
    invalid_metric_rows,
    invalid_date_rows,
    unmatched_campaign_rows,
    unmatched_creative_rows,
    consolidated_rows,
    other_issue_rows,
    total_issue_rows,

    qa_pass_rate,
    quality_status,
    notes
)

SELECT
    CAST(SYSDATETIME() AS DATE),

    'Dataset',

    dataset_name,

    NULL,

    bronze_table_name,
    silver_table_name,

    bronze_row_count,
    silver_row_count,
    rows_checked,
    rows_passed,
    rows_failed,

    duplicate_rows,
    missing_key_rows,
    invalid_metric_rows,
    invalid_date_rows,
    unmatched_campaign_rows,
    unmatched_creative_rows,
    consolidated_rows,

    0,

    rows_failed,

    qa_pass_rate,

    CASE
        WHEN rows_checked = 0
            THEN 'Not Evaluated'

        WHEN qa_pass_rate >= 0.970000
            THEN 'Passed'

        WHEN qa_pass_rate >= 0.900000
            THEN 'Warning'

        ELSE 'Failed'
    END,

    CASE
        WHEN dataset_name = 'Media'
        THEN
            'Duplicate media records are treated as failed rows.'

        ELSE
            'Valid source rows may be consolidated into fewer Silver rows during aggregation.'
    END

FROM dataset_calculated;


/*=========================================================
  6. INSERT CAMPAIGN-LEVEL QUALITY RESULTS
=========================================================*/

;WITH media_campaign AS
(
    SELECT
        campaign_id,

        COUNT_BIG(*) AS bronze_rows,

        SUM
        (
            CAST
            (
                CASE WHEN row_failed = 0
                     THEN 1 ELSE 0 END
                AS BIGINT
            )
        ) AS rows_passed,

        SUM(CAST(row_failed AS BIGINT))
            AS rows_failed,

        SUM(CAST(duplicate_flag AS BIGINT))
            AS duplicate_rows,

        SUM(CAST(missing_key_flag AS BIGINT))
            AS missing_key_rows,

        SUM(CAST(invalid_metric_flag AS BIGINT))
            AS invalid_metric_rows,

        SUM(CAST(invalid_date_flag AS BIGINT))
            AS invalid_date_rows,

        SUM(CAST(unmatched_campaign_flag AS BIGINT))
            AS unmatched_campaign_rows,

        SUM(CAST(unmatched_creative_flag AS BIGINT))
            AS unmatched_creative_rows

    FROM #media_quality

    WHERE campaign_id IS NOT NULL

    GROUP BY campaign_id
),

media_silver AS
(
    SELECT
        campaign_id,
        COUNT_BIG(*) AS silver_rows
    FROM silver.fact_media_daily
    GROUP BY campaign_id
),

web_campaign AS
(
    SELECT
        campaign_id,

        COUNT_BIG(*) AS bronze_rows,

        SUM
        (
            CAST
            (
                CASE WHEN row_failed = 0
                     THEN 1 ELSE 0 END
                AS BIGINT
            )
        ) AS rows_passed,

        SUM(CAST(row_failed AS BIGINT))
            AS rows_failed,

        SUM(CAST(missing_key_flag AS BIGINT))
            AS missing_key_rows,

        SUM(CAST(invalid_metric_flag AS BIGINT))
            AS invalid_metric_rows,

        SUM(CAST(invalid_date_flag AS BIGINT))
            AS invalid_date_rows,

        SUM(CAST(unmatched_campaign_flag AS BIGINT))
            AS unmatched_campaign_rows

    FROM #web_quality

    WHERE campaign_id IS NOT NULL

    GROUP BY campaign_id
),

web_silver AS
(
    SELECT
        campaign_id,
        COUNT_BIG(*) AS silver_rows
    FROM silver.fact_web_daily
    GROUP BY campaign_id
),

conversion_campaign AS
(
    SELECT
        campaign_id,

        COUNT_BIG(*) AS bronze_rows,

        SUM
        (
            CAST
            (
                CASE WHEN row_failed = 0
                     THEN 1 ELSE 0 END
                AS BIGINT
            )
        ) AS rows_passed,

        SUM(CAST(row_failed AS BIGINT))
            AS rows_failed,

        SUM(CAST(missing_key_flag AS BIGINT))
            AS missing_key_rows,

        SUM(CAST(invalid_metric_flag AS BIGINT))
            AS invalid_metric_rows,

        SUM(CAST(invalid_date_flag AS BIGINT))
            AS invalid_date_rows,

        SUM(CAST(unmatched_campaign_flag AS BIGINT))
            AS unmatched_campaign_rows

    FROM #conversion_quality

    WHERE campaign_id IS NOT NULL

    GROUP BY campaign_id
),

conversion_silver AS
(
    SELECT
        campaign_id,
        COUNT_BIG(*) AS silver_rows
    FROM silver.fact_conversions
    GROUP BY campaign_id
),

campaign_base AS
(
    SELECT
        c.campaign_id,

        COALESCE(m.bronze_rows, 0)
        + COALESCE(w.bronze_rows, 0)
        + COALESCE(v.bronze_rows, 0)
            AS bronze_row_count,

        COALESCE(ms.silver_rows, 0)
        + COALESCE(ws.silver_rows, 0)
        + COALESCE(vs.silver_rows, 0)
            AS silver_row_count,

        COALESCE(m.bronze_rows, 0)
        + COALESCE(w.bronze_rows, 0)
        + COALESCE(v.bronze_rows, 0)
            AS rows_checked,

        COALESCE(m.rows_passed, 0)
        + COALESCE(w.rows_passed, 0)
        + COALESCE(v.rows_passed, 0)
            AS rows_passed,

        COALESCE(m.rows_failed, 0)
        + COALESCE(w.rows_failed, 0)
        + COALESCE(v.rows_failed, 0)
            AS rows_failed,

        COALESCE(m.duplicate_rows, 0)
            AS duplicate_rows,

        COALESCE(m.missing_key_rows, 0)
        + COALESCE(w.missing_key_rows, 0)
        + COALESCE(v.missing_key_rows, 0)
            AS missing_key_rows,

        COALESCE(m.invalid_metric_rows, 0)
        + COALESCE(w.invalid_metric_rows, 0)
        + COALESCE(v.invalid_metric_rows, 0)
            AS invalid_metric_rows,

        COALESCE(m.invalid_date_rows, 0)
        + COALESCE(w.invalid_date_rows, 0)
        + COALESCE(v.invalid_date_rows, 0)
            AS invalid_date_rows,

        COALESCE(m.unmatched_campaign_rows, 0)
        + COALESCE(w.unmatched_campaign_rows, 0)
        + COALESCE(v.unmatched_campaign_rows, 0)
            AS unmatched_campaign_rows,

        COALESCE(m.unmatched_creative_rows, 0)
            AS unmatched_creative_rows,

        CASE
            WHEN COALESCE(w.rows_passed, 0)
                 > COALESCE(ws.silver_rows, 0)

            THEN COALESCE(w.rows_passed, 0)
                 - COALESCE(ws.silver_rows, 0)

            ELSE 0
        END
        +
        CASE
            WHEN COALESCE(v.rows_passed, 0)
                 > COALESCE(vs.silver_rows, 0)

            THEN COALESCE(v.rows_passed, 0)
                 - COALESCE(vs.silver_rows, 0)

            ELSE 0
        END AS consolidated_rows

    FROM silver.dim_campaign AS c

    LEFT JOIN media_campaign AS m
        ON m.campaign_id = c.campaign_id

    LEFT JOIN media_silver AS ms
        ON ms.campaign_id = c.campaign_id

    LEFT JOIN web_campaign AS w
        ON w.campaign_id = c.campaign_id

    LEFT JOIN web_silver AS ws
        ON ws.campaign_id = c.campaign_id

    LEFT JOIN conversion_campaign AS v
        ON v.campaign_id = c.campaign_id

    LEFT JOIN conversion_silver AS vs
        ON vs.campaign_id = c.campaign_id
),

campaign_calculated AS
(
    SELECT
        *,

        CAST
        (
            CAST(rows_passed AS DECIMAL(38,10))
            /
            NULLIF
            (
                CAST(rows_checked AS DECIMAL(38,10)),
                0
            )
            AS DECIMAL(9,6)
        ) AS qa_pass_rate

    FROM campaign_base
)

INSERT INTO gold.data_quality_summary
(
    summary_date,
    summary_level,
    dataset_name,
    campaign_id,

    bronze_table_name,
    silver_table_name,

    bronze_row_count,
    silver_row_count,
    rows_checked,
    rows_passed,
    rows_failed,

    duplicate_rows,
    missing_key_rows,
    invalid_metric_rows,
    invalid_date_rows,
    unmatched_campaign_rows,
    unmatched_creative_rows,
    consolidated_rows,
    other_issue_rows,
    total_issue_rows,

    qa_pass_rate,
    quality_status,
    notes
)

SELECT
    CAST(SYSDATETIME() AS DATE),

    'Campaign',

    'All Sources',

    campaign_id,

    'Multiple Bronze Fact Tables',
    'Multiple Silver Fact Tables',

    bronze_row_count,
    silver_row_count,
    rows_checked,
    rows_passed,
    rows_failed,

    duplicate_rows,
    missing_key_rows,
    invalid_metric_rows,
    invalid_date_rows,
    unmatched_campaign_rows,
    unmatched_creative_rows,
    consolidated_rows,

    0,

    rows_failed,

    qa_pass_rate,

    CASE
        WHEN rows_checked = 0
            THEN 'Not Evaluated'

        WHEN qa_pass_rate >= 0.970000
            THEN 'Passed'

        WHEN qa_pass_rate >= 0.900000
            THEN 'Warning'

        ELSE 'Failed'
    END,

    'Combined campaign-level quality result across media, web and conversion source rows.'

FROM campaign_calculated;


/*=========================================================
  7. REVIEW THE POPULATED RESULTS
=========================================================*/

SELECT
    summary_level,
    dataset_name,
    campaign_id,

    bronze_row_count,
    silver_row_count,

    rows_checked,
    rows_passed,
    rows_failed,

    duplicate_rows,
    invalid_metric_rows,
    invalid_date_rows,
    consolidated_rows,

    qa_pass_rate,
    quality_status

FROM gold.data_quality_summary

ORDER BY
    CASE
        WHEN summary_level = 'Dataset' THEN 1
        ELSE 2
    END,
    dataset_name,
    campaign_id;
GO
