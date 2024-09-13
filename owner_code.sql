DROP TABLE output_table;
CREATE TABLE output_table AS
    (SELECT clip, transaction_batch_date, buyer_1_full_name, buyer_2_full_name, seller_1_full_name,
            seller_2_full_name FROM ownertransfer_comprehensive
    WHERE interfamily_related_indicator='0' AND  (fips_code='06037' OR fips_code='06059' OR  fips_code='06065' OR  fips_code='06071'
       OR fips_code='06111')
                                                                                                       ) ;
drop TABLE table1;
CREATE TABLE table1 (
    id SERIAL PRIMARY KEY,
    name1 TEXT
);
drop TABLE table2;
CREATE TABLE table2 (
    id SERIAL PRIMARY KEY,
    name2 TEXT
);

INSERT INTO table1 (name1)
select buyer_1_full_name from output_table;

INSERT INTO table2 (name2)
select seller_1_full_name from output_table;


CREATE INDEX idx_name1_trgm ON table1 USING gin (name1 gin_trgm_ops);
CREATE INDEX idx_name2_trgm ON table2 USING gin (name2 gin_trgm_ops);

--


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