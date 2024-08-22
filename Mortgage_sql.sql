
-----try to complete missing zip using mls - not sure it is worth it it adds about 15' run time

DROP TABLE IF EXISTS Mortgage_Num;
CREATE TABLE Mortgage_Num AS
    (SELECT mortgage.basics.clip,
         --mls.listings.clip as clip_mls,
            -- choice of mortgage date or mortgage recording rate
         mortgage_composite_transaction_id,
         mortgage_sequence_number,
         transaction_batch_sequence_number,
          mortgage_type_code, --PURCHASE, REFI, JUNIOR, P,R,J
          mortgage_purpose_code,  --F (First Mortgage), see below
          conforming_loan_indicator,conventional_loan_indicator, refinance_loan_indicator,
           government_sponsored_enterprise_gse_eligible_mortgage_indicator,
           construction_loan_indicator,equity_loan_indicator,fha_loan_indicator,veterans_administration_loan_indicator,
          multifamily_rider_indicator,condominium_rider_indicator,second_home_rider_indicator,
        variable_rate_loan_indicator, fixed_rate_indicator, mortgage_date, mortgage_recording_date,
            SUBSTRING( deed_situs_zip_code___static FROM 1 FOR 5) as zip,
            NULLIF(REGEXP_REPLACE(mortgage.basics.fips_code, '[^0-9.]+', '', 'g'), '') ::numeric AS fips,
            NULLIF(REGEXP_REPLACE(fixed_rate_indicator, '[^0-9.]+', '', 'g'), '') ::numeric AS fix,
            NULLIF(REGEXP_REPLACE(mortgage_amount, '[^0-9.]+', '', 'g'), '') ::numeric AS amount,
            TO_DATE( TO_CHAR(TO_DATE(mortgage_date, 'YYYYMMDD'), 'YYYY-MM-DD'),'YYYY-MM-DD')  AS mtgdate,
            NULLIF(REGEXP_REPLACE(SUBSTRING(mortgage_date FROM 1 FOR 4),'[^0-9.]+', '', 'g'), '')::integer AS year,
            NULLIF(REGEXP_REPLACE(SUBSTRING(mortgage_date FROM 5 FOR 2),'[^0-9.]+', '', 'g'), '')::integer  AS month,
            NULLIF(REGEXP_REPLACE(SUBSTRING(mortgage_date FROM 7 FOR 2),'[^0-9.]+', '', 'g'), '')::integer  AS day,
            NULLIF(REGEXP_REPLACE(mortgage_interest_rate, '[^0-9.]+', '', 'g'), '') ::numeric AS rate
        FROM mortgage.basics
        WHERE mortgage_date!='' AND property_indicator_code___static IN ('10', '11', '21', '22')
        AND  mortgage_loan_type_code='CNV' AND fixed_rate_indicator!='' --AND mortgage.basics.clip!=''
    ---Residential Conventional
     );


-----
DROP TABLE IF EXISTS zip_mortgage;
CREATE TABLE zip_mortgage AS
(
    SELECT
        ----putt the mortage zip if zip_mls is empty - e.g refinance
        zip,
        year AS yearm,
        month AS monthm,
      AVG(fips) AS fipsm,
      CAST(COUNT(fix)AS INTEGER) AS mortgages,
      CAST(COUNT(CASE WHEN  mortgage_type_code = 'P' THEN 1 END) AS INTEGER) AS purchases,
      CAST( COUNT(CASE WHEN  mortgage_type_code = 'J' THEN 1 END)AS INTEGER)  AS junior,
      CAST( COUNT(CASE WHEN  mortgage_type_code = 'R' THEN 1 END)AS INTEGER)  AS refinances,
      CAST( COUNT(CASE WHEN fix = 1 THEN 1 END)AS INTEGER) AS fix_mortgages,
      CAST( COUNT(CASE WHEN fix = 0 THEN 1 END)AS INTEGER) AS var_mortgages,

       percentile_cont(0.5) WITHIN GROUP (ORDER BY rate*amount/100) AS int_50,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY rate) AS rate_50,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY amount) AS amount_50,


       percentile_cont(0.25) WITHIN GROUP (ORDER BY rate*amount/100) AS int_25,
       percentile_cont(0.25) WITHIN GROUP (ORDER BY rate) AS rate_25,
       percentile_cont(0.25) WITHIN GROUP (ORDER BY amount) AS amount_25,


       percentile_cont(0.75) WITHIN GROUP (ORDER BY rate*amount/100) AS int_75,
       percentile_cont(0.75) WITHIN GROUP (ORDER BY rate) AS rate_75,
       percentile_cont(0.75) WITHIN GROUP (ORDER BY amount) AS amount_75
    FROM
        Mortgage_Num
    WHERE zip!=''
    GROUP BY
        zip,
        year,
        month
    ORDER BY
        zip,
        year,
        month
);


    --


/*
 mortgage_purpose_code
CdTbl	CdVal	CdDesc
MPRPS	A	Cash Out First
MPRPS	B	Rate /Term Reduction
MPRPS	C	Piggy-Back on Purchase
MPRPS	D	Standalone Subordinate (fka Brand New Equity)
MPRPS	E	First with Subordinate (fka First with Equity)
MPRPS	F	New First Mortgage
MPRPS	K	Consolidation
MPRPS	L	Undetermined First Mortgage
MPRPS	M	Undetermined Standalone Subordinate
MPRPS	N	Piggy-Back on Refinance
MPRPS	O	HUD recording associated with reverse mtg
MPRPS	P	First Trust Modification
MPRPS	Q	Junior Trust Modification
MPRPS	R	Other Trust Modification
MPRPS	V	Reverse Mortgage
MPRPS	Z	Duplicate Mortgage

*/

    select * fom zip_mls_mortgage