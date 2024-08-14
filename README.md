MLS_SQL produces a zip-month level MLS dataset
The key feature is that it re-creates active listing for any zip-month then merge with MLS at the zip-month
MTG_SQL produces a zip level Mortgage dataset and then match at the zip-month level with MLS (including listing)
Note:MLS_SQL should be run before MTG_SQL
MERGE_MLS_MTH merge between MLS and MTG at the transaction level. Key to obtain LTV, then collapse at zip_month and merge with active listing
All join are LEFT JOIN with MLS on the left
MLS codes include a purging for duplicates
