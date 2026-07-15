/*=========================================================
  MEKANISM MARKETING ANALYTICS
  BRONZE LAYER DATA LOADING
=========================================================*/

USE mekanism_marketing_analytics;
GO

DECLARE
    @start_time DATETIME2,
    @end_time   DATETIME2,
    @row_count  INT;


/*=========================================================
  1. LOAD bronze.dim_campaign
=========================================================*/

SET @start_time = GETDATE();

PRINT '#################################################';
PRINT 'LOADING TABLE bronze.dim_campaign';
PRINT '#################################################';

BEGIN TRY

    TRUNCATE TABLE bronze.dim_campaign;

    BULK INSERT bronze.dim_campaign
    FROM 'C:\Users\rahul\Downloads\dim_campaign.csv'
    WITH
    (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        CODEPAGE = '65001',
        TABLOCK
    );

    SET @end_time = GETDATE();

    SELECT @row_count = COUNT(*)
    FROM bronze.dim_campaign;

    PRINT 'TABLE bronze.dim_campaign LOADED SUCCESSFULLY';
    PRINT 'LOADING TIME: '
        + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
        + ' seconds';
    PRINT 'TOTAL ROWS LOADED: '
        + CAST(@row_count AS NVARCHAR(20));

END TRY
BEGIN CATCH

    PRINT 'ERROR LOADING TABLE bronze.dim_campaign';
    PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();

END CATCH;

PRINT '';


/*=========================================================
  2. LOAD bronze.dim_creative
=========================================================*/

SET @start_time = GETDATE();

PRINT '#################################################';
PRINT 'LOADING TABLE bronze.dim_creative';
PRINT '#################################################';

BEGIN TRY

    TRUNCATE TABLE bronze.dim_creative;

    BULK INSERT bronze.dim_creative
    FROM 'C:\Users\rahul\Downloads\dim_creative.csv'
    WITH
    (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        CODEPAGE = '65001',
        TABLOCK
    );

    SET @end_time = GETDATE();

    SELECT @row_count = COUNT(*)
    FROM bronze.dim_creative;

    PRINT 'TABLE bronze.dim_creative LOADED SUCCESSFULLY';
    PRINT 'LOADING TIME: '
        + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
        + ' seconds';
    PRINT 'TOTAL ROWS LOADED: '
        + CAST(@row_count AS NVARCHAR(20));

END TRY
BEGIN CATCH

    PRINT 'ERROR LOADING TABLE bronze.dim_creative';
    PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();

END CATCH;

PRINT '';


/*=========================================================
  3. LOAD bronze.fact_media_daily_raw
=========================================================*/

SET @start_time = GETDATE();

PRINT '#################################################';
PRINT 'LOADING TABLE bronze.fact_media_daily_raw';
PRINT '#################################################';

BEGIN TRY

    TRUNCATE TABLE bronze.fact_media_daily_raw;

    BULK INSERT bronze.fact_media_daily_raw
    FROM 'C:\Users\rahul\Downloads\fact_media_daily_raw.csv'
    WITH
    (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        CODEPAGE = '65001',
        TABLOCK
    );

    SET @end_time = GETDATE();

    SELECT @row_count = COUNT(*)
    FROM bronze.fact_media_daily_raw;

    PRINT 'TABLE bronze.fact_media_daily_raw LOADED SUCCESSFULLY';
    PRINT 'LOADING TIME: '
        + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
        + ' seconds';
    PRINT 'TOTAL ROWS LOADED: '
        + CAST(@row_count AS NVARCHAR(20));

END TRY
BEGIN CATCH

    PRINT 'ERROR LOADING TABLE bronze.fact_media_daily_raw';
    PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();

END CATCH;

PRINT '';


/*=========================================================
  4. LOAD bronze.fact_web_daily_raw
=========================================================*/

SET @start_time = GETDATE();

PRINT '#################################################';
PRINT 'LOADING TABLE bronze.fact_web_daily_raw';
PRINT '#################################################';

