DROP TABLE output_table
CREATE TABLE output_table AS
(SELECT clip, fips_code, transaction_batch_date, SUBSTRING(transaction_batch_date FROM 1 FOR 4) as transaction_year, SUBSTRING(transaction_batch_date FROM 5 FOR 2)
    as transaction_month,
mortgage_interest_rate_type_code, variable_rate_loan_indicator,
fixed_rate_indicator, mortgage_type_code,  mortgage_interest_rate,mortgage_amount, conforming_loan_indicator, conventional_loan_indicator, mortgage_arm_index_type,
mortgage_arm_maximum_interest_rate, mortgage_arm_change_percent_limit
FROM mortgage.basics WHERE  fips_code='06037' OR fips_code='06059' OR  fips_code='06065' OR  fips_code='06071'  OR fips_code='06111' AND transaction_batch_date!='');

/*UPDATE output_table
SET mortgage_interest_rate ='0' WHERE mortgage_interest_rate ='';*/
ALTER TABLE output_table
ALTER COLUMN fixed_rate_indicator TYPE NUMERIC USING fixed_rate_indicator::NUMERIC
ALTER TABLE output_table
ALTER COLUMN transaction_year TYPE NUMERIC USING transaction_year::NUMERIC
ALTER TABLE output_table
ALTER COLUMN transaction_month TYPE NUMERIC USING transaction_month::NUMERIC
ALTER TABLE output_table
ALTER COLUMN variable_rate_loan_indicator TYPE NUMERIC USING variable_rate_loan_indicator::NUMERIC


/*
SELECT
    mortgage_amount,
    CASE
        WHEN mortgage_amount ~ '^[+-]?[0-9]*\.?[0-9]+$' THEN mortgage_amount::NUMERIC
        ELSE NULL
    END AS mortgage
FROM output_table;
*/

DROP TABLE collaps1
CREATE TABLE collaps1 AS
(SELECT transaction_year, transaction_month, AVG(fixed_rate_indicator) AS fix ,
       AVG(variable_rate_loan_indicator) AS variable
 FROM output_table
                                      GROUP BY transaction_year, transaction_month ORDER BY transaction_year,transaction_month ) ;


