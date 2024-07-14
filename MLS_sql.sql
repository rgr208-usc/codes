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
       last_listing_date_and_time_standardized, days_on_market_dom, listings.days_on_market_dom_derived, days_on_market_dom_cumulative,
       close_price, current_listing_price,
       original_listing_price, price_per_square_foot FROM mls.listings
WHERE listing_transaction_type_code_derived='S' AND listing_date!='' AND listing_date!='TBD' AND current_listing_price!='' AND price_per_square_foot!=''
  AND days_on_market_dom_derived!='' AND close_price!=''  AND (fips_code='06037' OR fips_code='06059' OR  fips_code='06065' OR  fips_code='06071'  OR fips_code='06111'));

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
ALTER TABLE output_mls
ALTER COLUMN price_per_square_foot  TYPE NUMERIC USING price_per_square_foot::NUMERIC
ALTER TABLE output_mls
ALTER COLUMN current_listing_price  TYPE NUMERIC USING current_listing_price::NUMERIC
ALTER TABLE output_mls
ALTER COLUMN close_price  TYPE NUMERIC USING close_price::NUMERIC
ALTER TABLE output_mls
ALTER COLUMN days_on_market_dom_derived TYPE NUMERIC USING days_on_market_dom_derived::NUMERIC
ALTER TABLE output_mls
ADD COLUMN close_ppsf NUMERIC
UPDATE output_mls
SET close_ppsf=price_per_square_foot*close_price/NULLIF(current_listing_price, 0);


DROP TABLE zip_mls
CREATE TABLE zip_mls AS
(SELECT listing_address_zip_code, listing_year, listing_month, COUNT(fips_code) as listings, AVG( price_per_square_foot) AS list_psf,
AVG(current_listing_price) AS list_p, AVG(close_price) AS price,AVG(days_on_market_dom_derived) AS dom, AVG(output_mls.close_ppsf) as cl_psf
 FROM output_mls
                                      GROUP BY listing_address_zip_code, listing_year,listing_month ORDER BY listing_address_zip_code, listing_year,listing_month ) ;

---FULL TABLE ----

---FULL TABLE ----
DROP TABLE transaction
CREATE TABLE transaction AS
(SELECT clip, fips_code, listing_address_zip_code, SUBSTRING(close_date_standardized FROM 1 FOR 4) as close_year,
        SUBSTRING(close_date_standardized FROM 6 FOR 2) as close_month,
        close_price, current_listing_price, original_listing_price, price_per_square_foot,
        days_on_market_dom_derived, days_on_market_dom_cumulative, property_type_code_standardized
        FROM mls.listings
WHERE listing_status_category_code_standardized='S'  AND (fips_code='06037' OR fips_code='06059' OR  fips_code='06065' OR  fips_code='06071'  OR fips_code='06111'));


