{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM movielens_rds_zeroetl.public.links
)
SELECT 
    "movieId" as movieid,
    "imdbId" as imdbd,
    "tmdbId" as tmdbid
FROM source
