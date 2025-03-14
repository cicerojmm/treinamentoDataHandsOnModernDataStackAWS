{{ config(materialized='ephemeral') }}

WITH user_activity AS (
    SELECT 
        userId,
        COUNT(DISTINCT movieId) AS unique_movies_rated,
        COUNT(*) AS total_ratings,
        ROUND(AVG(rating), 2) AS avg_rating
    FROM {{ ref('stg_ratings') }}
    GROUP BY userId
)
SELECT * FROM user_activity
