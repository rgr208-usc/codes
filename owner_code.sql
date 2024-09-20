DROP TABLE IF EXISTS table_full;
CREATE TABLE table_full AS
SELECT
    NULLIF(REGEXP_REPLACE( owner_transfer_composite_transaction_id,'[^0-9.]+', '', 'g'), '')::bigint as transaction_id,
    SUBSTRING(buyer_1_first_name_and_middle_initial FROM 1 FOR 4) as buyer_1_first_name,
    buyer_1_last_name,
    SUBSTRING(buyer_2_first_name_and_middle_initial FROM 1 FOR 4) as buyer_2_first_name,
     buyer_2_last_name,
    SUBSTRING(seller_1_first_name FROM 1 FOR 4) as seller_1_first_name,
    seller_1_last_name,
    TO_DATE(SUBSTRING(sale_derived_date FROM 1 FOR 8), 'YYYYMMDD') AS date
    FROM ownertransfer_comprehensive
    WHERE interfamily_related_indicator='0' --no family transfer
      AND primary_category_code='A'  --arm length
      AND property_indicator_code___static='10' -- single family
      AND  (fips_code='06037' OR fips_code='06059') --LA MSA
AND seller_1_last_name!='' AND seller_1_first_name!='' AND buyer_1_first_name_and_middle_initial!=''
                  AND buyer_1_last_name!='' --non missing name
                  AND TO_DATE(SUBSTRING(sale_derived_date FROM 1 FOR 8), 'YYYYMMDD')>'2015-01-01' --time sample
AND TO_DATE(SUBSTRING(sale_derived_date FROM 1 FOR 8), 'YYYYMMDD')<'2024-01-01'
 ;

/*
CREATE INDEX idx_buyer1 ON buyer_table(buyer_1_last_name, buyer_1_first_name, sale_date);
CREATE INDEX idx_seller1 ON seller_table(seller_1_last_name, seller_1_first_name,sale_date);
*/

DROP TABLE IF EXISTS table1;
CREATE TABLE table1 (
    id SERIAL PRIMARY KEY,
   name1 TEXT, name2 TEXT,  date1 DATE
                    --, id2 BIGINT
);


DROP TABLE IF EXISTS table2;
CREATE TABLE table2 (
    id SERIAL PRIMARY KEY,
   name3 TEXT, name4 TEXT, date2 DATE

                    ---, id3 BIGINT
);

INSERT INTO table1 (name1)
select buyer_1_first_name from table_full;
INSERT INTO table1 (name2)
select buyer_1_last_name from table_full;
INSERT INTO table1 (date1)
select date from table_full;
--INSERT INTO table1 (id2)
--select transaction_id from table_full;


INSERT INTO table2 (name3)
select seller_1_first_name from table_full;
INSERT INTO table2 (name4)
select seller_1_last_name from table_full;
INSERT INTO table2 (date2)
select date from table_full;
--INSERT INTO table2 (id3)
--select transaction_id from table_full;

DROP TABLE IF EXISTS INTERNAL_TRANSACTION;
CREATE TABLE INTERNAL_TRANSACTION AS
SELECT
m.*,
t.*
FROM
   table1 m
INNER JOIN
    table2 t
ON
     m.name1=t.name3 AND m.name2=t.name4 AND
    ABS(EXTRACT(EPOCH FROM AGE( m.date1, t.date2))/ 86400) <= 365
;


/*


DROP TABLE IF EXISTS table1;
CREATE TABLE table1 (
    id SERIAL PRIMARY KEY,
    name1 TEXT
);
DROP TABLE IF EXISTS table2;
CREATE TABLE table2 (
    id SERIAL PRIMARY KEY,
    name2 TEXT
);

INSERT INTO table1 (name1)
select buyer_1_last_name from output_table;

INSERT INTO table2 (name2)
select seller_1_last_name from output_table;



--Exact match
DROP TABLE IF EXISTS match;
CREATE INDEX idx_table1_name1_hash ON table1((md5(name1))); CREATE INDEX idx_table2_name2_hash ON table2((md5(name2)));
CREATE TABLE match AS
SELECT
    t1.id AS id1,
    t1.name1,
    t2.id AS id2,
    t2.name2
  FROM
    table1 t1

  LEFT JOIN
   table2 t2 ON md5(t1.name1) = md5(t2.name2);
;

select * from match
/*
CREATE TABLE match AS
(SELECT
    t1.id AS id1,
    t1.name1,
    t2.id AS id2,
    t2.name2,
    similarity(t1.name1, t2.name2) AS similarity_score
/*levenshtein()* trim(Levenshtein( , )) spacing  */
FROM
    table1 t1
JOIN
    table2 t2 ON similarity(t1.name1, t2.name2) > 0.2
ORDER BY
    similarity_score DESC);
---with CBT
--Alternative: Using a CTE for Better Performance
--For large datasets, you might consider using a Common Table Expression (CTE) to store intermediate results:

WITH similar_names AS (
    SELECT
        t1.id AS id1,
        t1.name1,
        t2.id AS id2,
        t2.name2,
        similarity(t1.name1, t2.name2) AS similarity_score
    FROM
        table1 t1
    CROSS JOIN
        table2 t2
    WHERE
        similarity(t1.name1, t2.name2) > 0.2
)
SELECT *
FROM similar_names
ORDER BY similarity_score DESC;


-- Set similarity threshold
SET pg_trgm.similarity_threshold = 0.3; -- Adjust the threshold as needed

-- Perform fuzzy join
SELECT
    t1.id AS t1_id,
    t1.name AS t1_name,
    t2.id AS t2_id,
    t2.name AS t2_name,
    similarity(t1.name, t2.name) AS similarity
FROM
    table1 t1
JOIN
    table2 t2
ON
    t1.name % t2.name -- % operator for similarity match
ORDER BY
    similarity DESC;

-- levenshtein

SELECT
    t1.id AS t1_id,
    t1.name AS t1_name,
    t2.id AS t2_id,
    t2.name AS t2_name,
    levenshtein(t1.name, t2.name) AS distance
FROM
    table1 t1
JOIN
    table2 t2
ON
    levenshtein(t1.name, t2.name) <= 2 -- Adjust the threshold as needed
ORDER BY
    distance;


 */