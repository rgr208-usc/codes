
---Transactions and Listing----
-------

-- LA (fips_code='06037' OR fips_code='06059' OR  fips_code='06065' OR  fips_code='06071'  OR fips_code='06111'));
DROP TABLE IF EXISTS MLS;
CREATE TABLE MLS AS
(SELECT
    clip, fips_code, SUBSTRING(listing_address_zip_code FROM 1 FOR 5) as  zip_code ,
     NULLIF(REGEXP_REPLACE(SUBSTRING(listing_address_zip_code FROM 1 FOR 5), '[^0-9.]+', '', 'g'), '')::numeric AS zip_num,
    listing_status_category_code_standardized,property_type_code_standardized,
    listing_id_standardized, listing_id,
    TO_DATE(SUBSTRING(close_date_standardized FROM 1 FOR 10), 'YYYY-MM-DD') AS close_date,
    TO_DATE(SUBSTRING(listing_date FROM 1 FOR 10), 'YYYY-MM-DD') AS listing_date,
    TO_DATE(SUBSTRING(original_listing_date FROM 1 FOR 10), 'YYYY-MM-DD') AS orginal_listing_date,
    NULLIF(REGEXP_REPLACE(fips_code, '[^0-9.]+', '', 'g'), '')::numeric AS fips,
    NULLIF(REGEXP_REPLACE(SUBSTRING(close_date_standardized FROM 1 FOR 4),'[^0-9.]+', '', 'g'), '')::integer as year,
    NULLIF(REGEXP_REPLACE(SUBSTRING(close_date_standardized FROM 6 FOR 2),'[^0-9.]+', '', 'g'), '')::integer as month,
    NULLIF(REGEXP_REPLACE(SUBSTRING(close_date_standardized FROM 9 FOR 2),'[^0-9.]+', '', 'g'), '')::integer as day,
    NULLIF(REGEXP_REPLACE(SUBSTRING(listing_date FROM 1 FOR 4),'[^0-9.]+', '', 'g'), '') as list_year,
    NULLIF(REGEXP_REPLACE(SUBSTRING(listing_date FROM 6 FOR 2),'[^0-9.]+', '', 'g'), '') as list_month,
    NULLIF(REGEXP_REPLACE(close_price, '[^0-9.]+', '', 'g'), '')::numeric AS price,
    NULLIF(REGEXP_REPLACE(current_listing_price, '[^0-9.]+', '', 'g'), '')::numeric AS list_p,
    NULLIF(REGEXP_REPLACE(original_listing_price, '[^0-9.]+', '', 'g'), '')::numeric AS or_list_p,
    NULLIF(REGEXP_REPLACE(price_per_square_foot, '[^0-9.]+', '', 'g'), '')::numeric AS list_ppsf,
    NULLIF(REGEXP_REPLACE(days_on_market_dom_derived, '[^0-9.]+', '', 'g'), '')::numeric AS dom,
    NULLIF(REGEXP_REPLACE(days_on_market_dom_cumulative, '[^0-9.]+', '', 'g'), '')::numeric AS cumdom
FROM   mls.listings
--Here we focus on transaction-separate file we focus on listing
WHERE  listing_transaction_type_code_derived='S'
AND    (property_type_code_standardized='CN' OR property_type_code_standardized='SF' OR  property_type_code_standardized='TH'   )
AND listing_address_zip_code !=''
);


/*
LISTING STATUS CATEGORY CODE STANDARDIZED	AlphaNumeric	LSTCAT

Listing Category

CdTbl	CdVal	CdDesc
LSTCAT	A  	ACTIVE
LSTCAT	D  	DELETED
LSTCAT	S  	SOLD
LSTCAT	U  	PENDING
LSTCAT	X  	EXPIRED (INCLUDES WITHDRAWN, CANCELLED, TERMINATED, INACTIVE, ETC.)

LISTING TRANSACTION TYPE CODE DERIVED

CdTbl	CdVal	CdDesc
RENTSL	S	Sale
RENTSL	R	Rental


*/
---- Suppress the duplicates -- by clip listing date close date
ALTER TABLE MLS ADD COLUMN id SERIAL PRIMARY KEY;
--------add an unique id
WITH cte AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY clip, listing_status_category_code_standardized,listing_date, close_date, list_p, price ORDER BY id) as rn
    FROM MLS
    WHERE listing_status_category_code_standardized='S'
)
DELETE FROM MLS
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
    FROM MLS
    WHERE listing_status_category_code_standardized !='S'
)
DELETE FROM MLS
WHERE id IN (
    SELECT id
    FROM cte
    WHERE rn > 1
);

