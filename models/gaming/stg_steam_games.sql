-- models/gaming/stg_steam_games.sql
-- Staging model: clean and type raw Steam library data.
-- One row per game. Standardizes types, nulls out missing values,
-- and derives a simple completion_pct from achievements.

with source as (
    select * from {{ ref('raw_steam_library') }}
),

cleaned as (
    select
        cast(app_id               as int64)   as app_id,
        trim(game_title)                       as game_title,
        lower(trim(genre))                     as genre,
        lower(trim(subgenre))                  as subgenre,
        cast(release_year         as int64)    as release_year,
        cast(purchase_price_usd   as numeric)  as purchase_price_usd,
        cast(playtime_hours       as numeric)  as playtime_hours,
        cast(last_played          as date)     as last_played,
        cast(achievements_earned  as int64)    as achievements_earned,
        cast(achievements_total   as int64)    as achievements_total,
        lower(trim(platform))                  as platform,

        -- derived
        safe_divide(
            cast(achievements_earned as numeric),
            cast(achievements_total  as numeric)
        ) as achievement_completion_pct

    from source
    where game_title is not null
      and playtime_hours >= 0
)

select * from cleaned