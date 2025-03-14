{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM movielens_rds_zeroetl.public.movies
)
SELECT 
    movieid,
    title,
    genres
FROM source
