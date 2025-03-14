{{ config(materialized='table') }}

SELECT 
    m.movieId,
    m.title,
    m.genres,
    r.avg_rating,
    r.total_ratings
FROM {{ ref('stg_movies') }} m
LEFT JOIN {{ ref('int_movie_ratings') }} r ON m.movieId = r.movieId
