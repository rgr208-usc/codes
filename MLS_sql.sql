

---FULL TABLE ----
DROP TABLE transaction
CREATE TABLE transaction AS
(SELECT clip, fips_code, listing_address_zip_code, SUBSTRING(close_date_standardized FROM 1 FOR 4) as close_year,
        SUBSTRING(close_date_standardized FROM 6 FOR 2) as close_month,
        close_price, current_listing_price, original_listing_price, price_per_square_foot,
        days_on_market_dom_derived, days_on_market_dom_cumulative, property_type_code_standardized
        FROM mls.listings
WHERE listing_status_category_code_standardized='S'  AND (fips_code='06037' OR fips_code='06059' OR  fips_code='06065' OR  fips_code='06071'  OR fips_code='06111'));

--Numeric Conversation

-- 'clip', 'fips_code', 'listing_address_zip_code','close_year','close_month','close_price', 'current_listing_price', 'original_listing_price', 'price_per_square_foot',
--         'days_on_market_dom_derived', 'days_on_market_dom_cumulative'

DO $$
DECLARE
    cols TEXT[] := ARRAY['clip', 'fips_code', 'listing_address_zip_code','close_year','close_month','close_price', 'current_listing_price', 'original_listing_price', 'price_per_square_foot',
 'days_on_market_dom_derived', 'days_on_market_dom_cumulative']; -- List your existing columns here
    col TEXT;
BEGIN
    FOREACH col IN ARRAY cols
    LOOP
        -- Step 1: Add the new column
        EXECUTE format('ALTER TABLE transaction ADD COLUMN %I_n numeric', col);

        -- Step 2: Update the new column with valid numeric values
        EXECUTE format('UPDATE transaction SET %I_n = CASE
            WHEN %I ~ ''^[+-]?[0-9]+(\.[0-9]+)?$'' THEN %I::numeric
            ELSE NULL
        END', col, col, col);
    END LOOP;
END $$;


---collpase----

DROP TABLE zip_mls
CREATE TABLE zip_mls AS
(SELECT listing_address_zip_code, close_year, close_month, COUNT(fips_code) as listings, AVG( price_per_square_foot_n) AS list_psf,
AVG(current_listing_price_n) AS list_p, AVG(close_price_n) AS price,AVG(days_on_market_dom_derived_n) AS dom
 FROM transaction
                                      GROUP BY listing_address_zip_code, listing_year,listing_month ORDER BY listing_address_zip_code, listing_year,listing_month ) ;


