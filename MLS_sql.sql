--MLS

DROP TABLE output_mls;
CREATE TABLE output_mls AS
(SELECT clip, fips_code, listing_address_zip_code, census_tract, listing_id_standardized, listing_type, listing_status_code, listing_status_category_code_standardized,
       listing_status_code_standardized, listing_transaction_type_code_derived, listing_date, SUBSTRING(listing_date FROM 1 FOR 4) as listing_year,
       SUBSTRING(listing_date FROM 6 FOR 2) as listing_month,
       original_listing_date,
       close_date, close_date_standardized, SUBSTRING(close_date_standardized FROM 1 FOR 4) as close_year, SUBSTRING(close_date_standardized FROM 6 FOR 2) as close_month ,
       off_market_date_and_time_standardized, off_market_date,
       original_listing_date_and_time_standardized,
       last_listing_date_and_time_standardized, days_on_market_dom, days_on_market_dom_cumulative, close_price, current_listing_price,
       original_listing_price, price_per_square_foot FROM mls.listings
WHERE listing_transaction_type_code_derived='S' AND listing_date!='' AND listing_date!='TBD' AND (fips_code='06037' OR fips_code='06059' OR  fips_code='06065' OR  fips_code='06071'  OR fips_code='06111'));

/*
SELECT t.*, CTID
                  FROM public.output_mls t
                  ORDER BY clip
                  LIMIT 501

 */

ALTER TABLE output_mls
ALTER COLUMN listing_month  TYPE NUMERIC USING listing_month::NUMERIC
ALTER TABLE output_mls
ALTER COLUMN listing_year  TYPE NUMERIC USING listing_year::NUMERIC
ALTER COLUMN days_on_market_dom_cumulative  TYPE NUMERIC USING days_on_market_dom_cumulative::NUMERIC
ALTER COLUMN days_on_market_dom_cumulative  TYPE NUMERIC USING days_on_market_dom_cumulative::NUMERIC
ALTER COLUMN original_listing_price  TYPE NUMERIC USING orginal_listing_price::NUMERIC
ALTER COLUMN close_price  TYPE NUMERIC USING close_price::NUMERIC
ALTER COLUMN price_per_square_foot  TYPE NUMERIC USING price_per_square_foot::NUMERIC
