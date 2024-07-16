
---FULL TABLE ----

-- LA (fips_code='06037' OR fips_code='06059' OR  fips_code='06065' OR  fips_code='06071'  OR fips_code='06111'));

DROP TABLE TRANS_NUM
CREATE TABLE TRANS_NUM AS
(SELECT
    clip, fips_code,  listing_address_zip_code,  property_type_code_standardized,
    SUBSTRING(close_date_standardized FROM 1 FOR 4) as close_year,
    SUBSTRING(close_date_standardized FROM 6 FOR 2) as close_month,
    NULLIF(REGEXP_REPLACE(SUBSTRING(listing_date FROM 1 FOR 4),'[^0-9.]+', '', 'g'), '') as list_year,
    SUBSTRING(listing_date FROM 6 FOR 2) as list_month,
    NULLIF(REGEXP_REPLACE(close_price, '[^0-9.]+', '', 'g'), '')::numeric AS price,
    NULLIF(REGEXP_REPLACE(current_listing_price, '[^0-9.]+', '', 'g'), '')::numeric AS list_p,
    NULLIF(REGEXP_REPLACE(original_listing_price, '[^0-9.]+', '', 'g'), '')::numeric AS or_list_p,
    NULLIF(REGEXP_REPLACE(price_per_square_foot, '[^0-9.]+', '', 'g'), '')::numeric AS list_ppsf,
    NULLIF(REGEXP_REPLACE(days_on_market_dom_derived, '[^0-9.]+', '', 'g'), '')::numeric AS dom,
    NULLIF(REGEXP_REPLACE(days_on_market_dom_cumulative, '[^0-9.]+', '', 'g'), '')::numeric AS cumdom
FROM   mls.listings
WHERE listing_status_category_code_standardized='S');


---collpase----

--issue with median

--conditional

DROP TABLE zip_mls
CREATE TABLE zip_mls2 AS
(SELECT listing_address_zip_code, close_year, close_month, COUNT(fips_code) as listings, AVG( price) AS price , AVG(list_p) as list_p,
AVG(or_list_p) AS or_list_p, AVG(price*list_ppsf/NULLIF(list_p, 0)) as ppsf , AVG(dom) AS dom, AVG(cumdom) AS cumdom
 FROM TRANS_NUM
                                      GROUP BY listing_address_zip_code, close_year, close_month ORDER BY listing_address_zip_code, close_year, close_month ) ;


SELECT * FROM zip_ml