DROP TABLE IF EXISTS buyer_table;
CREATE TABLE buyer_table AS
SELECT
    sale_derived_date, buyer_1_last_name, buyer_2_last_name,
    SUBSTRING(buyer_1_first_name_and_middle_initial FROM 1 FOR 4) as buyer_1_first_name,
    SUBSTRING(buyer_2_first_name_and_middle_initial FROM 1 FOR 4) as buyer_2_first_name,
    TO_DATE(SUBSTRING(sale_derived_date FROM 1 FOR 8), 'YYYYMMDD') AS sale_date
    FROM ownertransfer_comprehensive
    WHERE interfamily_related_indicator='0'
      AND property_indicator_code___static='10'
      AND  (fips_code='06037' OR fips_code='06059')
AND deed_category_type_code='G';

DROP TABLE IF EXISTS seller_table;
CREATE TABLE seller_table AS
SELECT sale_derived_date, seller_1_last_name,
        SUBSTR(seller_1_first_name FROM 1 FOR 4) as seller_1_first_name,
       TO_DATE(SUBSTRING(sale_derived_date FROM 1 FOR 8), 'YYYYMMDD') AS sale_date
             FROM ownertransfer_comprehensive
    WHERE interfamily_related_indicator='0'
   AND property_indicator_code___static='10'
  AND  (fips_code='06037' OR fips_code='06059')
AND deed_category_type_code='G';

CREATE INDEX idx_buyer1_last_name ON buyer_table(buyer_1_last_name);
CREATE INDEX idx_buyer2_last_name ON buyer_table(buyer_2_last_name);

CREATE INDEX idx_buyer1_first_name ON buyer_table(buyer_1_first_name);
CREATE INDEX idx_buyer2_first_name ON buyer_table(buyer_2_first_name);

CREATE INDEX idx_seller1_last_name ON seller_table(seller_1_last_name);
CREATE INDEX idx_seller1_first_name ON seller_table(seller_1_first_name);

CREATE INDEX idx_buyer_sale_date ON buyer_table (sale_date);
CREATE INDEX idx_seller_sale_date ON seller_table (sale_date);


DROP TABLE IF EXISTS INTERNAL_TRANSACTION;
CREATE TABLE INTERNAL_TRANSACTION AS
SELECT
    m.buyer_1_last_name,
    m.buyer_1_first_name,
    m.buyer_2_first_name,
    m.buyer_2_last_name,
    m.sale_date as buyer_close,
    t.seller_1_last_name,
    t.seller_1_first_name,
    t.sale_date as seller_close
FROM
    buyer_table m
INNER JOIN
    seller_table t
ON
    ( m.buyer_1_last_name=t.seller_1_last_name OR m.buyer_2_last_name=t.seller_1_last_name)
    AND
   (m.buyer_1_first_name=t.seller_1_first_name OR m.buyer_2_first_name=t.seller_1_first_name)
    AND
    ABS(EXTRACT(EPOCH FROM AGE( m.sale_date, t.sale_date))/ 86400) <= 365
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