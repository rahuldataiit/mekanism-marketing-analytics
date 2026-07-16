/*=========================================================
  MEKANISM MARKETING ANALYTICS
  BRONZE LAYER DATA PROFILING

  Purpose:
  Identify records and values that may require cleaning
  before creating the Silver layer.

  Interpretation:
  - Queries labelled "Expected: zero rows" identify errors.
  - Category queries should be reviewed for inconsistent
    spellings, capitalization, spacing, and naming.
=========================================================*/

USE mekanism_marketing_analytics;
GO


/*=========================================================
  0. ROW-COUNT OVERVIEW
=========================================================*/

SELECT 'bronze.dim_campaign' AS table_name, COUNT(*) AS total_rows
FROM bronze.dim_campaign

UNION ALL
SELECT 'bronze.dim_creative', COUNT(*)
FROM bronze.dim_creative

UNION ALL
SELECT 'bronze.fact_media_daily_raw', COUNT(*)
FROM bronze.fact_media_daily_raw

UNION ALL
SELECT 'bronze.fact_web_daily_raw', COUNT(*)
FROM bronze.fact_web_daily_raw

UNION ALL
SELECT 'bronze.fact_conversions_raw', COUNT(*)
FROM bronze.fact_conversions_raw

UNION ALL
SELECT 'bronze.campaign_targets', COUNT(*)
FROM bronze.campaign_targets;
GO


/*=========================================================
  1. PROFILE bronze.dim_campaign
=========================================================*/

PRINT '================================================';
PRINT 'PROFILING bronze.dim_campaign';
PRINT '================================================';


/* 1.1 Preview the data */

SELECT *
FROM bronze.dim_campaign
ORDER BY campaign_id;


/* 1.2 Find NULL or blank mandatory values
   Expected: zero rows
*/

SELECT *
FROM bronze.dim_campaign
WHERE campaign_id IS NULL
   OR NULLIF(TRIM(campaign_id), '') IS NULL
   OR campaign_name IS NULL
   OR NULLIF(TRIM(campaign_name), '') IS NULL
   OR client_name IS NULL
   OR NULLIF(TRIM(client_name), '') IS NULL
   OR objective IS NULL
   OR NULLIF(TRIM(objective), '') IS NULL;


/* 1.3 Find duplicate campaign IDs
   Note: the primary key should prevent these from loading.
   Expected: zero rows
*/

SELECT
    campaign_id,
    COUNT(*) AS duplicate_count
FROM bronze.dim_campaign
GROUP BY campaign_id
HAVING COUNT(*) > 1;


/* 1.4 Find possible duplicate campaign names after
   ignoring capitalization and spaces
*/

SELECT
    LOWER(TRIM(campaign_name)) AS normalized_campaign_name,
    COUNT(*) AS record_count
FROM bronze.dim_campaign
GROUP BY LOWER(TRIM(campaign_name))
HAVING COUNT(*) > 1;


/* 1.5 Review objective naming consistency */

SELECT
    objective AS raw_objective,
    LOWER(TRIM(objective)) AS normalized_objective,
    COUNT(*) AS record_count
FROM bronze.dim_campaign
GROUP BY
    objective,
    LOWER(TRIM(objective))
ORDER BY normalized_objective, raw_objective;


/* 1.6 Review market naming consistency */

SELECT
    market AS raw_market,
    LOWER(TRIM(market)) AS normalized_market,
    COUNT(*) AS record_count
FROM bronze.dim_campaign
GROUP BY
    market,
    LOWER(TRIM(market))
ORDER BY normalized_market, raw_market;


/* 1.7 Find leading or trailing spaces */

SELECT *
FROM bronze.dim_campaign
WHERE campaign_id <> TRIM(campaign_id)
   OR campaign_name <> TRIM(campaign_name)
   OR client_name <> TRIM(client_name)
   OR objective <> TRIM(objective)
   OR market <> TRIM(market);


