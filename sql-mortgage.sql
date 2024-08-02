

DROP TABLE IF EXISTS MLS;
CREATE TABLE MLS AS
SELECT TO_DATE(SUBSTRING(close_date_standardized FROM 1 FOR 10), 'YYYY-MM-DD') AS closedate
    FROM mls.listings
WHERE listing_status_category_code_standardized='S';

DROP TABLE IF EXISTS MTG;
CREATE TABLE MTG AS
SELECT TO_CHAR(TO_DATE(mortgage_recording_date, 'YYYYMMDD'), 'YYYY-MM-DD') AS formatted_date
    FROM mortgage.basics

;

---





----DATE CLOSE


SELECT
    o.order_id,
    o.order_date,
    s.shipment_id,
    s.shipment_date
FROM
    orders o
JOIN
    shipments s
ON
    ABS(o.order_date - s.shipment_date) < INTERVAL '10 days';


/*
SELECT   zip,
        COUNT(*) AS count
FROM Mortgage_Num
GROUP BY zip
ORDER BY count DESC;

*/
 --Sale Derived Date > Sale Derived Recording Date Transaction Batch Date


