{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM movielens_rds_zeroetl.public.ratings
)
SELECT 
    "userId" as userid,
    "movieId" as movieid,
    rating,
    timestamp AS rating_timestamp
FROM source
