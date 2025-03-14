{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM movielens_rds_zeroetl.public.links
)
SELECT 
    movieid,
    imdbid,
    tmdbid
FROM source
