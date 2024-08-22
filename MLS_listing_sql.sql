
--This code specifically deal with listing

---active listing


 DROP TABLE IF EXISTS TRANS_NUM
CREATE TABLE TRANS_NUM AS
(SELECT
    clip, fips_code, SUBSTRING(listing_address_zip_code FROM 1 FOR 5) as listing_address_zip_code ,
    listing_status_category_code_standardized,property_type_code_standardized,
    listing_id_standardized, listing_id,
    TO_DATE(SUBSTRING(close_date_standardized FROM 1 FOR 10), 'YYYY-MM-DD') AS close_date,
    TO_DATE(SUBSTRING(listing_date FROM 1 FOR 10), 'YYYY-MM-DD') AS listing_date,
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
FROM   mls.listings
--
WHERE --(listing_status_category_code_standardized='S'| listings.listing_status_category_code_standardized='A') AND
      --choose the type of property
      (property_type_code_standardized='CN' OR property_type_code_standardized='SF' OR  property_type_code_standardized='TH'   )
);


--create an active listing data range using listing dates and dom

DROP TABLE IF EXISTS ACTIVE;
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
