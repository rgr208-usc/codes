
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
SELECT clip as clipm,
       TO_DATE( TO_CHAR(TO_DATE(mortgage_date, 'YYYYMMDD'), 'YYYY-MM-DD'),'YYYY-MM-DD')  AS mtgdate,
       mortgage_type_code, --PURCHASE, REFI, JUNIOR, P,R,J
       mortgage_purpose_code,  --F (First Mortgage), see below
       conforming_loan_indicator,conventional_loan_indicator, refinance_loan_indicator,
       government_sponsored_enterprise_gse_eligible_mortgage_indicator,
        construction_loan_indicator,equity_loan_indicator,fha_loan_indicator,veterans_administration_loan_indicator,
        multifamily_rider_indicator,condominium_rider_indicator,second_home_rider_indicator,
        variable_rate_loan_indicator, fixed_rate_indicator,
            NULLIF(REGEXP_REPLACE(mortgage.basics.fips_code, '[^0-9.]+', '', 'g'), '') ::numeric AS fips,
            NULLIF(REGEXP_REPLACE(fixed_rate_indicator, '[^0-9.]+', '', 'g'), '') ::numeric AS fix,
            NULLIF(REGEXP_REPLACE(mortgage_amount, '[^0-9.]+', '', 'g'), '') ::numeric AS amount,
            NULLIF(REGEXP_REPLACE(mortgage_interest_rate, '[^0-9.]+', '', 'g'), '') ::numeric AS rate
    FROM mortgage.basics
   WHERE property_indicator_code___static IN ('10', '11', '21', '22') AND  mortgage_type_code = 'P'
;


---MERGE

DROP TABLE IF EXISTS MLS_MTG;
CREATE TABLE MLS_MTG AS
SELECT clip_mls, listing_id,  orginal_listing_date,  listing_date, closedate, mtgdate, price, amount as mortgage, rate,
       amount/ NULLIF(price, 0) as ltv
FROM MLS
LEFT JOIN MTG
ON MLS.clip_mls = MTG.clipm AND
ABS(EXTRACT(EPOCH FROM AGE(MLS.closedate, MTG.mtgdate)) / 86400) <= 5;

----Duplicated issues


SELECT clip_mls, listing_id, closedate, orginal_listing_date, listing_date, price, ltv FROM MLS_MTG

DROP TABLE IF EXISTS TEMP;
CREATE TABLE TEMP AS
SELECT clip_mls, closedate, listing_date, price, COUNT(*) as counta
FROM MLS
GROUP BY clip_mls, closedate, listing_date, price
HAVING COUNT(*) > 1;

SELECT counta, count(*)
FROM TEMP
GROUP BY counta
ORDER BY count DESC;

SELECT COUNT(*) AS total_rows
FROM MLS

