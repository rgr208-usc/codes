
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




#delimit;

clear all;
cd /Users/ranciere/Dropbox/data_sources/Corelogic;
odbc query "PostgreSQLDB", dialog(complete) user(ranciere) password(usc2024!!);
odbc load, exec ("SELECT * FROM public.zip_mls " )  dsn("postgreSQLDB");






#delimit;

clear all;
cd /Users/ranciere/Dropbox/data_sources/Corelogic;
odbc query "PostgreSQLDB", dialog(complete) user(ranciere) password(usc2024!!);
odbc load, exec ("SELECT * FROM public.zip_mls " )  dsn("postgreSQLDB");

rename listing_address_zip_code ZIP_CODE_L;
gen str5 ZIP_CODE = substr(ZIP_CODE_L, 1, 5);
drop if ZIP_CODE=="";

save mls, replace;

merge m:1 ZIP_CODE using zipcodes;
keep if _merge==3;

#delimit;

rename listing_year year;
rename listing_month month;

gen day=1;
g date=mdy(month,day,year);
format date %td;

gen month2 = mofd(date);
format month2 %tm;


destring ZIP_CODE, g(zip);
tsset zip month2;

 
save mls2, replace;


spmap  cl_psf using zipcodes_coor.dta if year==2023 & month==7 & fip==06037 , id(id) fcolor(Reds) title( "PPSF LA CO JULY 2021");


/*
listing_sta |
tus_categor |
y_code_stan |
   dardized |      Freq.     Percent        Cum.
------------+-----------------------------------
          A |     21,134        0.61        0.61
          D |         33        0.00        0.61
          S |  2,391,585       68.50       69.11
          U |      8,879        0.25       69.36
          X |  1,069,626       30.64      100.00
------------+-----------------------------------
      Total |  3,491,257      100.00
	  
	  CdTbl	CdVal	CdDesc
LSTCAT	A  	ACTIVE
LSTCAT	D  	DELETED
LSTCAT	S  	SOLD
LSTCAT	U  	PENDING
LSTCAT	X  	EXPIRED (INCLUDES WITHDRAWN, CANCELLED, TERMINATED, INACTIVE, ETC.)

*/


/*

#delimit;

clear all;
cd /Users/ranciere/Dropbox/data_sources/Corelogic;
odbc query "PostgreSQLDB", dialog(complete) user(ranciere) password(usc2024!!);
odbc load, exec ("SELECT * FROM mortgage.output_table " )  dsn("postgreSQLDB");





g refi=1 if mortgage_type_code=="R";
g junior=1 if mortgage_type_code=="J";
g purchase=1 if mortgage_type_code=="P";


/*
foreach var of varlist transaction_year-fixed_rate_indicator mortgage_interest_rate-purchase{
	destring `var', g(`var'n) force
}
;
*/


/*

mortgage_ty |
    pe_code |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |          2        0.00        0.00
          F |         11        0.00        0.00
          J |  6,119,423       25.51       25.51
          P |  7,385,919       30.79       56.30
          R | 10,483,306       43.70      100.00
------------+-----------------------------------
      Total | 23,988,661      100.00
*/


rename transaction_monthn month;
rename transaction_yearn year;

g id==1


save mortgage.dta, replace;


/*


collapse (sum) id refi junior purchase  (mean) mortgage_interest_raten mortgage_amountn, by(month year)

gen day=1
g date=mdy(month,day,year)
format date %td

*/



*SAN FRANCISCO

/*
odbc load, exec("SELECT clip, fips_code, listing_id_standardized, listing_type, listing_status_category_code_standardized, listing_status_code_standardized, listing_transaction_type_code_derived, listing_date, original_listing_date, close_date, close_date_standardized, days_on_market_dom, days_on_market_dom_cumulative, original_listing_date_and_time_standardized, last_listing_date_and_time_standardized, close_price, current_listing_price, original_listing_price, price_per_square_foot FROM mls.listings  WHERE  fips_code='06075' OR fips_code='06002' OR  fips_code='06013' OR  fips_code='06081'  OR fips_code='06041' ") dsn("postgreSQLDB")
*/

*LOS ANGELES

/*
odbc load, exec("SELECT clip, fips_code, listing_id_standardized, listing_type, listing_status_category_code_standardized, listing_status_code_standardized, listing_transaction_type_code_derived, listing_date, original_listing_date, close_date, close_date_standardized, days_on_market_dom, days_on_market_dom_cumulative, original_listing_date_and_time_standardized, last_listing_date_and_time_standardized, close_price, current_listing_price, original_listing_price, price_per_square_foot FROM mls.listings  WHERE  fips_code='06037' OR fips_code='06059' OR  fips_code='06065' OR  fips_code='06071'  OR fips_code='06111' ") dsn("postgreSQLDB")
*/

