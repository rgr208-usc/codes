--SANDBOX CODE 

DROP TABLE IF EXISTS Eagle_Rock;
CREATE TABLE Eagle_Rock AS
SELECT
    TO_DATE(SUBSTRING(sale_derived_date FROM 1 FOR 8), 'YYYYMMDD') as date,
     primary_category_code,
     investor_purchase_indicator,
     owner_transfer_composite_transaction_id,
     buyer_1_corporate_indicator,
     buyer_1_first_name_and_middle_initial,
    SUBSTRING(buyer_1_first_name_and_middle_initial FROM 1 FOR 4) as buyer_1_first_name,
     buyer_1_last_name,
     buyer_2_first_name_and_middle_initial,
    SUBSTRING(buyer_2_first_name_and_middle_initial FROM 1 FOR 4) as buyer_2_first_name,
    CASE WHEN seller_1_last_name!='' AND seller_1_first_name!='' AND buyer_1_first_name_and_middle_initial!=''
                  AND buyer_1_last_name!='' THEN 1 ELSE 0 END AS non_missing,
   buyer_2_last_name, seller_1_last_name, seller_1_first_name, seller_2_full_name
FROM ownertransfer_comprehensive  WHERE
      interfamily_related_indicator='0'
      AND property_indicator_code___static='10'
      AND  (fips_code='06037' OR fips_code='06059')
     AND deed_category_type_code='G'
    AND interfamily_related_indicator='0' AND  substring(deed_situs_zip_code___static FROM 1 FOR 5) ='90041'
AND TO_DATE(SUBSTRING(sale_derived_date FROM 1 FOR 8), 'YYYYMMDD')>'2021-01-01'
AND TO_DATE(SUBSTRING(sale_derived_date FROM 1 FOR 8), 'YYYYMMDD')<'2024-01-01'
AND seller_1_last_name!='' AND seller_1_first_name!='' AND buyer_1_first_name_and_middle_initial!='' AND buyer_1_last_name!=''
;

select * from Eagle_Rock order by date


select date, buyer_1_first_name,
       buyer_1_last_name, buyer_2_first_name, buyer_2_last_name, seller_1_first_name,   seller_1_last_name, seller_2_full_name
from Eagle_Rock order by date
