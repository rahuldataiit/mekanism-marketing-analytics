# Mekanism Marketing Analytics

An end-to-end media and marketing analytics project built using **SQL Server** and **Power BI**.

The project demonstrates how raw campaign, advertising, website, and conversion data can be transformed into a trusted reporting layer for campaign performance analysis, budget monitoring, data-quality validation, and optimization recommendations.

> **Note:** This is an independent portfolio and practice project. It is not affiliated with or endorsed by Mekanism.

---

## Project Overview

In this project, I work as a Data Analyst supporting a media agency managing six client campaigns across:

- Paid Search
- Paid Social
- Programmatic Display
- Online Video
- Organic Social

The primary objective is to create a reliable SQL reporting layer and an interactive Power BI dashboard that helps stakeholders understand:

- Campaign performance
- Budget utilization and pacing
- Channel and creative effectiveness
- Website engagement
- Conversion and revenue performance
- Data-quality and tracking issues
- Optimization opportunities

---

## Business Stakeholders

The reporting solution is designed for:

- Media strategists
- Account managers
- Analytics leads
- Client marketing teams
- Campaign managers

---

## Tools and Technologies

- SQL Server
- SQL Server Management Studio
- Power BI Desktop
- Power Query
- DAX
- Microsoft Excel
- Git and GitHub

---

## Data Architecture

The project follows a **Bronze–Silver–Gold medallion architecture**.

### Bronze Layer

The Bronze layer stores the source data in its original form.

It allows data-quality issues to remain available for investigation, including:

- Duplicate records
- Missing UTM parameters
- Inconsistent channel labels
- Blank and missing values
- Leading or trailing spaces
- Negative media spend
- Clicks greater than impressions
- Cross-source reporting mismatches

### Silver Layer

The Silver layer contains cleaned and standardized data.

Planned transformations include:

- Standardizing channel names
- Trimming text fields
- Converting blank values to `NULL`
- Removing business-level duplicates
- Validating metric relationships
- Flagging invalid values
- Standardizing geography, device, and campaign fields
- Aggregating web and conversion data to a consistent reporting grain

### Gold Layer

The Gold layer contains business-ready tables and reporting views used by Power BI.

It will provide:

- Campaign-level reporting
- Channel performance
- Creative performance
- Web and conversion funnel analysis
- KPI target comparisons
- Budget pacing
- Data-quality metrics

---

## Source Tables

| Table | Description |
|---|---|
| `dim_campaign` | Campaign name, client, objective, dates, budget, and market |
| `dim_creative` | Creative, format, channel, campaign, and variant information |
| `fact_media_daily_raw` | Daily impressions, clicks, spend, engagements, and video views |
| `fact_web_daily_raw` | Daily website sessions, bounce rate, and session duration |
| `fact_conversions_raw` | Daily conversions and attributed revenue |
| `campaign_targets` | Campaign-level KPI targets and benchmarks |

The original workbook contains approximately:

- 6 campaigns
- 60 creatives
- 5,000 media-performance records
- 5,000 website-performance records
- 2,300 conversion records

---

## Database Structure

```text
mekanism_marketing_analytics
│
├── bronze
│   ├── dim_campaign
│   ├── dim_creative
│   ├── fact_media_daily_raw
│   ├── fact_web_daily_raw
│   ├── fact_conversions_raw
│   └── campaign_targets
│
├── silver
│   ├── dim_campaign
│   ├── dim_creative
│   ├── fact_media_daily
│   ├── fact_web_daily
│   └── fact_conversions
│
└── gold
    ├── dim_date
    ├── campaign_performance
    ├── channel_performance
    ├── creative_performance
    ├── funnel_performance
    └── data_quality_summary
