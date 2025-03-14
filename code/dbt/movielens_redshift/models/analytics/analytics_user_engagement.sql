{{ config(materialized='table') }}

SELECT 
    userId,
    unique_movies_rated,
    total_ratings,
    avg_rating
FROM {{ ref('int_user_profiles') }}
ORDER BY total_ratings DESC
