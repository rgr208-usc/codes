
--BUYER-SELLER MATCHING CODE

-- you can exclude when Buy and Sell same property
-- buyer is much more informed than seller
--notes seller2 full name is almost never informed

DROP TABLE IF EXISTS table_full;
CREATE TABLE table_full AS
SELECT
    NULLIF(REGEXP_REPLACE(clip,'[^0-9.]+', '', 'g'), '')::bigint as clip,
    NULLIF(REGEXP_REPLACE( owner_transfer_composite_transaction_id,'[^0-9.]+', '', 'g'), '')::bigint as transaction_id,
    SUBSTRING(buyer_1_first_name_and_middle_initial FROM 1 FOR 3) as buyer_1_first_name,
    buyer_1_last_name,
    SUBSTRING(buyer_2_first_name_and_middle_initial FROM 1 FOR 3) as buyer_2_first_name,
     buyer_2_last_name,
     SUBSTRING(buyer_3_first_name_and_middle_initial FROM 1 FOR 3) as buyer_3_first_name,
     buyer_3_last_name,
     SUBSTRING(buyer_4_first_name_and_middle_initial FROM 1 FOR 3) as buyer_4_first_name,
     buyer_4_last_name,
    SUBSTRING(seller_1_first_name FROM 1 FOR 4) as seller_1_first_name,
    seller_1_last_name,
    TO_DATE(SUBSTRING(sale_derived_date FROM 1 FOR 8), 'YYYYMMDD') AS date,
    EXTRACT (MONTH FROM  TO_DATE(SUBSTRING(sale_derived_date FROM 1 FOR 8), 'YYYYMMDD')) AS month,
    EXTRACT (YEAR FROM  TO_DATE(SUBSTRING(sale_derived_date FROM 1 FOR 8), 'YYYYMMDD')) AS year
    FROM ownertransfer_comprehensive
    WHERE interfamily_related_indicator='0' --no family transfer
     AND investor_purchase_indicator='0'  -- no investor very bad for the matching -- very very poorly indicated
      AND primary_category_code='A'  --arm length
      AND (property_indicator_code___static='10' OR property_indicator_code___static='11')-- single family or condo --
      AND  (fips_code='06037' OR fips_code='06059') --LA MSA
AND TO_DATE(SUBSTRING(sale_derived_date FROM 1 FOR 8), 'YYYYMMDD')>'2000-01-01' --time sample
AND TO_DATE(SUBSTRING(sale_derived_date FROM 1 FOR 8), 'YYYYMMDD')<'2024-01-01'
 ;


---prepare the buyer and seller tables

DROP TABLE IF EXISTS table1;
CREATE TABLE table1 AS
    SELECT clip as buyer_clip, transaction_id as buyer_transaction_id,buyer_1_first_name, buyer_1_last_name, buyer_2_first_name, buyer_2_last_name
    ,buyer_3_first_name, buyer_3_last_name, buyer_4_first_name, buyer_4_last_name
     ,date as buyer_date
    FROM table_full
;

ALTER TABLE table1 ADD COLUMN id_b SERIAL PRIMARY KEY;

DROP TABLE IF EXISTS table2;
CREATE TABLE table2 AS
    SELECT clip as seller_clip, transaction_id as seller_transaction_id,seller_1_first_name, seller_1_last_name, date as seller_date
    FROM table_full
;
ALTER TABLE table2 ADD COLUMN id_s SERIAL PRIMARY KEY;

--ROUND 1 Match on Buyer 1 / Seller 1

DROP TABLE IF EXISTS INTERNAL_TRANSACTION1;
CREATE TABLE INTERNAL_TRANSACTION1 AS
SELECT
m.*,
t.*,
m.buyer_date-t.seller_date as  dif
FROM
   table1 m
INNER JOIN
    table2 t
ON
     m.buyer_1_first_name=t.seller_1_first_name AND m.buyer_1_last_name=t.seller_1_last_name
         AND ABS(EXTRACT(EPOCH FROM AGE( m.buyer_date, t.seller_date))/ 86400) <= 365
WHERE  m.buyer_1_first_name!='' AND m.buyer_1_last_name!='' AND t.seller_1_first_name!='' AND  t.seller_1_last_name!=''
;



    --select buyer_transaction_id,count(*) as count from internal_transaction2 group by buyer_transaction_id order by count DESC

--ROUND 2 Match on Buyer 2 / Seller 1

DROP TABLE IF EXISTS INTERNAL_TRANSACTION2;
CREATE TABLE INTERNAL_TRANSACTION2 AS
SELECT
m.*,
t.*,
m.buyer_date-t.seller_date as  dif
FROM
   table1 m
