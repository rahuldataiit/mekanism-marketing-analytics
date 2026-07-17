/*=========================================================
  MEKANISM MARKETING ANALYTICS

  POPULATE:
  gold.campaign_target_performance

  GRAIN:
  One row per campaign
=========================================================*/

USE mekanism_marketing_analytics;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
    @start_time    DATETIME2(0) = SYSDATETIME(),
    @end_time      DATETIME2(0),
    @inserted_rows INT;

PRINT '=================================================';
PRINT 'LOADING gold.campaign_target_performance';
PRINT '=================================================';


/*=========================================================
  BEGIN LOAD
=========================================================*/

BEGIN TRY

    BEGIN TRANSACTION;


    /*=====================================================
      1. REMOVE PREVIOUS DATA

      This allows the script to be rerun safely.
    =====================================================*/

    TRUNCATE TABLE gold.campaign_target_performance;


    /*=====================================================
      2. AGGREGATE ACTUAL PERFORMANCE

      gold.campaign_daily_performance contains multiple rows
      per campaign.

      We summarize it to:
      One row per campaign.
    =====================================================*/

    ;WITH campaign_actuals AS
    (
        SELECT
            campaign_id,

            SUM(CAST(impressions AS BIGINT))
                AS total_impressions,

            SUM(CAST(clicks AS BIGINT))
                AS total_clicks,

            SUM(CAST(spend AS DECIMAL(38,2)))
                AS total_spend,

            SUM(CAST(video_views AS BIGINT))
                AS total_video_views,

            SUM(CAST(engagements AS BIGINT))
                AS total_engagements,

            SUM(CAST(sessions AS BIGINT))
                AS total_sessions,

            SUM(CAST(conversions AS BIGINT))
                AS total_conversions,

            SUM(CAST(revenue AS DECIMAL(38,2)))
                AS total_revenue

        FROM gold.campaign_daily_performance

        GROUP BY
            campaign_id
    ),


    /*=====================================================
      3. PREPARE CAMPAIGN TARGETS

      MAX is used to ensure one target record per campaign.
      Silver should normally already contain one row per
      campaign.
    =====================================================*/

    campaign_targets AS
    (
        SELECT
            campaign_id,

            MAX(target_ctr)
                AS target_ctr,

            MAX(target_cpc)
                AS target_cpc,

            MAX(target_cvr)
                AS target_cvr,

            MAX(target_cpa)
                AS target_cpa,

            MAX(target_qa_pass_rate)
                AS target_qa_pass_rate

        FROM silver.campaign_targets

        GROUP BY
            campaign_id
    ),


    /*=====================================================
      4. CALCULATE CAMPAIGN TOTALS AND KPIs
    =====================================================*/

    campaign_metrics AS
    (
        SELECT
            c.campaign_id,

            COALESCE
            (
                NULLIF(TRIM(c.campaign_name), ''),
                'Unknown Campaign'
            ) AS campaign_name,

            COALESCE
            (
                NULLIF(TRIM(c.client_name), ''),
                'Unknown Client'
            ) AS client_name,

            COALESCE
            (
                NULLIF(TRIM(c.objective), ''),
                'Unknown'
            ) AS objective,

            NULLIF(TRIM(c.market), '')
                AS market,

            c.start_date,
            c.end_date,


            /* Inclusive campaign duration */

            CASE
                WHEN c.start_date IS NOT NULL
                 AND c.end_date IS NOT NULL
                 AND c.end_date >= c.start_date
                THEN DATEDIFF
                     (
                         DAY,
                         c.start_date,
                         c.end_date
                     ) + 1
            END AS campaign_duration_days,


            /* Campaign budget */

            c.budget,


            /* Actual totals */

            CAST
            (
                COALESCE(a.total_spend, 0)
                AS DECIMAL(18,2)
            ) AS total_spend,

            CAST
            (
                CASE
                    WHEN c.budget IS NOT NULL
                    THEN c.budget
                         - COALESCE(a.total_spend, 0)
                END
                AS DECIMAL(18,2)
            ) AS remaining_budget,


            /* Budget utilization = Spend / Budget */

            CAST
            (
                CASE
                    WHEN c.budget > 0
                    THEN
                        CAST
                        (
                            COALESCE(a.total_spend, 0)
                            AS DECIMAL(38,10)
                        )
                        /
                        NULLIF
                        (
                            CAST(c.budget AS DECIMAL(38,10)),
                            0
                        )
                END
                AS DECIMAL(18,6)
            ) AS budget_utilization,


            COALESCE(a.total_impressions, 0)
                AS total_impressions,

            COALESCE(a.total_clicks, 0)
                AS total_clicks,

            COALESCE(a.total_video_views, 0)
                AS total_video_views,

            COALESCE(a.total_engagements, 0)
                AS total_engagements,

            COALESCE(a.total_sessions, 0)
                AS total_sessions,

            COALESCE(a.total_conversions, 0)
                AS total_conversions,

            CAST
            (
                COALESCE(a.total_revenue, 0)
                AS DECIMAL(18,2)
            ) AS total_revenue,


            /* CTR = Clicks / Impressions */

            CAST
            (
                CAST
                (
                    a.total_clicks
                    AS DECIMAL(38,10)
                )
                /
                NULLIF
                (
                    CAST
                    (
                        a.total_impressions
                        AS DECIMAL(38,10)
                    ),
                    0
                )
                AS DECIMAL(18,6)
            ) AS actual_ctr,


            /* CPC = Spend / Clicks */

            CAST
            (
                CAST
                (
                    a.total_spend
                    AS DECIMAL(38,10)
                )
                /
                NULLIF
                (
                    CAST
                    (
                        a.total_clicks
                        AS DECIMAL(38,10)
                    ),
                    0
                )
                AS DECIMAL(18,4)
            ) AS actual_cpc,


            /* CPM = Spend / Impressions × 1,000 */

            CAST
            (
                (
                    CAST
                    (
                        a.total_spend
                        AS DECIMAL(38,10)
                    )
                    /
                    NULLIF
                    (
                        CAST
                        (
                            a.total_impressions
                            AS DECIMAL(38,10)
                        ),
                        0
                    )
                ) * 1000
                AS DECIMAL(18,4)
            ) AS actual_cpm,


            /* Session rate = Sessions / Clicks */

            CAST
            (
                CAST
                (
                    a.total_sessions
                    AS DECIMAL(38,10)
                )
                /
                NULLIF
                (
                    CAST
                    (
                        a.total_clicks
                        AS DECIMAL(38,10)
                    ),
                    0
                )
                AS DECIMAL(18,6)
            ) AS actual_session_rate,


            /* CVR = Conversions / Sessions */

            CAST
            (
                CAST
                (
                    a.total_conversions
                    AS DECIMAL(38,10)
                )
                /
                NULLIF
                (
                    CAST
                    (
                        a.total_sessions
                        AS DECIMAL(38,10)
                    ),
                    0
                )
                AS DECIMAL(18,6)
            ) AS actual_cvr,


            /* CPA = Spend / Conversions */

            CAST
            (
                CAST
                (
                    a.total_spend
                    AS DECIMAL(38,10)
                )
                /
                NULLIF
                (
                    CAST
                    (
                        a.total_conversions
                        AS DECIMAL(38,10)
                    ),
                    0
                )
                AS DECIMAL(18,4)
            ) AS actual_cpa,


            /* ROAS = Revenue / Spend */

            CAST
            (
                CAST
                (
                    a.total_revenue
                    AS DECIMAL(38,10)
                )
                /
                NULLIF
                (
                    CAST
                    (
                        a.total_spend
                        AS DECIMAL(38,10)
                    ),
                    0
                )
                AS DECIMAL(18,6)
            ) AS actual_roas,


            /* Engagement rate = Engagements / Impressions */

            CAST
            (
                CAST
                (
                    a.total_engagements
                    AS DECIMAL(38,10)
                )
                /
                NULLIF
                (
                    CAST
                    (
                        a.total_impressions
                        AS DECIMAL(38,10)
                    ),
                    0
                )
                AS DECIMAL(18,6)
            ) AS actual_engagement_rate,


            /* Video-view rate = Video Views / Impressions */

            CAST
            (
                CAST
                (
                    a.total_video_views
                    AS DECIMAL(38,10)
                )
                /
                NULLIF
                (
                    CAST
                    (
                        a.total_impressions
                        AS DECIMAL(38,10)
                    ),
                    0
                )
                AS DECIMAL(18,6)
            ) AS actual_video_view_rate,


            /*
              QA pass rate requires a separate data-quality
              audit calculation. It remains NULL for now.
            */

            CAST(NULL AS DECIMAL(18,6))
                AS actual_qa_pass_rate,


            /* Campaign targets */

            t.target_ctr,
            t.target_cpc,
            t.target_cvr,
            t.target_cpa,
            t.target_qa_pass_rate

        FROM silver.dim_campaign AS c

        LEFT JOIN campaign_actuals AS a
            ON a.campaign_id = c.campaign_id

        LEFT JOIN campaign_targets AS t
            ON t.campaign_id = c.campaign_id
    ),


    /*=====================================================
      5. COMPARE ACTUAL KPIs WITH TARGETS
    =====================================================*/

    campaign_statuses AS
    (
        SELECT
            *,


            /* Higher CTR is better */

            CASE
                WHEN target_ctr IS NULL
                    THEN 'No Target'

                WHEN actual_ctr IS NULL
                    THEN 'No Data'

                WHEN actual_ctr >= target_ctr
                    THEN 'Met'

                ELSE 'Not Met'
            END AS ctr_status,


            /* Lower CPC is better */

            CASE
                WHEN target_cpc IS NULL
                    THEN 'No Target'

                WHEN actual_cpc IS NULL
                    THEN 'No Data'

                WHEN actual_cpc <= target_cpc
                    THEN 'Met'

                ELSE 'Not Met'
            END AS cpc_status,


            /* Higher CVR is better */

            CASE
                WHEN target_cvr IS NULL
                    THEN 'No Target'

                WHEN actual_cvr IS NULL
                    THEN 'No Data'

                WHEN actual_cvr >= target_cvr
                    THEN 'Met'

                ELSE 'Not Met'
            END AS cvr_status,


            /* Lower CPA is better */

            CASE
                WHEN target_cpa IS NULL
                    THEN 'No Target'

                WHEN actual_cpa IS NULL
                    THEN 'No Data'

                WHEN actual_cpa <= target_cpa
                    THEN 'Met'

                ELSE 'Not Met'
            END AS cpa_status,


            /* Higher QA pass rate is better */

            CASE
                WHEN target_qa_pass_rate IS NULL
                    THEN 'No Target'

                WHEN actual_qa_pass_rate IS NULL
                    THEN 'No Data'

                WHEN actual_qa_pass_rate
                     >= target_qa_pass_rate
                    THEN 'Met'

                ELSE 'Not Met'
            END AS qa_status

        FROM campaign_metrics
    ),


    /*=====================================================
      6. COUNT TARGETS EVALUATED AND TARGETS MET

      Only Met and Not Met are evaluated.

      No Target and No Data are excluded.
    =====================================================*/

    campaign_scores AS
    (
        SELECT
            *,

            CAST
            (
                CASE
                    WHEN ctr_status IN ('Met', 'Not Met')
                    THEN 1 ELSE 0
                END
                +
                CASE
                    WHEN cpc_status IN ('Met', 'Not Met')
                    THEN 1 ELSE 0
                END
                +
                CASE
                    WHEN cvr_status IN ('Met', 'Not Met')
                    THEN 1 ELSE 0
                END
                +
                CASE
                    WHEN cpa_status IN ('Met', 'Not Met')
                    THEN 1 ELSE 0
                END
                +
                CASE
                    WHEN qa_status IN ('Met', 'Not Met')
                    THEN 1 ELSE 0
                END

                AS TINYINT
            ) AS targets_evaluated,


            CAST
            (
                CASE WHEN ctr_status = 'Met'
                    THEN 1 ELSE 0 END
                +
                CASE WHEN cpc_status = 'Met'
                    THEN 1 ELSE 0 END
                +
                CASE WHEN cvr_status = 'Met'
                    THEN 1 ELSE 0 END
                +
                CASE WHEN cpa_status = 'Met'
                    THEN 1 ELSE 0 END
                +
                CASE WHEN qa_status = 'Met'
                    THEN 1 ELSE 0 END

                AS TINYINT
            ) AS targets_met

        FROM campaign_statuses
    )


    /*=====================================================
      7. INSERT RESULTS INTO GOLD TABLE
    =====================================================*/

    INSERT INTO gold.campaign_target_performance
    (
        campaign_id,
        campaign_name,
        client_name,
        objective,
        market,
        start_date,
        end_date,
        campaign_duration_days,

        budget,
        total_spend,
        remaining_budget,
        budget_utilization,

        total_impressions,
        total_clicks,
        total_video_views,
        total_engagements,
        total_sessions,
        total_conversions,
        total_revenue,

        actual_ctr,
        actual_cpc,
        actual_cpm,
        actual_session_rate,
        actual_cvr,
        actual_cpa,
        actual_roas,
        actual_engagement_rate,
        actual_video_view_rate,
        actual_qa_pass_rate,

        target_ctr,
        target_cpc,
        target_cvr,
        target_cpa,
        target_qa_pass_rate,

        ctr_status,
        cpc_status,
        cvr_status,
        cpa_status,
        qa_status,

        targets_evaluated,
        targets_met,
        target_achievement_rate,
        overall_target_status
    )

    SELECT
        campaign_id,
        campaign_name,
        client_name,
        objective,
        market,
        start_date,
        end_date,
        campaign_duration_days,

        budget,
        total_spend,
        remaining_budget,
        budget_utilization,

        total_impressions,
        total_clicks,
        total_video_views,
        total_engagements,
        total_sessions,
        total_conversions,
        total_revenue,

        actual_ctr,
        actual_cpc,
        actual_cpm,
        actual_session_rate,
        actual_cvr,
        actual_cpa,
        actual_roas,
        actual_engagement_rate,
        actual_video_view_rate,
        actual_qa_pass_rate,

        target_ctr,
        target_cpc,
        target_cvr,
        target_cpa,
        target_qa_pass_rate,

        ctr_status,
        cpc_status,
        cvr_status,
        cpa_status,
        qa_status,

        targets_evaluated,
        targets_met,


        /* Target achievement = Targets Met / Evaluated */

        CAST
        (
            CAST(targets_met AS DECIMAL(18,6))
            /
            NULLIF
            (
                CAST(targets_evaluated AS DECIMAL(18,6)),
                0
            )
            AS DECIMAL(9,6)
        ) AS target_achievement_rate,


        /* Overall campaign target status */

        CASE
            WHEN targets_evaluated = 0
                THEN 'No Targets Available'

            WHEN targets_met = targets_evaluated
                THEN 'All Targets Met'

            WHEN targets_met = 0
                THEN 'No Targets Met'

            ELSE 'Partially Met'
        END AS overall_target_status

    FROM campaign_scores;


    SET @inserted_rows = @@ROWCOUNT;

    COMMIT TRANSACTION;


    /*=====================================================
      8. SUCCESS MESSAGE
    =====================================================*/

    SET @end_time = SYSDATETIME();

    PRINT '=================================================';
    PRINT 'GOLD CAMPAIGN TARGET TABLE LOADED SUCCESSFULLY';

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
    PRINT 'ERROR LOADING CAMPAIGN TARGET PERFORMANCE';

    PRINT 'ERROR NUMBER: '
        + CAST(ERROR_NUMBER() AS NVARCHAR(20));

    PRINT 'ERROR MESSAGE: '
        + ERROR_MESSAGE();

    PRINT 'ERROR LINE: '
        + CAST(ERROR_LINE() AS NVARCHAR(20));

    PRINT '=================================================';

    THROW;

END CATCH;
GO
