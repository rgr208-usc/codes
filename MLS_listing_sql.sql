
--This code specifically deal with listing - abandonned file


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


----DUPLICATES PURGE FOR TRANSACTIONS - same as in MLS----

--create an active listing data range using listing dates and dom

DROP TABLE IF EXISTS ACTIVE;
CREATE TABLE ACTIVE AS
SELECT clip, fips_code, listing_status_category_code_standardized, zip_code, zip_num, dom, listing_date, close_date,
   (listing_date + (dom || ' days')::INTERVAL)::DATE AS end_listing_date,
   EXTRACT(MONTH FROM (listing_date + (dom || ' days')::INTERVAL)::DATE) AS month_exp,
   EXTRACT(YEAR FROM (listing_date + (dom || ' days')::INTERVAL)::DATE) AS year_exp,
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
