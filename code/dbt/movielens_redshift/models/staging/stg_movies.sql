{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM movielens_rds_zeroetl.public.movies
)
SELECT 
    "movieId" as movieid,
    title,
    genres
FROM source
