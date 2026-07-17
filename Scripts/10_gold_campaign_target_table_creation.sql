/*=========================================================
  MEKANISM MARKETING ANALYTICS

  CREATE:
  gold.campaign_target_performance

  GRAIN:
  One row per campaign
=========================================================*/

USE mekanism_marketing_analytics;
GO

SET NOCOUNT ON;
GO


/*=========================================================
  1. DROP THE TABLE IF IT ALREADY EXISTS
=========================================================*/

DROP TABLE IF EXISTS gold.campaign_target_performance;
GO


/*=========================================================
  2. CREATE THE CAMPAIGN TARGET PERFORMANCE TABLE
=========================================================*/

CREATE TABLE gold.campaign_target_performance
(
    /*=====================================================
      CAMPAIGN IDENTIFICATION
    =====================================================*/

    campaign_id          NVARCHAR(7)   NOT NULL,
    campaign_name        NVARCHAR(100) NOT NULL,
    client_name          NVARCHAR(100) NOT NULL,
    objective            NVARCHAR(50)  NOT NULL,
    market               NVARCHAR(50)  NULL,

    start_date           DATE          NULL,
    end_date             DATE          NULL,

    campaign_duration_days INT         NULL,


    /*=====================================================
      CAMPAIGN BUDGET
    =====================================================*/

    budget               DECIMAL(18,2) NULL,

    total_spend          DECIMAL(18,2) NOT NULL
        CONSTRAINT DF_gold_target_total_spend
        DEFAULT 0,

    remaining_budget     DECIMAL(18,2) NULL,

    budget_utilization   DECIMAL(18,6) NULL,


    /*=====================================================
      ACTUAL CAMPAIGN TOTALS
    =====================================================*/

    total_impressions    BIGINT NOT NULL
        CONSTRAINT DF_gold_target_impressions
        DEFAULT 0,

    total_clicks         BIGINT NOT NULL
        CONSTRAINT DF_gold_target_clicks
        DEFAULT 0,

    total_video_views    BIGINT NOT NULL
        CONSTRAINT DF_gold_target_video_views
        DEFAULT 0,

    total_engagements    BIGINT NOT NULL
        CONSTRAINT DF_gold_target_engagements
        DEFAULT 0,

    total_sessions       BIGINT NOT NULL
        CONSTRAINT DF_gold_target_sessions
        DEFAULT 0,

    total_conversions    BIGINT NOT NULL
        CONSTRAINT DF_gold_target_conversions
        DEFAULT 0,

    total_revenue        DECIMAL(18,2) NOT NULL
        CONSTRAINT DF_gold_target_revenue
        DEFAULT 0,


    /*=====================================================
      ACTUAL CALCULATED KPIs
    =====================================================*/

    actual_ctr           DECIMAL(18,6) NULL,

    actual_cpc           DECIMAL(18,4) NULL,

    actual_cpm           DECIMAL(18,4) NULL,

    actual_session_rate  DECIMAL(18,6) NULL,

    actual_cvr           DECIMAL(18,6) NULL,

    actual_cpa           DECIMAL(18,4) NULL,

    actual_roas          DECIMAL(18,6) NULL,

    actual_engagement_rate
                          DECIMAL(18,6) NULL,

    actual_video_view_rate
                          DECIMAL(18,6) NULL,

    actual_qa_pass_rate  DECIMAL(18,6) NULL,


    /*=====================================================
      CAMPAIGN KPI TARGETS
    =====================================================*/

    target_ctr           DECIMAL(9,6)  NULL,

    target_cpc           DECIMAL(12,2) NULL,

    target_cvr           DECIMAL(9,6)  NULL,

    target_cpa           DECIMAL(12,2) NULL,

    target_qa_pass_rate  DECIMAL(9,6)  NULL,


    /*=====================================================
      ACTUAL-VERSUS-TARGET STATUS
    =====================================================*/

    ctr_status           NVARCHAR(20) NULL,

    cpc_status           NVARCHAR(20) NULL,

    cvr_status           NVARCHAR(20) NULL,

    cpa_status           NVARCHAR(20) NULL,

    qa_status            NVARCHAR(20) NULL,


    /*=====================================================
      OVERALL TARGET PERFORMANCE
    =====================================================*/

    targets_evaluated    TINYINT NULL,

    targets_met          TINYINT NULL,

    target_achievement_rate
                          DECIMAL(9,6) NULL,

    overall_target_status
                          NVARCHAR(30) NULL,


    /*=====================================================
      DATA LINEAGE
    =====================================================*/

    load_timestamp       DATETIME2(0) NOT NULL
        CONSTRAINT DF_gold_campaign_target_load_timestamp
        DEFAULT SYSDATETIME(),


    /*=====================================================
      PRIMARY KEY
    =====================================================*/

    CONSTRAINT PK_gold_campaign_target_performance
        PRIMARY KEY (campaign_id),


    /*=====================================================
      DATA-QUALITY CHECKS
    =====================================================*/

    CONSTRAINT CK_gold_target_campaign_dates
        CHECK
        (
            start_date IS NULL
            OR end_date IS NULL
            OR end_date >= start_date
        ),

    CONSTRAINT CK_gold_target_campaign_duration
        CHECK
        (
            campaign_duration_days IS NULL
            OR campaign_duration_days >= 0
        ),

    CONSTRAINT CK_gold_target_budget
        CHECK
        (
            budget IS NULL
            OR budget >= 0
        ),

    CONSTRAINT CK_gold_target_total_spend
        CHECK (total_spend >= 0),

    CONSTRAINT CK_gold_target_impressions
        CHECK (total_impressions >= 0),

    CONSTRAINT CK_gold_target_clicks
        CHECK (total_clicks >= 0),

    CONSTRAINT CK_gold_target_video_views
        CHECK (total_video_views >= 0),

    CONSTRAINT CK_gold_target_engagements
        CHECK (total_engagements >= 0),

    CONSTRAINT CK_gold_target_sessions
        CHECK (total_sessions >= 0),

    CONSTRAINT CK_gold_target_conversions
        CHECK (total_conversions >= 0),

    CONSTRAINT CK_gold_target_revenue
        CHECK (total_revenue >= 0),

    CONSTRAINT CK_gold_target_clicks_impressions
        CHECK (total_clicks <= total_impressions),

    CONSTRAINT CK_gold_target_actual_ctr
        CHECK
        (
            actual_ctr IS NULL
            OR actual_ctr BETWEEN 0 AND 1
        ),

    CONSTRAINT CK_gold_target_actual_cpc
        CHECK
        (
            actual_cpc IS NULL
            OR actual_cpc >= 0
        ),

    CONSTRAINT CK_gold_target_actual_cpm
        CHECK
        (
            actual_cpm IS NULL
            OR actual_cpm >= 0
        ),

    CONSTRAINT CK_gold_target_actual_session_rate
        CHECK
        (
            actual_session_rate IS NULL
            OR actual_session_rate >= 0
        ),

    CONSTRAINT CK_gold_target_actual_cvr
        CHECK
        (
            actual_cvr IS NULL
            OR actual_cvr >= 0
        ),

    CONSTRAINT CK_gold_target_actual_cpa
        CHECK
        (
            actual_cpa IS NULL
            OR actual_cpa >= 0
        ),

    CONSTRAINT CK_gold_target_actual_roas
        CHECK
        (
            actual_roas IS NULL
            OR actual_roas >= 0
        ),

    CONSTRAINT CK_gold_target_actual_qa
        CHECK
        (
            actual_qa_pass_rate IS NULL
            OR actual_qa_pass_rate BETWEEN 0 AND 1
        ),

    CONSTRAINT CK_gold_target_achievement_rate
        CHECK
        (
            target_achievement_rate IS NULL
            OR target_achievement_rate BETWEEN 0 AND 1
        ),

    CONSTRAINT CK_gold_target_counts
        CHECK
        (
            targets_evaluated IS NULL
            OR targets_met IS NULL
            OR targets_met <= targets_evaluated
        ),

    CONSTRAINT CK_gold_target_ctr_status
        CHECK
        (
            ctr_status IS NULL
            OR ctr_status IN
            (
                'Met',
                'Not Met',
                'No Target',
                'No Data'
            )
        ),

    CONSTRAINT CK_gold_target_cpc_status
        CHECK
        (
            cpc_status IS NULL
            OR cpc_status IN
            (
                'Met',
                'Not Met',
                'No Target',
                'No Data'
            )
        ),

    CONSTRAINT CK_gold_target_cvr_status
        CHECK
        (
            cvr_status IS NULL
            OR cvr_status IN
            (
                'Met',
                'Not Met',
                'No Target',
                'No Data'
            )
        ),

    CONSTRAINT CK_gold_target_cpa_status
        CHECK
        (
            cpa_status IS NULL
            OR cpa_status IN
            (
                'Met',
                'Not Met',
                'No Target',
                'No Data'
            )
        ),

    CONSTRAINT CK_gold_target_qa_status
        CHECK
        (
            qa_status IS NULL
            OR qa_status IN
            (
                'Met',
                'Not Met',
                'No Target',
                'No Data'
            )
        ),

    CONSTRAINT CK_gold_overall_target_status
        CHECK
        (
            overall_target_status IS NULL
            OR overall_target_status IN
            (
                'All Targets Met',
                'Partially Met',
                'No Targets Met',
                'No Targets Available'
            )
        )
);
GO


/*=========================================================
  3. SUCCESS MESSAGE
=========================================================*/

PRINT '=================================================';
PRINT 'TABLE gold.campaign_target_performance CREATED';
PRINT 'GRAIN: ONE ROW PER CAMPAIGN';
PRINT '=================================================';
GO


/*=========================================================
  4. VERIFY THE TABLE STRUCTURE
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
  AND TABLE_NAME = 'campaign_target_performance'
ORDER BY ORDINAL_POSITION;
GO
