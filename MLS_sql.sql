
---FULL TABLE ----

-- LA (fips_code='06037' OR fips_code='06059' OR  fips_code='06065' OR  fips_code='06071'  OR fips_code='06111'));

DROP TABLE IF EXISTS TRANS_NUM
CREATE TABLE TRANS_NUM AS
(SELECT
    clip, fips_code, listing_address_zip_code,
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
      (property_type_code_standardized='CN' OR property_type_code_standardized='SF' OR  property_type_code_standardized='TH'   )
);


---collpase----

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
