-- models/gaming/fct_playtime.sql
-- Fact model: playtime and value metrics per game.
-- Answers: which games gave the best value per dollar?
--   What's completion rate by genre? Which genres dominate playtime?
-- One row per game.

with staged as (
    select * from {{ ref('stg_steam_games') }}
),

games as (
    select * from {{ ref('dim_games') }}
),

metrics as (
    select
        s.app_id,
        s.game_title,
        g.genre,
        g.subgenre,
        g.release_era,
        g.price_tier,
        g.is_roguelike,

        -- playtime
        s.playtime_hours,
        s.last_played,

        -- value metrics
        s.purchase_price_usd,
        safe_divide(s.purchase_price_usd, s.playtime_hours) as cost_per_hour,

        -- achievement metrics
        s.achievements_earned,
        s.achievements_total,
        s.achievement_completion_pct,

        -- engagement classification
        case
            when s.playtime_hours = 0        then 'Unplayed'
            when s.playtime_hours < 5        then 'Sampled'
            when s.playtime_hours < 20       then 'Played'
            when s.playtime_hours < 100      then 'Invested'
            else                                  'Obsessed'
        end as engagement_tier,

        -- value classification (cost per hour, lower = better)
        case
            when s.purchase_price_usd = 0    then 'Free'
            when safe_divide(s.purchase_price_usd, s.playtime_hours) < 1.00
                                             then 'Excellent Value'
            when safe_divide(s.purchase_price_usd, s.playtime_hours) < 3.00
                                             then 'Good Value'
            when safe_divide(s.purchase_price_usd, s.playtime_hours) < 10.00
                                             then 'Fair Value'
            else                                  'Poor Value'
        end as value_tier,

        -- days since last played
        date_diff(current_date(), s.last_played, day) as days_since_played,

        -- active flag (played in last 90 days)
        case
            when date_diff(current_date(), s.last_played, day) <= 90 then true
            else false
        end as is_recently_played

    from staged s
    left join games g on s.app_id = g.app_id
)

select * from metrics
order by playtime_hours desc