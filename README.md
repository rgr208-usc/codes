1. MLS_sql prepares data on transactions,listings (including active listing) and prices at transaction and zip level
2.  Mortgage_sql pepares date on mortgages  at transaction and zip level
3.  Merge_MLS_MTH merge at --a) transaction level (within a data range)---b) zip level
4.  Important Features: Cleaning for Duplicates. This is key
5.  New Features; In addition to transactions, and active listing, I added Expired listing (listing ending up with no sales)
6.  Key Variable: DOM. days on markets. I produced active listing using the range listing_date+dom so if dom is not good, we are screwed.
7.  MLS.do is the stata code