/* 1.8 Find invalid date or budget relationships
   Expected: zero rows
*/

SELECT *
FROM bronze.dim_campaign
WHERE start_date IS NULL
   OR end_date IS NULL
   OR end_date < start_date
   OR budget IS NULL
   OR budget < 0;


/*=========================================================
  2. PROFILE bronze.dim_creative
=========================================================*/

PRINT '================================================';
PRINT 'PROFILING bronze.dim_creative';
PRINT '================================================';


/* 2.1 Preview the data */

SELECT TOP (100) *
FROM bronze.dim_creative
ORDER BY creative_id;


/* 2.2 Find NULL or blank mandatory values
   Expected: zero rows
*/

SELECT *
FROM bronze.dim_creative
WHERE creative_id IS NULL
   OR NULLIF(TRIM(creative_id), '') IS NULL
   OR campaign_id IS NULL
   OR NULLIF(TRIM(campaign_id), '') IS NULL
   OR channel IS NULL
   OR NULLIF(TRIM(channel), '') IS NULL
   OR [format] IS NULL
   OR NULLIF(TRIM([format]), '') IS NULL
   OR creative_name IS NULL
   OR NULLIF(TRIM(creative_name), '') IS NULL
   OR variant IS NULL
   OR NULLIF(TRIM(variant), '') IS NULL;


/* 2.3 Find duplicate creative IDs
   Expected: zero rows
*/

SELECT
    creative_id,
    COUNT(*) AS duplicate_count
FROM bronze.dim_creative
GROUP BY creative_id
HAVING COUNT(*) > 1;


/* 2.4 Find duplicate creative definitions after ignoring
   capitalization and extra spaces
*/

SELECT
    campaign_id,
    LOWER(TRIM(channel)) AS normalized_channel,
    LOWER(TRIM([format])) AS normalized_format,
    LOWER(TRIM(creative_name)) AS normalized_creative_name,
    LOWER(TRIM(variant)) AS normalized_variant,
    COUNT(*) AS duplicate_count
FROM bronze.dim_creative
GROUP BY
    campaign_id,
    LOWER(TRIM(channel)),
    LOWER(TRIM([format])),
    LOWER(TRIM(creative_name)),
    LOWER(TRIM(variant))
HAVING COUNT(*) > 1;


/* 2.5 Review channel naming consistency */

SELECT
    channel AS raw_channel,
    LOWER(TRIM(channel)) AS normalized_channel,
    COUNT(*) AS record_count
FROM bronze.dim_creative
GROUP BY
    channel,
    LOWER(TRIM(channel))
ORDER BY normalized_channel, raw_channel;


/* 2.6 Review creative-format naming consistency */

SELECT
    [format] AS raw_format,
    LOWER(TRIM([format])) AS normalized_format,
    COUNT(*) AS record_count
FROM bronze.dim_creative
GROUP BY
    [format],
    LOWER(TRIM([format]))
ORDER BY normalized_format, raw_format;


/* 2.7 Review variant naming consistency */

SELECT
    variant AS raw_variant,
    UPPER(TRIM(variant)) AS normalized_variant,
    COUNT(*) AS record_count
FROM bronze.dim_creative
GROUP BY
    variant,
    UPPER(TRIM(variant))
ORDER BY normalized_variant, raw_variant;


/* 2.8 Find leading or trailing spaces */

SELECT *
FROM bronze.dim_creative
WHERE creative_id <> TRIM(creative_id)
   OR campaign_id <> TRIM(campaign_id)
   OR channel <> TRIM(channel)
   OR [format] <> TRIM([format])
   OR creative_name <> TRIM(creative_name)
   OR variant <> TRIM(variant);


/* 2.9 Find creative records with an invalid campaign ID
   Expected: zero rows
*/

SELECT
    cr.*
FROM bronze.dim_creative AS cr
LEFT JOIN bronze.dim_campaign AS ca
    ON cr.campaign_id = ca.campaign_id
WHERE ca.campaign_id IS NULL;


