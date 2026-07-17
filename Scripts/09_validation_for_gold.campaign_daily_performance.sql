SELECT
    'Silver Media' AS source,
    SUM(impressions) AS impressions,
    SUM(clicks) AS clicks,
    SUM(spend) AS spend,
    SUM(video_views) AS video_views,
    SUM(engagements) AS engagements
FROM silver.fact_media_daily

UNION ALL

SELECT
    'Gold Campaign Performance',
    SUM(impressions),
    SUM(clicks),
    SUM(spend),
    SUM(video_views),
    SUM(engagements)
FROM gold.campaign_daily_performance;

SELECT
    'Silver Web' AS source,
    SUM(sessions) AS sessions
FROM silver.fact_web_daily

UNION ALL

SELECT
    'Gold Campaign Performance',
    SUM(sessions)
FROM gold.campaign_daily_performance;

SELECT
    'Silver Conversions' AS source,
    SUM(conversions) AS conversions,
    SUM(revenue) AS revenue
FROM silver.fact_conversions

UNION ALL

SELECT
    'Gold Campaign Performance',
    SUM(conversions),
    SUM(revenue)
FROM gold.campaign_daily_performance;

SELECT
    date_key,
    campaign_id,
    channel,
    country,
    city,
    device,
    COUNT(*) AS row_count
FROM gold.campaign_daily_performance
GROUP BY
    date_key,
    campaign_id,
    channel,
    country,
    city,
    device
HAVING COUNT(*) > 1;
