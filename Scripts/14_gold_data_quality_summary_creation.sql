/*=========================================================
  MEKANISM MARKETING ANALYTICS

  CREATE TABLE:
  gold.data_quality_summary

  PURPOSE:
  Store Bronze-to-Silver reconciliation,
  issue counts and QA pass rates.
=========================================================*/

USE mekanism_marketing_analytics;
GO

SET NOCOUNT ON;
GO


/*=========================================================
  1. DROP TABLE IF IT ALREADY EXISTS
=========================================================*/

DROP TABLE IF EXISTS gold.data_quality_summary;
GO


/*=========================================================
  2. CREATE DATA-QUALITY SUMMARY TABLE
=========================================================*/

CREATE TABLE gold.data_quality_summary
(
    /* Technical key */

    quality_summary_key BIGINT IDENTITY(1,1) NOT NULL,


    /* Date when the quality check was performed */

    summary_date DATE NOT NULL
        CONSTRAINT DF_gold_dq_summary_date
        DEFAULT CAST(SYSDATETIME() AS DATE),


    /* Dataset-level or campaign-level result */

    summary_level NVARCHAR(20) NOT NULL,


    /* Media, Web, Conversions, Campaigns or All Sources */

    dataset_name NVARCHAR(50) NOT NULL,


    /*
      NULL for overall dataset results.

      Contains campaign ID when summary_level
      is Campaign.
    */

    campaign_id NVARCHAR(7) NULL,


    /* Source-table information */

    bronze_table_name NVARCHAR(128) NULL,

    silver_table_name NVARCHAR(128) NULL,


    /*=====================================================
      ROW-COUNT RECONCILIATION
    =====================================================*/

    bronze_row_count BIGINT NOT NULL
        CONSTRAINT DF_gold_dq_bronze_rows
        DEFAULT 0,

    silver_row_count BIGINT NOT NULL
        CONSTRAINT DF_gold_dq_silver_rows
        DEFAULT 0,

    rows_checked BIGINT NOT NULL
        CONSTRAINT DF_gold_dq_rows_checked
        DEFAULT 0,

    rows_passed BIGINT NOT NULL
        CONSTRAINT DF_gold_dq_rows_passed
        DEFAULT 0,

    rows_failed BIGINT NOT NULL
        CONSTRAINT DF_gold_dq_rows_failed
        DEFAULT 0,


    /*=====================================================
      DATA-QUALITY ISSUE CATEGORIES
    =====================================================*/

    duplicate_rows BIGINT NOT NULL
        CONSTRAINT DF_gold_dq_duplicate_rows
        DEFAULT 0,

    missing_key_rows BIGINT NOT NULL
        CONSTRAINT DF_gold_dq_missing_key_rows
        DEFAULT 0,

    invalid_metric_rows BIGINT NOT NULL
        CONSTRAINT DF_gold_dq_invalid_metric_rows
        DEFAULT 0,

    invalid_date_rows BIGINT NOT NULL
        CONSTRAINT DF_gold_dq_invalid_date_rows
        DEFAULT 0,

    unmatched_campaign_rows BIGINT NOT NULL
        CONSTRAINT DF_gold_dq_unmatched_campaign_rows
        DEFAULT 0,

    unmatched_creative_rows BIGINT NOT NULL
        CONSTRAINT DF_gold_dq_unmatched_creative_rows
        DEFAULT 0,

    consolidated_rows BIGINT NOT NULL
        CONSTRAINT DF_gold_dq_consolidated_rows
        DEFAULT 0,

    other_issue_rows BIGINT NOT NULL
        CONSTRAINT DF_gold_dq_other_issue_rows
        DEFAULT 0,


    /*
      Count of rows having at least one issue.

      Do not calculate this by adding every issue category,
      because one row may have multiple issues.
    */

    total_issue_rows BIGINT NOT NULL
        CONSTRAINT DF_gold_dq_total_issue_rows
        DEFAULT 0,


    /*=====================================================
      DATA-QUALITY RESULT

      Stored as a decimal fraction:

      0.985000 = 98.50%
    =====================================================*/

    qa_pass_rate DECIMAL(9,6) NULL,


    /* Additional explanation */

    quality_status NVARCHAR(20) NULL,

    notes NVARCHAR(500) NULL,


    /* Data lineage */

    load_timestamp DATETIME2(0) NOT NULL
        CONSTRAINT DF_gold_dq_load_timestamp
        DEFAULT SYSDATETIME(),


    /*=====================================================
      PRIMARY KEY
    =====================================================*/

    CONSTRAINT PK_gold_data_quality_summary
        PRIMARY KEY (quality_summary_key),


    /*=====================================================
      VALIDATION RULES
    =====================================================*/

    CONSTRAINT CK_gold_dq_summary_level
        CHECK
        (
            summary_level IN
            (
                'Dataset',
                'Campaign'
            )
        ),


    /*
      Dataset summary should not have campaign_id.

      Campaign summary must have campaign_id.
    */

    CONSTRAINT CK_gold_dq_campaign_level
        CHECK
        (
            (
                summary_level = 'Dataset'
                AND campaign_id IS NULL
            )
            OR
            (
                summary_level = 'Campaign'
                AND campaign_id IS NOT NULL
            )
        ),


    CONSTRAINT CK_gold_dq_bronze_rows
        CHECK (bronze_row_count >= 0),

    CONSTRAINT CK_gold_dq_silver_rows
        CHECK (silver_row_count >= 0),

    CONSTRAINT CK_gold_dq_rows_checked
        CHECK (rows_checked >= 0),

    CONSTRAINT CK_gold_dq_rows_passed
        CHECK (rows_passed >= 0),

    CONSTRAINT CK_gold_dq_rows_failed
        CHECK (rows_failed >= 0),

    CONSTRAINT CK_gold_dq_duplicate_rows
        CHECK (duplicate_rows >= 0),

    CONSTRAINT CK_gold_dq_missing_key_rows
        CHECK (missing_key_rows >= 0),

    CONSTRAINT CK_gold_dq_invalid_metric_rows
        CHECK (invalid_metric_rows >= 0),

    CONSTRAINT CK_gold_dq_invalid_date_rows
        CHECK (invalid_date_rows >= 0),

    CONSTRAINT CK_gold_dq_unmatched_campaign_rows
        CHECK (unmatched_campaign_rows >= 0),

    CONSTRAINT CK_gold_dq_unmatched_creative_rows
        CHECK (unmatched_creative_rows >= 0),

    CONSTRAINT CK_gold_dq_consolidated_rows
        CHECK (consolidated_rows >= 0),

    CONSTRAINT CK_gold_dq_other_issue_rows
        CHECK (other_issue_rows >= 0),

    CONSTRAINT CK_gold_dq_total_issue_rows
        CHECK (total_issue_rows >= 0),


    /* Passed and failed rows cannot exceed checked rows */

    CONSTRAINT CK_gold_dq_passed_checked
        CHECK (rows_passed <= rows_checked),

    CONSTRAINT CK_gold_dq_failed_checked
        CHECK (rows_failed <= rows_checked),


    /* QA rate must be between 0% and 100% */

    CONSTRAINT CK_gold_dq_pass_rate
        CHECK
        (
            qa_pass_rate IS NULL
            OR qa_pass_rate BETWEEN 0 AND 1
        ),


    CONSTRAINT CK_gold_dq_quality_status
        CHECK
        (
            quality_status IS NULL
            OR quality_status IN
            (
                'Passed',
                'Warning',
                'Failed',
                'Not Evaluated'
            )
        )
);
GO


/*=========================================================
  3. CREATE REPORTING INDEX
=========================================================*/

CREATE INDEX IX_gold_data_quality_summary_reporting
ON gold.data_quality_summary
(
    summary_date,
    summary_level,
    dataset_name,
    campaign_id
);
GO


/*=========================================================
  4. SUCCESS MESSAGE
=========================================================*/

PRINT '=================================================';
PRINT 'TABLE gold.data_quality_summary CREATED';
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
  AND TABLE_NAME = 'data_quality_summary'
ORDER BY ORDINAL_POSITION;
GO