/*=========================================================
  3. PROFILE bronze.fact_media_daily_raw
=========================================================*/

PRINT '================================================';
PRINT 'PROFILING bronze.fact_media_daily_raw';
PRINT '================================================';


/* 3.1 Basic ranges */

SELECT
    COUNT(*) AS total_rows,
    MIN([date]) AS earliest_date,
    MAX([date]) AS latest_date,
    MIN(impressions) AS minimum_impressions,
    MAX(impressions) AS maximum_impressions,
    MIN(clicks) AS minimum_clicks,
    MAX(clicks) AS maximum_clicks,
    MIN(spend) AS minimum_spend,
    MAX(spend) AS maximum_spend
FROM bronze.fact_media_daily_raw;


/* 3.2 Count NULL or blank values */

SELECT
    SUM(CASE WHEN media_row_id IS NULL
                  OR NULLIF(TRIM(media_row_id), '') IS NULL
             THEN 1 ELSE 0 END) AS missing_media_row_id,

    SUM(CASE WHEN [date] IS NULL
             THEN 1 ELSE 0 END) AS missing_date,

    SUM(CASE WHEN campaign_id IS NULL
                  OR NULLIF(TRIM(campaign_id), '') IS NULL
             THEN 1 ELSE 0 END) AS missing_campaign_id,

    SUM(CASE WHEN creative_id IS NULL
                  OR NULLIF(TRIM(creative_id), '') IS NULL
             THEN 1 ELSE 0 END) AS missing_creative_id,

    SUM(CASE WHEN channel_raw IS NULL
                  OR NULLIF(TRIM(channel_raw), '') IS NULL
             THEN 1 ELSE 0 END) AS missing_channel,

    SUM(CASE WHEN country IS NULL
                  OR NULLIF(TRIM(country), '') IS NULL
             THEN 1 ELSE 0 END) AS missing_country,

    SUM(CASE WHEN city IS NULL
                  OR NULLIF(TRIM(city), '') IS NULL
             THEN 1 ELSE 0 END) AS missing_city,

    SUM(CASE WHEN device IS NULL
                  OR NULLIF(TRIM(device), '') IS NULL
             THEN 1 ELSE 0 END) AS missing_device,

    SUM(CASE WHEN utm_source IS NULL
                  OR NULLIF(TRIM(utm_source), '') IS NULL
             THEN 1 ELSE 0 END) AS missing_utm_source,

    SUM(CASE WHEN utm_medium IS NULL
                  OR NULLIF(TRIM(utm_medium), '') IS NULL
             THEN 1 ELSE 0 END) AS missing_utm_medium,

    SUM(CASE WHEN utm_campaign IS NULL
                  OR NULLIF(TRIM(utm_campaign), '') IS NULL
             THEN 1 ELSE 0 END) AS missing_utm_campaign
FROM bronze.fact_media_daily_raw;


/* 3.3 Find duplicate row IDs
   Expected: zero rows
*/

SELECT
    media_row_id,
    COUNT(*) AS duplicate_count
FROM bronze.fact_media_daily_raw
GROUP BY media_row_id
HAVING COUNT(*) > 1;


/* 3.4 Find exact content duplicates while ignoring
   the technical media_row_id
*/

SELECT
    [date],
    campaign_id,
    creative_id,
    channel_raw,
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
    source_system,
    COUNT(*) AS duplicate_count
FROM bronze.fact_media_daily_raw
GROUP BY
    [date],
    campaign_id,
    creative_id,
    channel_raw,
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
HAVING COUNT(*) > 1;


/* 3.5 Find duplicate expected business-grain records */

SELECT
    [date],
    campaign_id,
    creative_id,
    LOWER(TRIM(channel_raw)) AS normalized_channel,
    country,
    TRIM(city) AS normalized_city,
    device,
    COUNT(*) AS duplicate_count
