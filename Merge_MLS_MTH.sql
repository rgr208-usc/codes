
--MERGING ON DATE RANGE


DROP TABLE IF EXISTS MLS;
CREATE TABLE MLS AS
SELECT
    clip as clip_mls, SUBSTRING(listing_address_zip_code FROM 1 FOR 5) as listing_address_zip_code ,
    listing_status_category_code_standardized,property_type_code_standardized, listing_id, listing_id_standardized,
    TO_DATE(SUBSTRING(close_date_standardized FROM 1 FOR 10), 'YYYY-MM-DD') AS closedate,
    TO_DATE(SUBSTRING(listing_date FROM 1 FOR 10), 'YYYY-MM-DD') AS listing_date,
    TO_DATE(SUBSTRING(original_listing_date FROM 1 FOR 10), 'YYYY-MM-DD') AS orginal_listing_date,
    NULLIF(REGEXP_REPLACE(fips_code, '[^0-9.]+', '', 'g'), '')::numeric AS fips,
    NULLIF(REGEXP_REPLACE(listing_address_zip_code, '[^0-9.]+', '', 'g'), '')::numeric AS zip,
    NULLIF(REGEXP_REPLACE(SUBSTRING(listings.close_date_standardized FROM 1 FOR 4),'[^0-9.]+', '', 'g'), '')::integer as year,
    NULLIF(REGEXP_REPLACE(SUBSTRING(listings.close_date_standardized FROM 6 FOR 2),'[^0-9.]+', '', 'g'), '')::integer as month,
    NULLIF(REGEXP_REPLACE(SUBSTRING(listings.close_date_standardized FROM 9 FOR 2),'[^0-9.]+', '', 'g'), '')::integer as day,
    NULLIF(REGEXP_REPLACE(SUBSTRING(listing_date FROM 1 FOR 4),'[^0-9.]+', '', 'g'), '') as list_year,
    NULLIF(REGEXP_REPLACE(SUBSTRING(listing_date FROM 6 FOR 2),'[^0-9.]+', '', 'g'), '') as list_month,
    NULLIF(REGEXP_REPLACE(close_price, '[^0-9.]+', '', 'g'), '')::numeric AS price,
    NULLIF(REGEXP_REPLACE(current_listing_price, '[^0-9.]+', '', 'g'), '')::numeric AS list_p,
    NULLIF(REGEXP_REPLACE(original_listing_price, '[^0-9.]+', '', 'g'), '')::numeric AS or_list_p,
    NULLIF(REGEXP_REPLACE(price_per_square_foot, '[^0-9.]+', '', 'g'), '')::numeric AS list_ppsf,
    NULLIF(REGEXP_REPLACE(days_on_market_dom_derived, '[^0-9.]+', '', 'g'), '')::numeric AS dom,
    NULLIF(REGEXP_REPLACE(days_on_market_dom_cumulative, '[^0-9.]+', '', 'g'), '')::numeric AS cumdom
    FROM mls.listings
WHERE listing_status_category_code_standardized='S' AND
      --choose the type of property
      (property_type_code_standardized='CN' OR property_type_code_standardized='SF' OR  property_type_code_standardized='TH'   )
;

---------

ALTER TABLE MLS ADD COLUMN id_column SERIAL PRIMARY KEY;

----purging for duplicates (long)

WITH cte AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY clip_mls, listing_date, closedate, list_p, price ORDER BY id_column) as rn
    FROM MLS
)
DELETE FROM MLS
WHERE id_column IN (
    SELECT id_column
    FROM cte
    WHERE rn > 1
);


DROP TABLE IF EXISTS MTG;
CREATE TABLE MTG AS
SELECT clip as clip_mtg,

       ---choice of mortgage_date vs. mortgage_recprding_date

       TO_DATE( TO_CHAR(TO_DATE(mortgage_recording_date, 'YYYYMMDD'), 'YYYY-MM-DD'),'YYYY-MM-DD')  AS mtg_r_date,
       TO_DATE( TO_CHAR(TO_DATE(mortgage_date, 'YYYYMMDD'), 'YYYY-MM-DD'),'YYYY-MM-DD')  AS mtg_date,
       mortgage_type_code, --PURCHASE, REFI, JUNIOR, P,R,J
       mortgage_purpose_code,  --F (First Mortgage), see below
       conforming_loan_indicator,conventional_loan_indicator, refinance_loan_indicator,
       government_sponsored_enterprise_gse_eligible_mortgage_indicator,
        construction_loan_indicator,equity_loan_indicator,fha_loan_indicator,veterans_administration_loan_indicator,
        multifamily_rider_indicator,condominium_rider_indicator,second_home_rider_indicator,
        variable_rate_loan_indicator, fixed_rate_indicator,
            NULLIF(REGEXP_REPLACE(mortgage_amount, '[^0-9.]+', '', 'g'), '') ::numeric AS amount,
            NULLIF(REGEXP_REPLACE(SUBSTRING(mortgage_date FROM 1 FOR 4),'[^0-9.]+', '', 'g'), '')::integer AS year,
            NULLIF(REGEXP_REPLACE(SUBSTRING(mortgage_date FROM 5 FOR 2),'[^0-9.]+', '', 'g'), '')::integer  AS month,
            NULLIF(REGEXP_REPLACE(SUBSTRING(mortgage_date FROM 7 FOR 2),'[^0-9.]+', '', 'g'), '')::integer  AS day,
            NULLIF(REGEXP_REPLACE(mortgage_interest_rate, '[^0-9.]+', '', 'g'), '') ::numeric AS rate
    FROM mortgage.basics
   WHERE property_indicator_code___static IN ('10', '11', '21', '22') AND  mortgage_type_code = 'P'
;


---MERGE-- checked with Mortgage_Recorded_Date

DROP TABLE IF EXISTS MLS_MTG;
CREATE TABLE MLS_MTG AS
SELECT
    m.clip_mls,
    m.fips,
    m.listing_id,
    m.orginal_listing_date,
    m.listing_date,
    m.closedate,
    m.list_p,
    m.list_ppsf,
    m.or_list_p,
    m.dom,
    m.cumdom,
    m.price,
    m.list_p/NULLIF(m.price,0) AS lp_price,


    t.clip_mtg,
    t.mtg_date,
    t.mtg_r_date,
    t.amount AS mortgage,
    t.rate,
    t.amount / NULLIF(m.price, 0) AS ltv,
    t.variable_rate_loan_indicator,
    t.fixed_rate_indicator

FROM
    MLS m
LEFT JOIN
    MTG t
ON
    m.clip_mls = t.clip_mtg
    AND (
        ABS(EXTRACT(EPOCH FROM AGE(m.closedate, t.mtg_date)) / 86400) <= 5
        OR
        ABS(EXTRACT(EPOCH FROM AGE(m.closedate, t.mtg_r_date)) / 86400) <= 5
    )
WHERE  m.clip_mls!='';

----ASSESS THE MERGE

SELECT count(closedate)
FROM MLS_MTG
WHERE mtg_date IS NOT NULL OR mtg_r_date IS NOT NULL
ORDER BY count DESC;


