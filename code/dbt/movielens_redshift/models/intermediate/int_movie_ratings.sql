{{ config(materialized='ephemeral') }}

WITH movie_ratings AS (
    SELECT 
        movieId,
        ROUND(AVG(rating), 2) AS avg_rating,
        COUNT(rating) AS total_ratings
    FROM {{ ref('stg_ratings') }}
    GROUP BY movieId
)
SELECT 
    m.movieId,
    m.title,
    mr.avg_rating,
    mr.total_ratings
FROM {{ ref('stg_movies') }} m
LEFT JOIN movie_ratings mr ON m.movieId = mr.movieId