FROM bronze.fact_media_daily_raw
GROUP BY
    [date],
    campaign_id,
    creative_id,
    LOWER(TRIM(channel_raw)),
    country,
    TRIM(city),
    device
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


/* 3.6 Review inconsistent channel names */

SELECT
    channel_raw AS raw_channel,
    LOWER(TRIM(channel_raw)) AS normalized_channel,
    COUNT(*) AS record_count
FROM bronze.fact_media_daily_raw
GROUP BY
    channel_raw,
    LOWER(TRIM(channel_raw))
ORDER BY normalized_channel, raw_channel;


/* 3.7 Review city names and spacing */

SELECT
    city AS raw_city,
    TRIM(city) AS normalized_city,
    COUNT(*) AS record_count
FROM bronze.fact_media_daily_raw
GROUP BY
    city,
    TRIM(city)
ORDER BY normalized_city, raw_city;


/* 3.8 Review other categorical values */

SELECT device, COUNT(*) AS record_count
FROM bronze.fact_media_daily_raw
GROUP BY device
ORDER BY device;

SELECT country, COUNT(*) AS record_count
FROM bronze.fact_media_daily_raw
GROUP BY country
ORDER BY country;

SELECT utm_source, COUNT(*) AS record_count
FROM bronze.fact_media_daily_raw
GROUP BY utm_source
ORDER BY utm_source;

SELECT utm_medium, COUNT(*) AS record_count
FROM bronze.fact_media_daily_raw
GROUP BY utm_medium
ORDER BY utm_medium;


/* 3.9 Find invalid metric relationships
   Expected: zero rows after cleaning
*/

SELECT *
FROM bronze.fact_media_daily_raw
WHERE impressions < 0
   OR clicks < 0
   OR spend < 0
   OR video_views < 0
   OR engagements < 0
   OR clicks > impressions;


/* 3.10 Find leading or trailing spaces */

SELECT *
FROM bronze.fact_media_daily_raw
WHERE campaign_id <> TRIM(campaign_id)
   OR creative_id <> TRIM(creative_id)
   OR channel_raw <> TRIM(channel_raw)
   OR country <> TRIM(country)
   OR city <> TRIM(city)
   OR device <> TRIM(device)
   OR utm_source <> TRIM(utm_source)
   OR utm_medium <> TRIM(utm_medium)
   OR utm_campaign <> TRIM(utm_campaign);


/* 3.11 Find invalid campaign IDs
   Expected: zero rows
*/

SELECT DISTINCT
    f.campaign_id
FROM bronze.fact_media_daily_raw AS f
LEFT JOIN bronze.dim_campaign AS c
    ON f.campaign_id = c.campaign_id
WHERE c.campaign_id IS NULL;


/* 3.12 Find invalid creative IDs
   Expected: zero rows
*/

SELECT DISTINCT
    f.creative_id
FROM bronze.fact_media_daily_raw AS f
LEFT JOIN bronze.dim_creative AS c
    ON f.creative_id = c.creative_id
WHERE c.creative_id IS NULL;


/* 3.13 Find campaign and creative mismatches
   Expected: zero rows
*/

SELECT
    f.media_row_id,
    f.campaign_id AS media_campaign_id,
    f.creative_id,
    c.campaign_id AS creative_campaign_id
FROM bronze.fact_media_daily_raw AS f
INNER JOIN bronze.dim_creative AS c
    ON f.creative_id = c.creative_id
WHERE f.campaign_id <> c.campaign_id;


/* 3.14 Find media dates outside campaign dates
   Expected: zero rows
*/

SELECT
    f.media_row_id,
    f.[date],
    f.campaign_id,
    c.start_date,
    c.end_date
FROM bronze.fact_media_daily_raw AS f
INNER JOIN bronze.dim_campaign AS c
    ON f.campaign_id = c.campaign_id
WHERE f.[date] < c.start_date
   OR f.[date] > c.end_date;


/*=========================================================
  4. PROFILE bronze.fact_web_daily_raw
=========================================================*/

