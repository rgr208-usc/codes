
---FULL TABLE ----

-- LA (fips_code='06037' OR fips_code='06059' OR  fips_code='06065' OR  fips_code='06071'  OR fips_code='06111'));

DROP TABLE IF EXISTS TRANS_NUM
CREATE TABLE TRANS_NUM AS
(SELECT
    clip, fips_code, listing_address_zip_code, listing_status_category_code_standardized,
    TO_DATE(SUBSTRING(close_date_standardized FROM 1 FOR 10), 'YYYY-MM-DD') AS close_date,
    TO_DATE(SUBSTRING(listing_date FROM 1 FOR 10), 'YYYY-MM-DD') AS listing_date,
    TO_DATE(SUBSTRING(last_listing_date_and_time_standardized FROM 1 FOR 10), 'YYYY-MM-DD') AS last_listing_date,
    TO_DATE(SUBSTRING(off_market_date_and_time_standardized FROM 1 FOR 10), 'YYYY-MM-DD') AS off_market_date,
    NULLIF(REGEXP_REPLACE(fips_code, '[^0-9.]+', '', 'g'), '')::numeric AS fips,
    NULLIF(REGEXP_REPLACE(listing_address_zip_code, '[^0-9.]+', '', 'g'), '')::numeric AS zip,
    NULLIF(REGEXP_REPLACE(SUBSTRING(listings.close_date_standardized FROM 1 FOR 4),'[^0-9.]+', '', 'g'), '') as close_year,
    NULLIF(REGEXP_REPLACE(SUBSTRING(listings.close_date_standardized FROM 6 FOR 2),'[^0-9.]+', '', 'g'), '') as close_month,
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



DROP TABLE IF EXISTS zip_mls2;
CREATE TABLE zip_mls2 AS
(
    SELECT
        listing_address_zip_code,
        close_year,
        close_month,
        COUNT(fips_code) AS listings,
        AVG(fips)     AS fips,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY price) AS price,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY list_p) AS list_p,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY or_list_p) AS or_list_p,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY price * list_ppsf / NULLIF(list_p, 0)) AS ppsf,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY dom) AS dom,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY cumdom) AS cumdom
    FROM
        TRANS_NUM
    GROUP BY
        listing_address_zip_code,
        close_year,
        close_month
    ORDER BY
        listing_address_zip_code,
        close_year,
        close_month
);


--create an active date range

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


--The ideal would be to creat a loop
ALTER TABLE active
ADD COLUMN is_overlap BOOLEAN;

DROP TABLE IF EXISTS zip_mls2;

CREATE TABLE zip_mls2 AS
SELECT
    listing_address_zip_code,
    2023 AS year,
    1 AS month,
    COUNT(clip) AS active_listing
FROM
    (
        SELECT *,
            active_date_range && daterange('2023-01-01', '2023-01-31', '[]') AS overlap_check
        FROM active
    ) AS subquery
WHERE
    subquery.overlap_check
GROUP BY
    listing_address_zip_code
ORDER BY
    listing_address_zip_code;


DO $$
DECLARE
    start_year INTEGER := 2023;  -- Change this to your desired starting year
    end_year INTEGER := 2023;    -- Change this to your desired ending year
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



DROP TABLE IF EXISTS consolidated_zip_mls;

CREATE TABLE consolidated_zip_mls AS
WITH month_year AS (
    SELECT generate_series(2020, 2023) AS year,
           generate_series(1, 12) AS month
)
SELECT
    a.listing_address_zip_code,
    my.year,
    my.month,
    COUNT(a.clip) AS active_listing
FROM
    month_year my
LEFT JOIN
    active a ON a.active_date_range && daterange(
        DATE (my.year || '-' || lpad(my.month::text, 2, '0') || '-01'),
        (DATE (my.year || '-' || lpad(my.month::text, 2, '0') || '-01') + INTERVAL '1 month')::DATE,
        '[]'
    )
GROUP BY
    a.listing_address_zip_code, my.year, my.month
ORDER BY
    a.listing_address_zip_code, my.year, my.month;


SELECT * FROM zip_mls_2023_12

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


*/

/*
Los Angeles

1. Los Angeles County, California: FIPS code 06037
2. Orange County, California: FIPS code 06059
3. Riverside County, California: FIPS code 06065
4. San Bernardino County, California: FIPS code 06071
5. Ventura County, California: FIPS code 06111


1. San Francisco County, California: FIPS code 06075
2. Alameda County, California: FIPS code 06001
3. Contra Costa County, California: FIPS code 06013
4. San Mateo County, California: FIPS code 06081
5. Marin County, California: FIPS code 06041


*/
