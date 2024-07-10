CREATE TABLE output_mls AS
(SELECT clip, fips_code, listing_id_standardized, listing_type, listing_status_category_code_standardized,
       listing_status_code_standardized, listing_transaction_type_code_derived, listing_date, original_listing_date,
       close_date, close_date_standardized, days_on_market_dom, days_on_market_dom_cumulative, original_listing_date_and_time_standardized,
       last_listing_date_and_time_standardized, close_price, current_listing_price, original_listing_price, price_per_square_foot FROM mls.listings

WHERE  fips_code='06037' OR fips_code='06059' OR  fips_code='06065' OR  fips_code='06071'  OR fips_code='06111')