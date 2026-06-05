-- models/gaming/stg_steam_platform.sql
-- Staging model: clean and type raw Steam platform data from Steam Spy.
-- One row per game. Standardizes types, derives cost_per_hour,
-- and flags free-to-play games.

with source as (
    select * from {{ ref('raw_steam_platform') }}
),

cleaned as (
    select
        cast(appid                      as int64)   as appid,
        trim(name)                                   as game_title,
        lower(trim(primary_genre))                   as primary_genre,
        lower(trim(secondary_genre))                 as secondary_genre,
        cast(price_usd                  as numeric)  as price_usd,
        cast(is_free                    as bool)     as is_free,
        cast(owners_estimate            as int64)    as owners_estimate,
        cast(players_2weeks             as int64)    as players_2weeks,
        cast(avg_playtime_forever_hrs   as numeric)  as avg_playtime_forever_hrs,
        cast(avg_playtime_2weeks_hrs    as numeric)  as avg_playtime_2weeks_hrs,
        cast(median_playtime_hrs        as numeric)  as median_playtime_hrs,
        cast(positive_reviews           as int64)    as positive_reviews,
        cast(negative_reviews           as int64)    as negative_reviews,
        cast(total_reviews              as int64)    as total_reviews,
        cast(review_score               as numeric)  as review_score,
        cast(pulled_at                  as date)     as pulled_at,

        -- derived
        safe_divide(
            cast(price_usd as numeric),
            cast(avg_playtime_forever_hrs as numeric)
        ) as cost_per_hour

    from source
    where name is not null
      and avg_playtime_forever_hrs >= 0
)

select * from cleaned
