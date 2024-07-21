
DROP TABLE IF EXISTS Mortgage_Num;
CREATE TABLE Mortgage_Num AS
    (SELECT clip,SUBSTRING( deed_situs_zip_code___static FROM 1 FOR 5) as zip_code,
       mortgage_type_code, --PURCHASE, REFI, JUNIOR, P,R,J
       mortgage_purpose_code,  --F (First Mortgage), see below
       conforming_loan_indicator,conventional_loan_indicator, refinance_loan_indicator,
       government_sponsored_enterprise_gse_eligible_mortgage_indicator,
        construction_loan_indicator,equity_loan_indicator,fha_loan_indicator,veterans_administration_loan_indicator,
        multifamily_rider_indicator,condominium_rider_indicator,second_home_rider_indicator,
        variable_rate_loan_indicator, fixed_rate_indicator,
            NULLIF(REGEXP_REPLACE(fips_code, '[^0-9.]+', '', 'g'), '') ::numeric AS fips,
            NULLIF(REGEXP_REPLACE(mortgage_amount, '[^0-9.]+', '', 'g'), '') ::numeric amount,
            NULLIF(REGEXP_REPLACE(SUBSTRING(mortgage_recording_date FROM 1 FOR 4),'[^0-9.]+', '', 'g'), '')::integer as year,
            NULLIF(REGEXP_REPLACE(SUBSTRING(mortgage_recording_date FROM 5 FOR 2),'[^0-9.]+', '', 'g'), '')::integer  as month,
            NULLIF(REGEXP_REPLACE(mortgage_interest_rate, '[^0-9.]+', '', 'g'), '') ::numeric AS rate
     FROM mortgage.basics
     ---Residential Conventional
     WHERE (property_indicator_code___static = '10' OR property_indicator_code___static = '11' OR
            property_indicator_code___static = '21'
         OR property_indicator_code___static = '22') AND  (mortgage_loan_type_code='CNV') AND (fixed_rate_indicator!=''));
SELECT * FROM Mortgage_Num

---MERGING WITH MLS OR OWNER TRASNFER--

DROP TABLE IF EXISTS zip_mortgage;
CREATE TABLE zip_mortgage AS
(
    SELECT
       zip_code,
        year,
        month,
       COUNT(fixed_rate_indicator) AS mortgages,
       COUNT(CASE WHEN fixed_rate_indicator = '1' THEN 1 END) AS fix_mortgages,
       COUNT(CASE WHEN fixed_rate_indicator = '0' THEN 1 END) AS var_mortgages,
       AVG(fips) AS fips,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY rate) AS rate,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY amount) AS amount
    FROM
        Mortgage_Num
    GROUP BY
          zip_code,
        year,
        month
    ORDER BY
        zip_code,
        year,
        month
);
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