BEGIN TRY

    TRUNCATE TABLE bronze.fact_web_daily_raw;

    BULK INSERT bronze.fact_web_daily_raw
    FROM 'C:\Users\rahul\Downloads\fact_web_daily_raw.csv'
    WITH
    (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        CODEPAGE = '65001',
        TABLOCK
    );

    SET @end_time = GETDATE();

    SELECT @row_count = COUNT(*)
    FROM bronze.fact_web_daily_raw;

    PRINT 'TABLE bronze.fact_web_daily_raw LOADED SUCCESSFULLY';
    PRINT 'LOADING TIME: '
        + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
        + ' seconds';
    PRINT 'TOTAL ROWS LOADED: '
        + CAST(@row_count AS NVARCHAR(20));

END TRY
BEGIN CATCH

    PRINT 'ERROR LOADING TABLE bronze.fact_web_daily_raw';
    PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();

END CATCH;

PRINT '';


/*=========================================================
  5. LOAD bronze.fact_conversions_raw
=========================================================*/

SET @start_time = GETDATE();

PRINT '#################################################';
PRINT 'LOADING TABLE bronze.fact_conversions_raw';
PRINT '#################################################';

BEGIN TRY

    TRUNCATE TABLE bronze.fact_conversions_raw;

    BULK INSERT bronze.fact_conversions_raw
    FROM 'C:\Users\rahul\Downloads\fact_conversions_raw.csv'
    WITH
    (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        CODEPAGE = '65001',
        TABLOCK
    );

    SET @end_time = GETDATE();

    SELECT @row_count = COUNT(*)
    FROM bronze.fact_conversions_raw;

    PRINT 'TABLE bronze.fact_conversions_raw LOADED SUCCESSFULLY';
    PRINT 'LOADING TIME: '
        + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
        + ' seconds';
    PRINT 'TOTAL ROWS LOADED: '
        + CAST(@row_count AS NVARCHAR(20));

END TRY
BEGIN CATCH

    PRINT 'ERROR LOADING TABLE bronze.fact_conversions_raw';
    PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();

END CATCH;

PRINT '';


/*=========================================================
  6. LOAD bronze.campaign_targets
=========================================================*/

SET @start_time = GETDATE();

PRINT '#################################################';
PRINT 'LOADING TABLE bronze.campaign_targets';
PRINT '#################################################';

BEGIN TRY

    TRUNCATE TABLE bronze.campaign_targets;

    BULK INSERT bronze.campaign_targets
    FROM 'C:\Users\rahul\Downloads\campaign_targets.csv'
    WITH
    (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        CODEPAGE = '65001',
        TABLOCK
    );

    SET @end_time = GETDATE();

    SELECT @row_count = COUNT(*)
    FROM bronze.campaign_targets;

    PRINT 'TABLE bronze.campaign_targets LOADED SUCCESSFULLY';
    PRINT 'LOADING TIME: '
        + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
        + ' seconds';
    PRINT 'TOTAL ROWS LOADED: '
        + CAST(@row_count AS NVARCHAR(20));

END TRY
BEGIN CATCH

    PRINT 'ERROR LOADING TABLE bronze.campaign_targets';
    PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();

END CATCH;

PRINT '';


/*=========================================================
  VERIFY ALL BRONZE TABLE ROW COUNTS
=========================================================*/

SELECT
    'bronze.dim_campaign' AS table_name,
    COUNT(*) AS total_rows
FROM bronze.dim_campaign

UNION ALL

SELECT
    'bronze.dim_creative',
    COUNT(*)
FROM bronze.dim_creative

UNION ALL

SELECT
    'bronze.fact_media_daily_raw',
    COUNT(*)
FROM bronze.fact_media_daily_raw

UNION ALL

SELECT
    'bronze.fact_web_daily_raw',
    COUNT(*)
FROM bronze.fact_web_daily_raw

UNION ALL

SELECT
    'bronze.fact_conversions_raw',
    COUNT(*)
FROM bronze.fact_conversions_raw

UNION ALL

SELECT
    'bronze.campaign_targets',
    COUNT(*)
FROM bronze.campaign_targets;
GO

PRINT '================================================';
PRINT 'BRONZE DATA LOADING PROCESS COMPLETED';
PRINT '================================================';
GO