PRINT '================================================';
PRINT 'PROFILING bronze.fact_web_daily_raw';
PRINT '================================================';


/* 4.1 Basic ranges */

SELECT
    COUNT(*) AS total_rows,
    MIN([date]) AS earliest_date,
    MAX([date]) AS latest_date,
    MIN(sessions) AS minimum_sessions,
    MAX(sessions) AS maximum_sessions,
    MIN(bounce_rate) AS minimum_bounce_rate,
    MAX(bounce_rate) AS maximum_bounce_rate,
    MIN(avg_session_seconds) AS minimum_session_seconds,
    MAX(avg_session_seconds) AS maximum_session_seconds
FROM bronze.fact_web_daily_raw;


/* 4.2 Count NULL or blank values */

SELECT
    SUM(CASE WHEN web_row_id IS NULL
                  OR NULLIF(TRIM(web_row_id), '') IS NULL
             THEN 1 ELSE 0 END) AS missing_web_row_id,

    SUM(CASE WHEN [date] IS NULL
             THEN 1 ELSE 0 END) AS missing_date,

    SUM(CASE WHEN campaign_id IS NULL
                  OR NULLIF(TRIM(campaign_id), '') IS NULL
             THEN 1 ELSE 0 END) AS missing_campaign_id,

    SUM(CASE WHEN channel_raw IS NULL
                  OR NULLIF(TRIM(channel_raw), '') IS NULL
             THEN 1 ELSE 0 END) AS missing_channel,

    SUM(CASE WHEN sessions IS NULL
             THEN 1 ELSE 0 END) AS missing_sessions,

    SUM(CASE WHEN bounce_rate IS NULL
             THEN 1 ELSE 0 END) AS missing_bounce_rate,

    SUM(CASE WHEN avg_session_seconds IS NULL
             THEN 1 ELSE 0 END) AS missing_avg_session_seconds,

    SUM(CASE WHEN utm_source IS NULL
                  OR NULLIF(TRIM(utm_source), '') IS NULL
             THEN 1 ELSE 0 END) AS missing_utm_source,

    SUM(CASE WHEN utm_medium IS NULL
                  OR NULLIF(TRIM(utm_medium), '') IS NULL
             THEN 1 ELSE 0 END) AS missing_utm_medium,

    SUM(CASE WHEN utm_campaign IS NULL
                  OR NULLIF(TRIM(utm_campaign), '') IS NULL
             THEN 1 ELSE 0 END) AS missing_utm_campaign
FROM bronze.fact_web_daily_raw;


/* 4.3 Find duplicate row IDs
   Expected: zero rows
*/

SELECT
    web_row_id,
    COUNT(*) AS duplicate_count
FROM bronze.fact_web_daily_raw
GROUP BY web_row_id
HAVING COUNT(*) > 1;


/* 4.4 Find exact content duplicates while ignoring
   the technical web_row_id
*/

SELECT
    [date],
    campaign_id,
    channel_raw,
    country,
    city,
    device,
    sessions,
    bounce_rate,
    avg_session_seconds,
    utm_source,
    utm_medium,
    utm_campaign,
    source_system,
    COUNT(*) AS duplicate_count
FROM bronze.fact_web_daily_raw
GROUP BY
    [date],
    campaign_id,
    channel_raw,
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
HAVING COUNT(*) > 1;


/* 4.5 Find duplicate expected business-grain records */

SELECT
    [date],
    campaign_id,
    LOWER(TRIM(channel_raw)) AS normalized_channel,
    country,
    TRIM(city) AS normalized_city,
    device,
    COUNT(*) AS duplicate_count
FROM bronze.fact_web_daily_raw
GROUP BY
    [date],
    campaign_id,
    LOWER(TRIM(channel_raw)),
    country,
    TRIM(city),
    device
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


/* 4.6 Review inconsistent channel names */

SELECT
    channel_raw AS raw_channel,
    LOWER(TRIM(channel_raw)) AS normalized_channel,
    COUNT(*) AS record_count
