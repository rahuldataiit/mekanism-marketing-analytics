;WITH creative_media_aggregated AS
(
    SELECT
        [date] AS activity_date,
        campaign_id,
        creative_id,

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

        SUM(CAST(spend AS DECIMAL(38,2)))
            AS spend,

        SUM(CAST(video_views AS BIGINT))
            AS video_views,

        SUM(CAST(engagements AS BIGINT))
            AS engagements

    FROM silver.fact_media_daily

    GROUP BY
        [date],
        campaign_id,
        creative_id,

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
)


INSERT INTO gold.creative_performance
(
    date_key,
    campaign_id,
    creative_id,
    creative_name,
    channel,
    [format],
    variant,
    country,
    city,
    device,

    impressions,
    clicks,
    spend,
    video_views,
    engagements,

    actual_ctr,
    actual_cpc,
    actual_cpm,
    engagement_rate,
    video_view_rate
)

SELECT
    d.date_key,

    m.campaign_id,
    m.creative_id,

    COALESCE
    (
        NULLIF(TRIM(c.creative_name), ''),
        'Unknown Creative'
    ) AS creative_name,

    m.channel,

    COALESCE
    (
        NULLIF(TRIM(c.[format]), ''),
        'Unknown'
    ) AS [format],

    COALESCE
    (
        NULLIF(TRIM(c.variant), ''),
        'Unknown'
    ) AS variant,

    m.country,
    m.city,
    m.device,

    m.impressions,
    m.clicks,

    CAST
    (
        m.spend AS DECIMAL(18,2)
    ) AS spend,

    m.video_views,
    m.engagements,


    /* CTR = Clicks / Impressions */

    CAST
    (
        CAST(m.clicks AS DECIMAL(38,10))
        /
        NULLIF
        (
            CAST(m.impressions AS DECIMAL(38,10)),
            0
        )
        AS DECIMAL(18,6)
    ) AS actual_ctr,


    /* CPC = Spend / Clicks */

    CAST
    (
        CAST(m.spend AS DECIMAL(38,10))
        /
        NULLIF
        (
            CAST(m.clicks AS DECIMAL(38,10)),
            0
        )
        AS DECIMAL(18,4)
    ) AS actual_cpc,


    /* CPM = Spend / Impressions × 1,000 */

    CAST
    (
        (
            CAST(m.spend AS DECIMAL(38,10))
            /
            NULLIF
            (
                CAST(m.impressions AS DECIMAL(38,10)),
                0
            )
        ) * 1000

        AS DECIMAL(18,4)
    ) AS actual_cpm,


    /* Engagement Rate = Engagements / Impressions */

    CAST
    (
        CAST(m.engagements AS DECIMAL(38,10))
        /
        NULLIF
        (
            CAST(m.impressions AS DECIMAL(38,10)),
            0
        )
        AS DECIMAL(18,6)
    ) AS engagement_rate,


    /* Video View Rate = Video Views / Impressions */

    CAST
    (
        CAST(m.video_views AS DECIMAL(38,10))
        /
        NULLIF
        (
            CAST(m.impressions AS DECIMAL(38,10)),
            0
        )
        AS DECIMAL(18,6)
    ) AS video_view_rate

FROM creative_media_aggregated AS m

INNER JOIN gold.dim_date AS d
    ON d.calendar_date = m.activity_date

INNER JOIN silver.dim_creative AS c
    ON c.creative_id = m.creative_id;
GO
