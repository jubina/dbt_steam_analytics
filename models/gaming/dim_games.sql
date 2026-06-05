-- models/gaming/dim_games.sql
-- Dimension model: game catalog with genre taxonomy and era classification.
-- Provides stable attributes for joining to fact models.
-- One row per game.

with staged as (
    select * from {{ ref('stg_steam_games') }}
),

enriched as (
    select
        app_id,
        game_title,
        genre,
        subgenre,
        release_year,
        platform,
        purchase_price_usd,
        achievements_total,

        -- era bucketing
        case
            when release_year < 2010 then 'Classic (pre-2010)'
            when release_year < 2015 then 'Mid Era (2010-2014)'
            when release_year < 2020 then 'Modern (2015-2019)'
            else                          'Current (2020+)'
        end as release_era,

        -- price tier
        case
            when purchase_price_usd = 0     then 'Free to Play'
            when purchase_price_usd < 15    then 'Budget'
            when purchase_price_usd < 40    then 'Mid-Range'
            else                                 'Premium'
        end as price_tier,

        -- is this a roguelike/roguelite?
        case
            when genre = 'roguelike'
              or subgenre = 'roguelike' then true
            else false
        end as is_roguelike,

        -- achievement-heavy game flag (>100 achievements)
        case
            when achievements_total > 100 then true
            else false
        end as is_achievement_heavy

    from staged
)

select * from enriched