FROM bronze.fact_web_daily_raw
GROUP BY
    channel_raw,
    LOWER(TRIM(channel_raw))
ORDER BY normalized_channel, raw_channel;


/* 4.7 Review city, country, device, and UTM values */

SELECT city, COUNT(*) AS record_count
FROM bronze.fact_web_daily_raw
GROUP BY city
ORDER BY city;

SELECT country, COUNT(*) AS record_count
FROM bronze.fact_web_daily_raw
GROUP BY country
ORDER BY country;

SELECT device, COUNT(*) AS record_count
FROM bronze.fact_web_daily_raw
GROUP BY device
ORDER BY device;

SELECT utm_source, COUNT(*) AS record_count
FROM bronze.fact_web_daily_raw
GROUP BY utm_source
ORDER BY utm_source;

SELECT utm_medium, COUNT(*) AS record_count
FROM bronze.fact_web_daily_raw
GROUP BY utm_medium
ORDER BY utm_medium;


/* 4.8 Find invalid web metrics
   This assumes bounce_rate is stored from 0 to 1.
*/

SELECT *
FROM bronze.fact_web_daily_raw
WHERE sessions < 0
   OR bounce_rate < 0
   OR bounce_rate > 1
   OR avg_session_seconds < 0;


/* 4.9 Find leading or trailing spaces */

SELECT *
FROM bronze.fact_web_daily_raw
WHERE campaign_id <> TRIM(campaign_id)
   OR channel_raw <> TRIM(channel_raw)
   OR country <> TRIM(country)
   OR city <> TRIM(city)
   OR device <> TRIM(device)
   OR utm_source <> TRIM(utm_source)
   OR utm_medium <> TRIM(utm_medium)
   OR utm_campaign <> TRIM(utm_campaign);


/* 4.10 Find invalid campaign IDs
   Expected: zero rows
*/

SELECT DISTINCT
    f.campaign_id
FROM bronze.fact_web_daily_raw AS f
LEFT JOIN bronze.dim_campaign AS c
    ON f.campaign_id = c.campaign_id
WHERE c.campaign_id IS NULL;


/* 4.11 Find web dates outside campaign dates
   Expected: zero rows
*/

SELECT
    f.web_row_id,
    f.[date],
    f.campaign_id,
    c.start_date,
    c.end_date
FROM bronze.fact_web_daily_raw AS f
INNER JOIN bronze.dim_campaign AS c
    ON f.campaign_id = c.campaign_id
WHERE f.[date] < c.start_date
   OR f.[date] > c.end_date;


/*=========================================================
  5. PROFILE bronze.fact_conversions_raw
=========================================================*/

PRINT '================================================';
PRINT 'PROFILING bronze.fact_conversions_raw';
PRINT '================================================';


/* 5.1 Basic ranges */

SELECT
    COUNT(*) AS total_rows,
    MIN([date]) AS earliest_date,
    MAX([date]) AS latest_date,
    MIN(conversions) AS minimum_conversions,
    MAX(conversions) AS maximum_conversions,
    MIN(revenue) AS minimum_revenue,
    MAX(revenue) AS maximum_revenue
FROM bronze.fact_conversions_raw;


/* 5.2 Count NULL or blank values */

SELECT
    SUM(CASE WHEN conversion_row_id IS NULL
                  OR NULLIF(TRIM(conversion_row_id), '') IS NULL
             THEN 1 ELSE 0 END) AS missing_conversion_row_id,

    SUM(CASE WHEN [date] IS NULL
             THEN 1 ELSE 0 END) AS missing_date,

    SUM(CASE WHEN campaign_id IS NULL
                  OR NULLIF(TRIM(campaign_id), '') IS NULL
             THEN 1 ELSE 0 END) AS missing_campaign_id,

    SUM(CASE WHEN channel_raw IS NULL
                  OR NULLIF(TRIM(channel_raw), '') IS NULL
             THEN 1 ELSE 0 END) AS missing_channel,

    SUM(CASE WHEN conversion_type IS NULL
                  OR NULLIF(TRIM(conversion_type), '') IS NULL
             THEN 1 ELSE 0 END) AS missing_conversion_type,

    SUM(CASE WHEN conversions IS NULL
             THEN 1 ELSE 0 END) AS missing_conversions,

    SUM(CASE WHEN revenue IS NULL
             THEN 1 ELSE 0 END) AS missing_revenue
