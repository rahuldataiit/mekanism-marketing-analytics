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
