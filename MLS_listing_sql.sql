
--This code specifically deal with listing

DROP TABLE IF EXISTS TRANS_LIST
CREATE TABLE TRANS_LIST AS
(SELECT
    clip, fips_code, SUBSTRING(listing_address_zip_code FROM 1 FOR 5) as listing_address_zip_code ,
    listing_status_category_code_standardized,property_type_code_standardized,
    listing_id_standardized, listing_id,
    TO_DATE(SUBSTRING(listing_date FROM 1 FOR 10), 'YYYY-MM-DD') AS listing_date,
    TO_DATE(SUBSTRING(close_date_standardized FROM 1 FOR 10), 'YYYY-MM-DD') AS close_date,
    NULLIF(REGEXP_REPLACE(fips_code, '[^0-9.]+', '', 'g'), '')::numeric AS fips,
    NULLIF(REGEXP_REPLACE(listing_address_zip_code, '[^0-9.]+', '', 'g'), '')::numeric AS zip,
    NULLIF(REGEXP_REPLACE(days_on_market_dom_derived, '[^0-9.]+', '', 'g'), '')::numeric AS dom,
   NULLIF(REGEXP_REPLACE(close_price, '[^0-9.]+', '', 'g'), '')::numeric AS price,
    NULLIF(REGEXP_REPLACE(current_listing_price, '[^0-9.]+', '', 'g'), '')::numeric AS list_p
FROM   mls.listings
WHERE   (property_type_code_standardized='CN' OR property_type_code_standardized='SF' OR  property_type_code_standardized='TH'   )
AND listing_transaction_type_code_derived='S'
);


/*
Listing Category

CdTbl	CdVal	CdDesc
LSTCAT	A  	ACTIVE
LSTCAT	D  	DELETED
LSTCAT	S  	SOLD
LSTCAT	U  	PENDING
LSTCAT	X  	EXPIRED (INCLUDES WITHDRAWN, CANCELLED, TERMINATED, INACTIVE, ETC.)
*/
---- Suppress the duplicates -- by clip listing date close date

ALTER TABLE TRANS_LIST ADD COLUMN id SERIAL PRIMARY KEY;

----DUPLICATES PURGE FOR TRANSACTIONS - same as in MLS----

WITH cte AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY clip, listing_status_category_code_standardized,listing_date, close_date, list_p, price ORDER BY id) as rn
    FROM TRANS_LIST
    WHERE listing_status_category_code_standardized='S'
)
DELETE FROM TRANS_LIST
WHERE id IN (
    SELECT id
    FROM cte
    WHERE rn > 1
);

---DUPLICATE PURGE FOR NON SALES

WITH cte AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY clip, listing_status_category_code_standardized,listing_date, list_p ORDER BY id) as rn
    FROM TRANS_LIST
    WHERE listing_status_category_code_standardized !='S'
)
DELETE FROM TRANS_LIST
WHERE id IN (
    SELECT id
    FROM cte
    WHERE rn > 1
);


--create an active listing data range using listing dates and dom

DROP TABLE IF EXISTS ACTIVE;
CREATE TABLE ACTIVE AS
SELECT clip, fips_code, listing_status_category_code_standardized, listing_address_zip_code, dom, listing_date,
   (listing_date + (dom || ' days')::INTERVAL)::DATE AS end_listing_date,
   EXTRACT(MONTH FROM (listing_date + (dom || ' days')::INTERVAL)::DATE) AS month_exp,
   EXTRACT(YEAR FROM (listing_date + (dom || ' days')::INTERVAL)::DATE) AS year_exp,
       daterange(
        listing_date,
        (listing_date + (dom || ' days')::INTERVAL)::DATE,
        '[]'
    ) AS active_date_range
FROM TRANS_LIST
    ---make sure open ended range correspond to active listing not missing dom
WHERE dom IS NOT NULL AND listing_address_zip_code!='' AND listing_date BETWEEN '2000-01-01' AND '2024-12-31';

---------Ger

DROP TABLE IF EXISTS zip_expired_listing;
CREATE TABLE zip_expired_listing AS
SELECT  listing_address_zip_code, year_exp, month_exp,
         CAST(COUNT(CASE WHEN  listing_status_category_code_standardized = 'X' THEN 1 END) AS INTEGER) AS exp_no_sales_listing,
         CAST(COUNT(CASE WHEN  listing_status_category_code_standardized = 'S' THEN 1 END) AS INTEGER) AS exp_sales_listing
FROM ACTIVE
    WHERE listing_address_zip_code!=''
    GROUP BY listing_address_zip_code, year_exp, month_exp
    ORDER BY listing_address_zip_code, year_exp, month_exp ;



---check if you can go to 2024
  DO $$
DECLARE
    start_year INTEGER := 2010;  -- Change this to your desired starting year
    end_year INTEGER := 2024;    -- Change this to your desired ending year
    month INTEGER;
    year INTEGER;
    last_day DATE;
    start_date DATE;
BEGIN
    -- Create indexes to optimize query performance
    CREATE INDEX IF NOT EXISTS idx_active_date_range
    ON active
    USING GIST (active_date_range);

    CREATE INDEX IF NOT EXISTS idx_listing_address_zip_code
    ON active (listing_address_zip_code);

    FOR year IN start_year..end_year LOOP
        FOR month IN 1..12 LOOP
            -- Calculate the start date and last day of the month for the current year and month
            start_date := DATE (year || '-' || lpad(month::text, 2, '0') || '-01');
            last_day := (start_date + INTERVAL '1 month') - INTERVAL '1 day';

            EXECUTE format('
                DROP TABLE IF EXISTS zip_mls_%s_%s;

                CREATE TABLE zip_mls_%s_%s AS
                SELECT
                    listing_address_zip_code,
                    %s AS year,
                    %s AS month,
                    CAST(COUNT(clip) AS INTEGER) AS active_listing
                FROM
                    (
                        SELECT *,
                            active_date_range && daterange(''%s'', ''%s'', ''[]'') AS overlap_check
                        FROM active
                    ) AS subquery
                WHERE
                    subquery.overlap_check
                GROUP BY
                    listing_address_zip_code
                ORDER BY
                    listing_address_zip_code;
            ', year, month, year, month, year, month,
            to_char(start_date, 'YYYY-MM-DD'),
            to_char(last_day, 'YYYY-MM-DD'));
        END LOOP;
    END LOOP;
END $$;


-- Merge active and expired listing

   DROP TABLE IF EXISTS zip_listing;
   CREATE TABLE zip_listing AS
       SELECT
      m.listing_address_zip_code,
       m.month_exp as month,
       m.year_exp as year,
       m.exp_no_sales_listing,
       m.exp_sales_listing,
       t.active_listing

        FROM zip_expired_listing m
        LEFT JOIN  zip_active_listing t
   ON m.listing_address_zip_code=t.listing_address_zip_code
   AND m.month_exp=t.month
   AND m.year_exp=t.year;



---CLEANING--- DROP ALL INTERIM TABLE

DO $$
DECLARE
    year INT;
    month INT;
    table_name TEXT;
BEGIN
    -- Iterate over each year and month to drop the tables
    FOR year IN 2010..2024 LOOP
        FOR month IN 1..12 LOOP
            table_name := 'zip_mls_' || year || '_' || month;
            EXECUTE 'DROP TABLE IF EXISTS ' || table_name;
        END LOOP;
    END LOOP;
END $$;