INNER JOIN
    table2 t
ON
      m.buyer_2_first_name=t.seller_1_first_name AND m.buyer_2_last_name=t.seller_1_last_name
         AND
    ABS(EXTRACT(EPOCH FROM AGE( m.buyer_date, t.seller_date))/ 86400) <= 365
WHERE m.buyer_2_first_name!='' AND m.buyer_2_last_name!='' AND t.seller_1_first_name!='' AND  t.seller_1_last_name!=''
;

---ROUND3

DROP TABLE IF EXISTS INTERNAL_TRANSACTION3;
CREATE TABLE INTERNAL_TRANSACTION3 AS
SELECT
m.*,
t.*,
m.buyer_date-t.seller_date as  dif
FROM
   table1 m
INNER JOIN
    table2 t
ON
      m.buyer_3_first_name=t.seller_1_first_name AND m.buyer_3_last_name=t.seller_1_last_name

         AND
    ABS(EXTRACT(EPOCH FROM AGE( m.buyer_date, t.seller_date))/ 86400) <= 365
WHERE m.buyer_3_first_name!='' AND m.buyer_3_last_name!='' AND t.seller_1_first_name!='' AND  t.seller_1_last_name!=''
;

---ROUND4

DROP TABLE IF EXISTS INTERNAL_TRANSACTION4;
CREATE TABLE INTERNAL_TRANSACTION4 AS
SELECT
m.*,
t.*,
m.buyer_date-t.seller_date as  dif
FROM
   table1 m
INNER JOIN
    table2 t
ON
      m.buyer_4_first_name=t.seller_1_first_name AND m.buyer_4_last_name=t.seller_1_last_name
         AND
    ABS(EXTRACT(EPOCH FROM AGE( m.buyer_date, t.seller_date))/ 86400) <= 365
 WHERE m.buyer_4_first_name!='' AND m.buyer_4_last_name!='' AND t.seller_1_first_name!='' AND  t.seller_1_last_name!=''
;

---- UNION (get rid of dubplicates by default)

DROP TABLE IF EXISTS INTERNAL_TRANSACTION;
CREATE TABLE  INTERNAL_TRANSACTION AS
SELECT * FROM INTERNAL_TRANSACTION1
UNION
SELECT * FROM INTERNAL_TRANSACTION2
UNION
SELECT * FROM INTERNAL_TRANSACTION3
UNION
SELECT * FROM INTERNAL_TRANSACTION4
;

--select count(distinct buyer_transaction_id) from INTERNAL_TRANSACTION

---Merge the Mstch in Principal Table

---- Create a Table with matched_transaction just exacted the id on the buyer side  -----


drop table if exists matched_transaction;
create table matched_transaction AS
select buyer_transaction_id, count(*) as count, AVG(dif) as dif from internal_transaction
group by buyer_transaction_id
-- where buyer_clip!=seller_clip -- to screen out the buy / sell of the same property within 12 months
;

--- Matching the initial table with matched transaction using left joint

drop table if exists  table_full_with_match;
create table table_full_with_match AS
select m.*, t.*
FROM table_full m
left join matched_transaction t
on m.transaction_id=t.buyer_transaction_id
;


---- counting

-- collapse as share of potential buyer matches
SELECT
   year, month, count(buyer_transaction_id) as match, count(transaction_id) as total, percentile_cont(0.5)WITHIN GROUP (ORDER BY count) AS count_50
    , 100*count(buyer_transaction_id)/count(transaction_id)  as share,  percentile_cont(0.5) WITHIN GROUP (ORDER BY dif) AS dif_50
    FROM table_full_with_match m
     WHERE
         count<2 -- single match
AND ( --to have share of matchable buyers aka buyers with name
         (m.buyer_1_first_name != '' AND m.buyer_1_last_name != '')
             OR (m.buyer_2_first_name != '' AND m.buyer_2_last_name != '')
             OR (m.buyer_3_first_name != '' AND m.buyer_3_last_name != '')
            OR (m.buyer_4_first_name != '' AND m.buyer_4_last_name != '')
         )
GROUP BY year, month
ORDER BY year, month
;



/*

---trying to get the serial matcher


drop table if exists matched_transaction_test;
create table matched_transaction_test AS
select buyer_transaction_id, buyer_1_first_name, buyer_1_last_name, count(*) as count from internal_transaction
group by buyer_transaction_id, buyer_1_first_name, buyer_1_last_name
order by count DESC
;

 */