1. MLS prepares data on transactions,listings (including active listing) and prices at transaction and zip level
2.  Mortgage pepares date on mortgages  at transaction and zip level
3.  Merge_MLS_Mortgage merge at --a) transaction level (within a data range) final output ZIP---b) zip level ZIP_ZIP
4.  Important Features: Cleaning for Duplicates. This is key
5.  New Features; In addition to transactions, and active listing, I added Expired listing (listing ending up with no sales)
6.  Key Variable: DOM. days on markets. I produced active listing using the range listing_date+dom so if dom is not good, we are screwed.
7.  Notes: Listing Prices are computing with only Listing that end up with sales. (this is not necessary but is important to produce List_Price/Price)
8.  At the zip level, I produce p25,p50,p75 of variables (except the ones that is a count -- transactions, sales..)
9.  MLS.do is the stata code
10. Matching_Buyer_Seller produces the pair of buyer-seller within 12 months following the same procedure as in Bayer-Annenber IER
11. 