***MORTGAGE BASIC BLOCK


*odbc load, exec("SELECT COUNT (*) FROM mortgage.basics WHERE  fips_code='06037' OR fips_code='06059' OR  fips_code='06065' OR  fips_code='06071'  OR fips_code='06111' ") dsn("postgreSQLDB")
 
/*SQL command
 
 
 "SELECT transaction_batch_date, SUBSTRING(transaction_batch_date FROM 1 FOR 4) as transaction_year FROM mortgage.basics"

 
 SELECT ZIPCode, Year, AVG(Price) AS AveragePrice FROM ownertransfer GROUP BY ZIPCode, Year ORDER BY ZIPCode, Year;
 
 
 */

 /*
odbc load, exec("SELECT clip, fips_code, mortgage_composite_transaction_id, transaction_batch_date, mortgage_interest_rate_type_code, mortgage_interest_rate, fixed_rate_indicator, variable_rate_loan_indicator FROM mortgage.basics WHERE  fips_code='06037' OR fips_code='06059' OR  fips_code='06065' OR  fips_code='06071'  OR fips_code='06111' ") dsn("postgreSQLDB")
*/

/*

odbc load, exec ("SELECT clip, fips_code, transaction_batch_date, SUBSTRING(transaction_batch_date FROM 1 FOR 4) as transaction_year, SUBSTRING(transaction_batch_date FROM 5 FOR 2) as transaction_month,
       variable_rate_loan_indicator,
       fixed_rate_indicator
FROM mortgage.basics WHERE  fips_code='06037' OR fips_code='06059' OR  fips_code='06065' OR  fips_code='06071'  OR fips_code='06111' ") dsn("postgreSQLDB");
 */
 
 
 
/*mortgage_loan_type_code, refinance_loan_indicator, mortgage_purpose_code, mortgage_arm_initial_reset_date, mortgage_type_code   */ 


/*

foreach var of varlist transaction_year-fixed_rate_indicator{
	destring `var', g(`var'n) force
}
;

save mortgage.dta, replace;

collapse (mean) variable_rate_loan_indicatorn fixed_rate_indicatorn   , by(year);

*/


 
***END MORTAGE BASIC BLOCK**

/*
g year_cl=substr(close_date,1,4)
destring year_cl, g(year_close) force
g month_cl=substr(close_date,6,2)
destring month_cl, g(month_close) force

destring days_on_market_dom, g(dom) force
destring days_on_market_dom_cumulative, g(dom_cum) force

g dom_s=dom_cum if dom_cum!=.
replace dom_s=dom if dom_cum==.

g id=1 if listing_id_standardized!=""

destring price_per_square_foot, g(price_sf) force
destring close_price, g(price) force
destring current_listing_price, g(current_price) force
destring original_listing_price, g(original_price) force


g close_to_current_p = price/current_price
g close_to_original_p= price/original_price

*Check Below

/*
bysort year_close : sum id if var7=="S" & year_close<2025
bysort year_close : sum dom_s if var5=="S" & year_close<2025
bysort year_listing : sum id if year_close<2024 & var5=="S" & var7=="S"

*/


/*
 tab var5

listing_sta |
tus_categor |
y_code_stan |
   dardized |      Freq.     Percent        Cum.
------------+-----------------------------------
          A |     21,134        0.61        0.61
          D |         33        0.00        0.61
          S |  2,391,585       68.50       69.11
          U |      8,879        0.25       69.36
          X |  1,069,626       30.64      100.00
------------+-----------------------------------
      Total |  3,491,257      100.00
	  
	  CdTbl	CdVal	CdDesc
LSTCAT	A  	ACTIVE
LSTCAT	D  	DELETED
LSTCAT	S  	SOLD
LSTCAT	U  	PENDING
LSTCAT	X  	EXPIRED (INCLUDES WITHDRAWN, CANCELLED, TERMINATED, INACTIVE, ETC.)

tab var 7

listing_tra |
nsaction_ty |
pe_code_der |
       ived |      Freq.     Percent        Cum.
------------+-----------------------------------
          R |    297,965        8.53        8.53
          S |  3,193,575       91.47      100.00
------------+-----------------------------------
      Total |  3,491,540      100.00


*/

*/