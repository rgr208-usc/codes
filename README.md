MLS_SQL produces a zip-month level MLS dataset \\
The key feature is that it re-creates active listings for any zip-month then merges with MLS at the zip-month \\ ****Final ouptut table zip in public \\
MTG_SQL produces a zip level Mortgage dataset and then matches at the zip-month level with MLS (including listing) \\  ****Final ouptut table zip_mls_mortgage in public \\
Note:MLS_SQL should be run before MTG_SQL \\
MERGE_MLS_MTH merge between MLS and MTG at the **transaction level**. Key to obtain LTV, then collapse at zip_month and merge with active listing \\****Final ouptut table merge in public \\
All join are LEFT JOIN with MLS on the left \\
MLS codes include a purging for duplicates \ this is important
