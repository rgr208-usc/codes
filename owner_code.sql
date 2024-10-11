--notes seller2 full name is almost never informed
DROP TABLE IF EXISTS table_full;
CREATE TABLE table_full AS
SELECT
    NULLIF(REGEXP_REPLACE( owner_transfer_composite_transaction_id,'[^0-9.]+', '', 'g'), '')::bigint as transaction_id,
    SUBSTRING(buyer_1_first_name_and_middle_initial FROM 1 FOR 4) as buyer_1_first_name,
    buyer_1_last_name,
    SUBSTRING(buyer_2_first_name_and_middle_initial FROM 1 FOR 4) as buyer_2_first_name,
     buyer_2_last_name,
     SUBSTRING(buyer_3_first_name_and_middle_initial FROM 1 FOR 4) as buyer_3_first_name,
     buyer_3_last_name,
     SUBSTRING(buyer_4_first_name_and_middle_initial FROM 1 FOR 4) as buyer_4_first_name,
     buyer_4_last_name,
    SUBSTRING(seller_1_first_name FROM 1 FOR 4) as seller_1_first_name,
    seller_1_last_name,
    TO_DATE(SUBSTRING(sale_derived_date FROM 1 FOR 8), 'YYYYMMDD') AS date
    FROM ownertransfer_comprehensive
    WHERE interfamily_related_indicator='0' --no family transfer
      AND primary_category_code='A'  --arm length
      AND property_indicator_code___static='10' -- single family
      AND  (fips_code='06037' OR fips_code='06059') --LA MSA
AND TO_DATE(SUBSTRING(sale_derived_date FROM 1 FOR 8), 'YYYYMMDD')>'2010-01-01' --time sample
AND TO_DATE(SUBSTRING(sale_derived_date FROM 1 FOR 8), 'YYYYMMDD')<'2024-01-01'
 ;

---prepare the buyer and seller tables

DROP TABLE IF EXISTS table1;
CREATE TABLE table1 AS
    SELECT transaction_id as buyer_transaction_id,buyer_1_first_name, buyer_1_last_name, buyer_2_first_name, buyer_2_last_name
    ,buyer_3_first_name, buyer_3_last_name, buyer_4_first_name, buyer_4_last_name
     ,date as buyer_date
    FROM table_full;
ALTER TABLE table1 ADD COLUMN id_b SERIAL PRIMARY KEY;

DROP TABLE IF EXISTS table2;
CREATE TABLE table2 AS
    SELECT transaction_id as seller_transaction_id,seller_1_first_name, seller_1_last_name, date as seller_date
    FROM table_full;
ALTER TABLE table2 ADD COLUMN id_s SERIAL PRIMARY KEY;

---

--ROUND 1 Match on Buyer 1 / Seller 1

DROP TABLE IF EXISTS INTERNAL_TRANSACTION1;
CREATE TABLE INTERNAL_TRANSACTION1 AS
SELECT
m.*,
t.*
FROM
   table1 m
INNER JOIN
    table2 t
ON
     m.buyer_1_first_name=t.seller_1_first_name AND m.buyer_1_last_name=t.seller_1_last_name
         AND
    ABS(EXTRACT(EPOCH FROM AGE( m.buyer_date, t.seller_date))/ 86400) <= 365
WHERE t.seller_1_last_name!='' AND t.seller_1_first_name!=''
;
--select buyer_transaction_id,count(*) as count from internal_transaction2 group by buyer_transaction_id order by count DESC

--ROUND 2 Match on Buyer 2 / Seller 1

DROP TABLE IF EXISTS INTERNAL_TRANSACTION2;
CREATE TABLE INTERNAL_TRANSACTION2 AS
SELECT
m.*,
t.*
FROM
   table1 m
INNER JOIN
    table2 t
ON
      m.buyer_2_first_name=t.seller_1_first_name AND m.buyer_2_last_name=t.seller_1_last_name
         AND
    ABS(EXTRACT(EPOCH FROM AGE( m.buyer_date, t.seller_date))/ 86400) <= 365
WHERE
t.seller_1_last_name!='' AND t.seller_1_first_name!=''
;

---ROUND3

DROP TABLE IF EXISTS INTERNAL_TRANSACTION3;
CREATE TABLE INTERNAL_TRANSACTION3 AS
SELECT
m.*,
t.*
FROM
   table1 m
INNER JOIN
    table2 t
ON
      m.buyer_3_first_name=t.seller_1_first_name AND m.buyer_3_last_name=t.seller_1_last_name

         AND
    ABS(EXTRACT(EPOCH FROM AGE( m.buyer_date, t.seller_date))/ 86400) <= 365
WHERE t.seller_1_last_name!='' AND t.seller_1_first_name!=''
;

---ROUND4

DROP TABLE IF EXISTS INTERNAL_TRANSACTION4;
CREATE TABLE INTERNAL_TRANSACTION4 AS
SELECT
m.*,
t.*
FROM
   table1 m
INNER JOIN
    table2 t
ON
      m.buyer_4_first_name=t.seller_1_first_name AND m.buyer_4_last_name=t.seller_1_last_name
         AND
    ABS(EXTRACT(EPOCH FROM AGE( m.buyer_date, t.seller_date))/ 86400) <= 365
WHERE t.seller_1_last_name!='' AND t.seller_1_first_name!=''
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

select count(distinct id_s) from internal_transaction
select count(distinct transaction_id) from table_full
select count(distinct transaction_id) from table_full
WHERE seller_1_last_name!='' AND seller_1_first_name!=''
AND
(
    (buyer_1_first_name!='' AND buyer_1_last_name!='')
    OR
    (buyer_2_first_name!='' AND buyer_2_last_name!='')
    OR
    (buyer_3_first_name!='' AND buyer_3_last_name!='')
    OR
    (buyer_4_first_name!='' AND buyer_4_last_name!='')
    )
;

select count(distinct id_b) from internal_transaction2
select count(*) from internal_transaction2

 */