----ADD A

DROP TABLE IF EXISTS zip_mls;
CREATE TABLE zip_mls AS
(
    SELECT
        zip_code,
        year,
        month,
        CAST(COUNT(CASE WHEN  listing_status_category_code_standardized = 'S' THEN 1 END) AS INTEGER) AS transaction,
        AVG(fips)  AS fips,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY price) AS price_50,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY list_p) AS list_p_50,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY or_list_p) AS or_list_p_50,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY price * list_ppsf / NULLIF(list_p, 0)) AS ppsf_50,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY list_p/ NULLIF(list_p, 0)) AS l_to_p_50,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY or_list_p/ NULLIF(list_p, 0)) AS orl_to_p_50,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY dom) AS dom_50,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY cumdom) AS cumdom_50,

        percentile_cont(0.25) WITHIN GROUP (ORDER BY price) AS price_25,
        percentile_cont(0.25) WITHIN GROUP (ORDER BY list_p) AS list_p_25,
        percentile_cont(0.25) WITHIN GROUP (ORDER BY or_list_p) AS or_list_25,
        percentile_cont(0.25) WITHIN GROUP (ORDER BY price * list_ppsf / NULLIF(list_p, 0)) AS ppsf_25,
        percentile_cont(0.25) WITHIN GROUP (ORDER BY list_p/ NULLIF(list_p, 0)) AS l_to_p_25,
        percentile_cont(0.25) WITHIN GROUP (ORDER BY or_list_p/ NULLIF(list_p, 0)) AS orl_to_p_25,
        percentile_cont(0.25) WITHIN GROUP (ORDER BY dom) AS dom_25,
        percentile_cont(0.25) WITHIN GROUP (ORDER BY cumdom) AS cumdom_25,


        percentile_cont(0.75) WITHIN GROUP (ORDER BY price) AS price_75,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY list_p) AS list_p_75,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY or_list_p) AS or_list_75,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY price * list_ppsf / NULLIF(list_p, 0)) AS ppsf_75,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY list_p/ NULLIF(list_p, 0)) AS l_to_p_75,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY or_list_p/ NULLIF(list_p, 0)) AS orl_to_p_75,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY dom) AS dom_75,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY cumdom) AS cumdom_75

    FROM
        MLS
    WHERE listing_status_category_code_standardized='S' AND zip_num>90000 AND zip_num<100000 AND zip_num IS NOT NULL
    GROUP BY
        zip_code,
        year,
        month
    ORDER BY
        zip_code,
        year,
        month
);


--LISTING PART

--EXPIRED LISTING #

DROP TABLE IF EXISTS listing_expired;
CREATE TABLE listing_expired AS
    SELECT clip, zip_code, zip_num, listing_date, dom,  listing_status_category_code_standardized,
    (listing_date + (dom || ' days')::INTERVAL)::DATE AS expired_date,
    EXTRACT(MONTH FROM (listing_date + (dom || ' days')::INTERVAL)::DATE) AS month,
   EXTRACT(YEAR FROM (listing_date + (dom || ' days')::INTERVAL)::DATE) AS year
   FROM MLS
WHERE dom IS NOT NULL AND listing_status_category_code_standardized='X' AND zip_num>90000 AND zip_num<100000 AND zip_num IS NOT NULL

--zip collapse---
DROP TABLE IF EXISTS zip_expired_listing;
    CREATE TABLE zip_expired_listing AS
        SELECT zip_code, month, year,
               CAST(COUNT(CASE WHEN  listing_status_category_code_standardized = 'X' THEN 1 END) AS INTEGER) AS listing_exp
        FROM listing_expired
GROUP BY zip_code, year, month
ORDER BY zip_code, year, month
;



--ACTIVE LISTING

DROP TABLE IF EXISTS ACTIVE;
CREATE TABLE ACTIVE AS
SELECT clip, fips_code, listing_status_category_code_standardized, zip_code, zip_num, dom, listing_date, close_date,
       daterange(
        listing_date,
        (listing_date + (dom || ' days')::INTERVAL)::DATE,
        '[]'
    ) AS active_date_range
FROM MLS
    ---make sure open ended range correspond to active listing not missing dom
WHERE dom IS NOT NULL AND zip_num>90000 AND zip_num<100000 AND zip_num IS NOT NULL;

---------Ger

---check if you can go to 2024
  DO $$
