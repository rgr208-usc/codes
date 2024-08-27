
--MERGING THE FIRST PART MERGE MLS AND MORTGAGE AT TRANSACTION LEVEL / THE SECOND PART MERGE AT ZIP LEVEL /:ISTINS IS ALWAYS PRODUCED AT ZIP LEVEL

    --Transaction-->ZIP
    --Zip--> ZIP_Z


--1.TRANSACTION LEVEL MERGE


---MERGE-- checked with Mortgage_Recorded_Date

DROP TABLE IF EXISTS MLS_MTG;
CREATE TABLE MLS_MTG AS
SELECT
    m.clip,
    m.fips,
    m.fips_code,
    m.zip_code,
    m.zip_num,
    m.listing_id, m.orginal_listing_date,
    m.listing_date,
    m.listing_status_category_code_standardized,
    m.close_date,
    m.year,
    m.month,
    m.list_p,
    m.list_ppsf,
    m.or_list_p,
    m.dom,
    m.cumdom,
    m.price,
    m.list_p/NULLIF(m.price,0) AS lp_price,


    t.clip as clipm,
    t.mtg_date,
    t.mtg_r_date,
    t.amount AS mortgage,
    t.rate,
    t.amount / NULLIF(m.price, 0) AS ltv,
    t.rate*t.amount/100 AS int,
    t.rate*t.amount/ NULLIF(m.price, 0)/100 AS intv,
    t.variable_rate_loan_indicator,
    t.fix,
    t.mortgage_type_code
FROM
    MLS m
LEFT JOIN
    MTG t
ON
    m.clip = t.clip
    AND (
        ABS(EXTRACT(EPOCH FROM AGE(m.close_date, t.mtg_date)) / 86400) <= 5
        OR
        ABS(EXTRACT(EPOCH FROM AGE(m.close_date, t.mtg_r_date)) / 86400) <= 5
    )
WHERE  m.clip!=''
  AND  m.listing_status_category_code_standardized='S'
  AND m.zip_num>90000 AND m.zip_num<100000 AND m.zip_num IS NOT NULL
AND  t.mortgage_type_code = 'P';


----COLLAPSE AND MERGE WITH LISTING

DROP TABLE IF EXISTS merge;
CREATE TABLE merge AS
    SELECT
        zip_code,
        year,
        month,
       CAST(COUNT(fips_code)AS INTEGER) AS transactions_old,
        CAST(COUNT(CASE WHEN price IS NOT NULL AND price != 0 THEN 1 END) AS INTEGER) AS transactions,
        CAST(COUNT(CASE WHEN  listing_status_category_code_standardized = 'S' THEN 1 END) AS INTEGER) AS transaction_exp,
        CAST( COUNT(CASE WHEN fix = 1 THEN 1 END)AS INTEGER) AS fix_mortgages,
        CAST( COUNT(CASE WHEN fix = 0 THEN 1 END)AS INTEGER) AS var_mortgages,

        AVG(fips)     AS fips,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY price) AS price_50,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY list_p) AS list_p_50,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY or_list_p) AS or_list_p_50,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY price * list_ppsf / NULLIF(list_p, 0)) AS ppsf_50,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY list_p/ NULLIF(list_p, 0)) AS l_to_p_50,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY or_list_p/ NULLIF(list_p, 0)) AS orl_to_p_50,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY dom) AS dom_50,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY cumdom) AS cumdom_50,

        percentile_cont(0.25) WITHIN GROUP (ORDER BY price) AS price_25,
        percentile_cont(0.25) WITHIN GROUP (ORDER BY list_p) AS list_p_25,
        percentile_cont(0.25) WITHIN GROUP (ORDER BY or_list_p) AS or_list_25,
        percentile_cont(0.25) WITHIN GROUP (ORDER BY price * list_ppsf / NULLIF(list_p, 0)) AS ppsf_25,
        percentile_cont(0.25) WITHIN GROUP (ORDER BY list_p/ NULLIF(list_p, 0)) AS l_to_p_25,
        percentile_cont(0.25) WITHIN GROUP (ORDER BY or_list_p/ NULLIF(list_p, 0)) AS orl_to_p_25,
        percentile_cont(0.25) WITHIN GROUP (ORDER BY dom) AS dom_25,
        percentile_cont(0.25) WITHIN GROUP (ORDER BY cumdom) AS cumdom_25,


        percentile_cont(0.75) WITHIN GROUP (ORDER BY price) AS price_75,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY list_p) AS list_p_75,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY or_list_p) AS or_list_75,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY price * list_ppsf / NULLIF(list_p, 0)) AS ppsf_75,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY list_p/ NULLIF(list_p, 0)) AS l_to_p_75,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY or_list_p/ NULLIF(list_p, 0)) AS orl_to_p_75,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY dom) AS dom_75,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY cumdom) AS cumdom_75,

         percentile_cont(0.5) WITHIN GROUP (ORDER BY int ) AS int_50,
         percentile_cont(0.5) WITHIN GROUP (ORDER BY ltv) AS ltv_50,
         percentile_cont(0.5) WITHIN GROUP (ORDER BY intv) AS intv_50,

         percentile_cont(0.75) WITHIN GROUP (ORDER BY int ) AS int_75,
         percentile_cont(0.75) WITHIN GROUP (ORDER BY ltv) AS ltv_75,
         percentile_cont(0.75) WITHIN GROUP (ORDER BY intv) AS intv_75,

         percentile_cont(0.25) WITHIN GROUP (ORDER BY int ) AS int_25,
         percentile_cont(0.25) WITHIN GROUP (ORDER BY ltv) AS ltv_25,
         percentile_cont(0.25) WITHIN GROUP (ORDER BY intv) AS intv_25
