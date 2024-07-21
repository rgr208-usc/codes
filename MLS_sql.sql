
---FULL TABLE ----

-- LA (fips_code='06037' OR fips_code='06059' OR  fips_code='06065' OR  fips_code='06071'  OR fips_code='06111'));

DROP TABLE IF EXISTS TRANS_NUM
CREATE TABLE TRANS_NUM AS
(SELECT
    clip, fips_code, SUBSTRING(listing_address_zip_code FROM 1 FOR 5) as listing_address_zip_code , listing_status_category_code_standardized,property_type_code_standardized,
    TO_DATE(SUBSTRING(close_date_standardized FROM 1 FOR 10), 'YYYY-MM-DD') AS close_date,
    TO_DATE(SUBSTRING(listing_date FROM 1 FOR 10), 'YYYY-MM-DD') AS listing_date,
    NULLIF(REGEXP_REPLACE(fips_code, '[^0-9.]+', '', 'g'), '')::numeric AS fips,
    NULLIF(REGEXP_REPLACE(listing_address_zip_code, '[^0-9.]+', '', 'g'), '')::numeric AS zip,
    NULLIF(REGEXP_REPLACE(SUBSTRING(listings.close_date_standardized FROM 1 FOR 4),'[^0-9.]+', '', 'g'), '')::integer as year,
    NULLIF(REGEXP_REPLACE(SUBSTRING(listings.close_date_standardized FROM 6 FOR 2),'[^0-9.]+', '', 'g'), '')::integer as month,
    NULLIF(REGEXP_REPLACE(SUBSTRING(listing_date FROM 1 FOR 4),'[^0-9.]+', '', 'g'), '') as list_year,
    NULLIF(REGEXP_REPLACE(SUBSTRING(listing_date FROM 6 FOR 2),'[^0-9.]+', '', 'g'), '') as list_month,
    NULLIF(REGEXP_REPLACE(close_price, '[^0-9.]+', '', 'g'), '')::numeric AS price,
    NULLIF(REGEXP_REPLACE(current_listing_price, '[^0-9.]+', '', 'g'), '')::numeric AS list_p,
    NULLIF(REGEXP_REPLACE(original_listing_price, '[^0-9.]+', '', 'g'), '')::numeric AS or_list_p,
    NULLIF(REGEXP_REPLACE(price_per_square_foot, '[^0-9.]+', '', 'g'), '')::numeric AS list_ppsf,
    NULLIF(REGEXP_REPLACE(days_on_market_dom_derived, '[^0-9.]+', '', 'g'), '')::numeric AS dom,
    NULLIF(REGEXP_REPLACE(days_on_market_dom_cumulative, '[^0-9.]+', '', 'g'), '')::numeric AS cumdom
FROM   mls.listings
WHERE listing_status_category_code_standardized='S' AND
      --choose the type of property
      (property_type_code_standardized='CN' OR property_type_code_standardized='SF' OR  property_type_code_standardized='TH'   )
);



DROP TABLE IF EXISTS zip_mls;
CREATE TABLE zip_mls AS
(
    SELECT
        listing_address_zip_code,
        year,
        month,
        COUNT(fips_code) AS transactions,
        AVG(fips)     AS fips,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY price) AS price,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY list_p) AS list_p,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY or_list_p) AS or_list_p,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY price * list_ppsf / NULLIF(list_p, 0)) AS ppsf,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY list_p/ NULLIF(list_p, 0)) AS l_to_p,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY or_list_p/ NULLIF(list_p, 0)) AS orl_to_p,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY dom) AS dom,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY cumdom) AS cumdom
    FROM
        TRANS_NUM
    GROUP BY
        listing_address_zip_code,
        year,
        month
    ORDER BY
        listing_address_zip_code,
        year,
        month
);


--create an active listing data range using listing dates and dom

DROP TABLE IF EXISTS ACTIVE
CREATE TABLE ACTIVE AS
(SELECT clip, fips_code, listing_address_zip_code, dom, listing_date,
   (listing_date + (dom || ' days')::INTERVAL)::DATE AS end_listing_date,
       daterange(
        listing_date,
        (listing_date + (dom || ' days')::INTERVAL)::DATE,
        '[]'
    ) AS active_date_range
FROM TRANS_NUM
    ---make sure open ended range correspond to active listing not missing dom
WHERE dom IS NOT NULL OR listing_status_category_code_standardized='A');

---create a table per month check with manual code at the end

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
                    COUNT(clip) AS active_listing
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

---Merge all tables to be checked seems OK
DROP TABLE IF EXISTS zip_listing
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

--Merge with Listings and creating zip

DROP TABLE IF EXISTS zip
CREATE TABLE zip AS
(
    SELECT
      fips,
      transactions,
      zip_mls.listing_address_zip_code as zip_code,
      zip_mls.month,
      zip_mls.year,
        price,
        active_listing,
        list_p,
        or_list_p,
        l_to_p,
        orl_to_p,
        ppsf,
        dom,
        cumdom
--check if you need to have Jan-March 2024
    FROM zip_mls
    INNER JOIN zip_listing
    ON (
        zip_mls.listing_address_zip_code = zip_listing.listing_address_zip_code
        AND zip_mls.month::INTEGER = zip_listing.month
        AND zip_mls.year::INTEGER = zip_listing.year
    )
    WHERE zip_mls.listing_address_zip_code !=''
    ORDER BY
        zip_mls.listing_address_zip_code,
        year,
        month
);

SELECT * FROM zip



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