FROM bronze.fact_conversions_raw;


/* 5.3 Find duplicate row IDs
   Expected: zero rows
*/

SELECT
    conversion_row_id,
    COUNT(*) AS duplicate_count
FROM bronze.fact_conversions_raw
GROUP BY conversion_row_id
HAVING COUNT(*) > 1;


/* 5.4 Find exact content duplicates while ignoring
   the technical conversion_row_id
*/

SELECT
    [date],
    campaign_id,
    channel_raw,
    country,
    city,
    device,
    conversion_type,
    conversions,
    revenue,
    source_system,
    COUNT(*) AS duplicate_count
FROM bronze.fact_conversions_raw
GROUP BY
    [date],
    campaign_id,
    channel_raw,
    country,
    city,
    device,
    conversion_type,
    conversions,
    revenue,
    source_system
HAVING COUNT(*) > 1;


/* 5.5 Find duplicate expected business-grain records */

SELECT
    [date],
    campaign_id,
    LOWER(TRIM(channel_raw)) AS normalized_channel,
    country,
    TRIM(city) AS normalized_city,
    device,
    LOWER(TRIM(conversion_type)) AS normalized_conversion_type,
    COUNT(*) AS duplicate_count
FROM bronze.fact_conversions_raw
GROUP BY
    [date],
    campaign_id,
    LOWER(TRIM(channel_raw)),
    country,
    TRIM(city),
    device,
    LOWER(TRIM(conversion_type))
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


/* 5.6 Review inconsistent channel names */

SELECT
    channel_raw AS raw_channel,
    LOWER(TRIM(channel_raw)) AS normalized_channel,
    COUNT(*) AS record_count
FROM bronze.fact_conversions_raw
GROUP BY
    channel_raw,
    LOWER(TRIM(channel_raw))
ORDER BY normalized_channel, raw_channel;


/* 5.7 Review conversion-type consistency */

SELECT
    conversion_type AS raw_conversion_type,
    LOWER(TRIM(conversion_type)) AS normalized_conversion_type,
    COUNT(*) AS record_count
FROM bronze.fact_conversions_raw
GROUP BY
    conversion_type,
    LOWER(TRIM(conversion_type))
ORDER BY normalized_conversion_type, raw_conversion_type;


/* 5.8 Review city, country, and device values */

SELECT city, COUNT(*) AS record_count
FROM bronze.fact_conversions_raw
GROUP BY city
ORDER BY city;

SELECT country, COUNT(*) AS record_count
FROM bronze.fact_conversions_raw
GROUP BY country
ORDER BY country;

SELECT device, COUNT(*) AS record_count
FROM bronze.fact_conversions_raw
GROUP BY device
ORDER BY device;


/* 5.9 Find invalid conversion metrics */

SELECT *
FROM bronze.fact_conversions_raw
WHERE conversions < 0
   OR revenue < 0
   OR (conversions = 0 AND revenue > 0);


/* 5.10 Find leading or trailing spaces */

SELECT *
FROM bronze.fact_conversions_raw
WHERE campaign_id <> TRIM(campaign_id)
   OR channel_raw <> TRIM(channel_raw)
   OR country <> TRIM(country)
   OR city <> TRIM(city)
   OR device <> TRIM(device)
   OR conversion_type <> TRIM(conversion_type);


/* 5.11 Find invalid campaign IDs
   Expected: zero rows
*/

SELECT DISTINCT
    f.campaign_id