/*
      CAST(COUNT(fix)AS INTEGER) AS mortgages,
      CAST(COUNT(CASE WHEN  mortgage_type_code = 'P' THEN 1 END) AS INTEGER) AS purchases,
      CAST( COUNT(CASE WHEN  mortgage_type_code = 'J' THEN 1 END)AS INTEGER)  AS junior,
      CAST( COUNT(CASE WHEN  mortgage_type_code = 'R' THEN 1 END)AS INTEGER)  AS refinances,
      CAST( COUNT(CASE WHEN fix = 1 THEN 1 END)AS INTEGER) AS fix_mortgages,
      CAST( COUNT(CASE WHEN fix = 0 THEN 1 END)AS INTEGER) AS var_mortgages,
*/
    FROM MLS_MTG
    WHERE
    GROUP BY
        zip_code,
        year,
        month
    ORDER BY
        zip_code,
        year,
        month
;

DROP TABLE IF EXISTS ZIP;
CREATE TABLE ZIP AS
(
    SELECT
      m.*,
      t.active_listing,
      u.listing_exp

--check if you need to have Jan-March 2024
    FROM MERGE m
    LEFT JOIN zip_listing t
    ON (
       m.zip_code = t.zip_code
        AND m.month::INTEGER = t.month
        AND m.year::INTEGER = t.year
    )
    LEFT JOIN listing_expired u
        ON(m.zip_code = u.zip_code
        AND m.month::INTEGER = u.month
        AND m.year::INTEGER = u.year)


    ORDER BY
        m.zip_code,
        m.year,
        m.month
);

--2 ZIP MERGE


DROP TABLE IF EXISTS ZIP_ZIP;
CREATE TABLE ZIP_ZIP AS
(
    SELECT
      m.*,
      t.active_listing,
      u.listing_exp,
      w.mortgages,
      w.purchases,
      w.junior,
   w.refinances,
   w.fix_mortgages,
   w.var_mortgages,

       w.int_50,
    w.rate_50,
      w.amount_50,


  w.int_25,
   w.rate_25,
         w.amount_25,
         w.int_75,
         w.rate_75,
  w.amount_75

--check if you need to have Jan-March 2024
    FROM zip_mls m
    LEFT JOIN zip_listing t
    ON (
       m.zip_code = t.zip_code
        AND m.month = t.month
        AND m.year= t.year
    )

    LEFT JOIN zip_expired_listing u
        ON(m.zip_code = u.zip_code
        AND m.month::INTEGER = u.month
        AND m.year::INTEGER = u.year)
    LEFT  JOIN zip_mortgage w
    ON (
        m.zip_code = w.zip_code
        AND m.month::INTEGER = w.month
        AND m.year::INTEGER = w.year
    )

    ORDER BY
        m.zip_code,
        m.year,
        m.month
);



select zip_code, year, month, transaction, active_listing, listing_exp FROM ZIP_ZIP WHERE year>2009