DECLARE
    start_year INTEGER := 2000;  -- Change this to your desired starting year
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

    CREATE INDEX IF NOT EXISTS idx_zip_code
    ON active (zip_code);

    FOR year IN start_year..end_year LOOP
        FOR month IN 1..12 LOOP
            -- Calculate the start date and last day of the month for the current year and month
            start_date := DATE (year || '-' || lpad(month::text, 2, '0') || '-01');
            last_day := (start_date + INTERVAL '1 month') - INTERVAL '1 day';

            EXECUTE format('
                DROP TABLE IF EXISTS zip_mls_%s_%s;

                CREATE TABLE zip_mls_%s_%s AS
                SELECT
                    zip_code,
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
                    zip_code
                ORDER BY
               zip_code;
            ', year, month, year, month, year, month,
            to_char(start_date, 'YYYY-MM-DD'),
            to_char(last_day, 'YYYY-MM-DD'));
        END LOOP;
    END LOOP;
END $$;


DROP TABLE IF EXISTS zip_listing;
    DO $$
DECLARE
    year INT;
    month INT;
    table_name TEXT;
    sql TEXT := 'CREATE TABLE zip_listing AS ';
BEGIN
    FOR year IN 2010..2024 LOOP
        FOR month IN 1..12 LOOP
            table_name := 'zip_mls_' || year || '_' || month;
            sql := sql || 'SELECT * FROM ' || table_name || ' UNION ALL ';
        END LOOP;
    END LOOP;

    -- Remove the last 'UNION ALL'
    sql := left(sql, length(sql) - length(' UNION ALL '));

    -- Execute the final SQL statement
    EXECUTE sql;
END $$;



-- Merge active and expired listing

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

/*
property_type_code_standardized

PROPTY	AP	Apartment
PROPTY	BD	Boat Dock
PROPTY	CN	Condo
PROPTY	CO	Commercial/industrial/Business
PROPTY	CP	Coop
PROPTY	FM	Farm
PROPTY	LD	Lots and Land
PROPTY	MF	Multi Family (5 >)
PROPTY	MH	Mobile Home
PROPTY	RI	Residential Income (2-4 units/Duplex/Triplex/Fourplex)
PROPTY	SF	Single Family
PROPTY	TH	Townhouse
PROPTY	TS	Fractional Ownershp/Timeshare


Listing Category

CdTbl	CdVal	CdDesc
LSTCAT	A  	ACTIVE
LSTCAT	D  	DELETED
LSTCAT	S  	SOLD
LSTCAT	U  	PENDING
LSTCAT	X  	EXPIRED (INCLUDES WITHDRAWN, CANCELLED, TERMINATED, INACTIVE, ETC.)

*/

/*
Los Angeles

1. Los Angeles County, California: FIPS code 06037
2. Orange County, California: FIPS code 06059
3. Riverside County, California: FIPS code 06065
4. San Bernardino County, California: FIPS code 06071
5. Ventura County, California: FIPS code 06111

San Francisco

1. San Francisco County, California: FIPS code 06075
2. Alameda County, California: FIPS code 06001
3. Contra Costa County, California: FIPS code 06013
4. San Mateo County, California: FIPS code 06081
5. Marin County, California: FIPS code 06041

San Diego
San Diego County, 06073


Sacramento




*/

/*
--MANUAL CODEx
ALTER TABLE active
ADD COLUMN is_overlap BOOLEAN;

DROP TABLE IF EXISTS zip_mls_check;
CREATE TABLE zip_mls_check AS
SELECT
    listing_address_zip_code,
    2020 AS year,
    2 AS month,
    COUNT(clip) AS active_listing
FROM
    (
        SELECT *,
            active_date_range && daterange('2020-01-01', '2020-01-31', '[]') AS overlap_check
        FROM active
    ) AS subquery
WHERE
    subquery.overlap_check
GROUP BY
    listing_address_zip_code
ORDER BY
    listing_address_zip_code;

SELECT * from zip_mls_check
*/

/*

DROP TABLE IF EXISTS TEMP;
CREATE TABLE TEMP AS
SELECT clip, zip, listing_date, close_date, list_p , price, COUNT(*) as counta
--SELECT listing_id_
FROM trans_num
WHERE listing_date IS NOT NULL AND zip IS NOT NULL AND clip!='' AND (price!=0 OR listing_status_category_code_standardized='A')
GROUP BY clip, zip, listing_date, close_date, list_p, price
--GROUP BY listing_id_standardized
HAVING COUNT(*) > 1;

SELECT counta, count(*)
FROM TEMP
GROUP BY counta
ORDER BY count DESC;

SELECT COUNT(*) AS total_rows
FROM   mls.listings
*/