FROM bronze.fact_conversions_raw AS f
LEFT JOIN bronze.dim_campaign AS c
    ON f.campaign_id = c.campaign_id
WHERE c.campaign_id IS NULL;


/* 5.12 Find conversion dates outside campaign dates
   Expected: zero rows
*/

SELECT
    f.conversion_row_id,
    f.[date],
    f.campaign_id,
    c.start_date,
    c.end_date
FROM bronze.fact_conversions_raw AS f
INNER JOIN bronze.dim_campaign AS c
    ON f.campaign_id = c.campaign_id
WHERE f.[date] < c.start_date
   OR f.[date] > c.end_date;


/*=========================================================
  6. PROFILE bronze.campaign_targets
=========================================================*/

PRINT '================================================';
PRINT 'PROFILING bronze.campaign_targets';
PRINT '================================================';


/* 6.1 Preview the data */

SELECT *
FROM bronze.campaign_targets
ORDER BY campaign_id;


/* 6.2 Find NULL values */

SELECT *
FROM bronze.campaign_targets
WHERE campaign_id IS NULL
   OR NULLIF(TRIM(campaign_id), '') IS NULL
   OR target_ctr IS NULL
   OR target_cpc IS NULL
   OR target_cvr IS NULL
   OR target_cpa IS NULL
   OR target_qa_pass_rate IS NULL;


/* 6.3 Find duplicate campaign IDs
   Expected: zero rows
*/

SELECT
    campaign_id,
    COUNT(*) AS duplicate_count
FROM bronze.campaign_targets
GROUP BY campaign_id
HAVING COUNT(*) > 1;


/* 6.4 Find invalid target values
   Rate targets are assumed to use decimal values from 0 to 1.
*/

SELECT *
FROM bronze.campaign_targets
WHERE target_ctr < 0
   OR target_ctr > 1
   OR target_cpc < 0
   OR target_cvr < 0
   OR target_cvr > 1
   OR target_cpa < 0
   OR target_qa_pass_rate < 0
   OR target_qa_pass_rate > 1;


/* 6.5 Find target records with invalid campaign IDs
   Expected: zero rows
*/

SELECT
    t.*
FROM bronze.campaign_targets AS t
LEFT JOIN bronze.dim_campaign AS c
    ON t.campaign_id = c.campaign_id
WHERE c.campaign_id IS NULL;


/* 6.6 Find campaigns that do not have target records */

SELECT
    c.campaign_id,
    c.campaign_name
FROM bronze.dim_campaign AS c
LEFT JOIN bronze.campaign_targets AS t
    ON c.campaign_id = t.campaign_id
WHERE t.campaign_id IS NULL;


/*=========================================================
  7. CROSS-TABLE CHANNEL CONSISTENCY
=========================================================*/

PRINT '================================================';
PRINT 'REVIEWING CHANNEL VALUES ACROSS ALL TABLES';
PRINT '================================================';

WITH all_channels AS
(
    SELECT 'dim_creative' AS source_table, channel AS raw_channel
    FROM bronze.dim_creative

    UNION ALL

    SELECT 'fact_media_daily_raw', channel_raw
    FROM bronze.fact_media_daily_raw

    UNION ALL

    SELECT 'fact_web_daily_raw', channel_raw
    FROM bronze.fact_web_daily_raw

    UNION ALL

    SELECT 'fact_conversions_raw', channel_raw
    FROM bronze.fact_conversions_raw
)
SELECT
    source_table,
    raw_channel,
    LOWER(TRIM(raw_channel)) AS normalized_channel,
    COUNT(*) AS record_count
FROM all_channels
GROUP BY
    source_table,
    raw_channel,
    LOWER(TRIM(raw_channel))
ORDER BY
    normalized_channel,
    source_table,
    raw_channel;
GO


PRINT '================================================';
PRINT 'BRONZE DATA PROFILING COMPLETED';
PRINT 'REVIEW EACH RESULT SET BEFORE BUILDING SILVER';
PRINT '================================================';
GO
