
/*=========================================================
  MEKANISM MARKETING ANALYTICS
  GOLD DATE DIMENSION CREATION AND POPULATION
=========================================================*/

USE mekanism_marketing_analytics;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- Treat Monday as the first day of the week.
SET DATEFIRST 1;

DECLARE
    @minimum_date        DATE,
    @maximum_date        DATE,
    @calendar_start_date DATE,
    @calendar_end_date   DATE,
    @row_count           INT,
    @start_time          DATETIME2,
    @end_time            DATETIME2;

SET @start_time = SYSDATETIME();

PRINT '#################################################';
PRINT 'CREATING AND POPULATING gold.dim_date';
PRINT '#################################################';


/*=========================================================
  1. FIND MINIMUM AND MAXIMUM DATES
=========================================================*/

SELECT
    @minimum_date = MIN(starting_date),
    @maximum_date = MAX(ending_date)
FROM
(
    SELECT
        MIN(start_date) AS starting_date,
        MAX(end_date)   AS ending_date
    FROM silver.dim_campaign

    UNION ALL

    SELECT
        MIN([date]),
        MAX([date])
    FROM silver.fact_media_daily

    UNION ALL

    SELECT
        MIN([date]),
        MAX([date])
    FROM silver.fact_web_daily

    UNION ALL

    SELECT
        MIN([date]),
        MAX([date])
    FROM silver.fact_conversions
) AS date_ranges;


/*=========================================================
  2. STOP IF NO DATES ARE AVAILABLE
=========================================================*/

IF @minimum_date IS NULL OR @maximum_date IS NULL
BEGIN
    THROW 50001,
          'No dates were found in the Silver tables.',
          1;
END;


/*=========================================================
  3. EXTEND THE RANGE TO COMPLETE CALENDAR YEARS
=========================================================*/

SET @calendar_start_date =
    DATEFROMPARTS(YEAR(@minimum_date), 1, 1);

SET @calendar_end_date =
    DATEFROMPARTS(YEAR(@maximum_date), 12, 31);


PRINT 'ACTUAL MINIMUM DATE: '
    + CONVERT(NVARCHAR(10), @minimum_date, 23);

PRINT 'ACTUAL MAXIMUM DATE: '
    + CONVERT(NVARCHAR(10), @maximum_date, 23);

PRINT 'CALENDAR START DATE: '
    + CONVERT(NVARCHAR(10), @calendar_start_date, 23);

PRINT 'CALENDAR END DATE: '
    + CONVERT(NVARCHAR(10), @calendar_end_date, 23);


/*=========================================================
  4. CREATE AND POPULATE THE DATE DIMENSION
=========================================================*/

BEGIN TRY

    BEGIN TRANSACTION;

    DROP TABLE IF EXISTS gold.dim_date;

    CREATE TABLE gold.dim_date
    (
        date_key           INT          NOT NULL,
        calendar_date      DATE         NOT NULL,

        day_number         TINYINT      NOT NULL,
        day_name           NVARCHAR(10) NOT NULL,
        day_of_week_number TINYINT      NOT NULL,
        day_of_year        SMALLINT     NOT NULL,

        iso_week_number    TINYINT      NOT NULL,

        month_number       TINYINT      NOT NULL,
        month_name         NVARCHAR(10) NOT NULL,

        quarter_number     TINYINT      NOT NULL,
        quarter_name       CHAR(2)      NOT NULL,

        year_number        SMALLINT     NOT NULL,
        year_month         CHAR(7)      NOT NULL,

        is_weekend         BIT          NOT NULL,

        CONSTRAINT PK_gold_dim_date
            PRIMARY KEY (date_key),

        CONSTRAINT UQ_gold_dim_date_calendar_date
            UNIQUE (calendar_date)
    );


    /* Generate one row for every calendar date */

    ;WITH date_series AS
    (
        SELECT
            @calendar_start_date AS calendar_date

        UNION ALL

        SELECT
            DATEADD(DAY, 1, calendar_date)
        FROM date_series
        WHERE calendar_date < @calendar_end_date
    )

    INSERT INTO gold.dim_date
    (
        date_key,
        calendar_date,
        day_number,
        day_name,
        day_of_week_number,
        day_of_year,
        iso_week_number,
        month_number,
        month_name,
        quarter_number,
        quarter_name,
        year_number,
        year_month,
        is_weekend
    )

    SELECT
        CONVERT
        (
            INT,
            CONVERT(CHAR(8), calendar_date, 112)
        ) AS date_key,

        calendar_date,

        DAY(calendar_date) AS day_number,

        DATENAME(WEEKDAY, calendar_date) AS day_name,

        DATEPART(WEEKDAY, calendar_date)
            AS day_of_week_number,

        DATEPART(DAYOFYEAR, calendar_date)
            AS day_of_year,

        DATEPART(ISO_WEEK, calendar_date)
            AS iso_week_number,

        MONTH(calendar_date)
            AS month_number,

        DATENAME(MONTH, calendar_date)
            AS month_name,

        DATEPART(QUARTER, calendar_date)
            AS quarter_number,

        CONCAT
        (
            'Q',
            DATEPART(QUARTER, calendar_date)
        ) AS quarter_name,

        YEAR(calendar_date)
            AS year_number,

        CONVERT(CHAR(7), calendar_date, 126)
            AS year_month,

        CASE
            WHEN DATEPART(WEEKDAY, calendar_date) IN (6, 7)
                THEN 1
            ELSE 0
        END AS is_weekend

    FROM date_series

    OPTION (MAXRECURSION 0);


    COMMIT TRANSACTION;


    /*=====================================================
      5. DISPLAY SUCCESS INFORMATION
    =====================================================*/

    SET @end_time = SYSDATETIME();

    SELECT
        @row_count = COUNT(*)
    FROM gold.dim_date;

    PRINT '#################################################';
    PRINT 'TABLE gold.dim_date CREATED SUCCESSFULLY';
    PRINT 'TOTAL ROWS LOADED: '
        + CAST(@row_count AS NVARCHAR(20));

    PRINT 'LOADING TIME: '
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

    PRINT '#################################################';

END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT '#################################################';
    PRINT 'ERROR CREATING gold.dim_date';
    PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();
    PRINT '#################################################';

    THROW;

END CATCH;


/*=========================================================
  6. VERIFY THE DATE DIMENSION
=========================================================*/

SELECT
    COUNT(*)           AS total_dates,
    MIN(calendar_date) AS first_date,
    MAX(calendar_date) AS last_date
FROM gold.dim_date;


SELECT TOP (20)
    *
FROM gold.dim_date
ORDER BY calendar_date;
GO
