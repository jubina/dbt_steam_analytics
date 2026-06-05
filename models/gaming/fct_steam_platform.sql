-- models/gaming/fct_steam_platform.sql
-- Fact model: Steam platform analytics across top 100 most-played games.
-- Source: Steam Spy API (top100in2weeks + appdetails enrichment)
-- Refreshed weekly via GitHub Actions.
--
-- Key questions answered:
--   "Which genres dominate the top 100 by ownership?"
--   "Do higher-priced games get better reviews?"
--   "What's the free-to-play vs paid split?"
--   "Which games have the best review sentiment?"

with staged as (
    select * from {{ ref('stg_steam_platform') }}
),

enriched as (
    select
        appid,
        game_title,
        primary_genre,
        secondary_genre,
        pulled_at,

        -- pricing
        price_usd,
        is_free,
        case
            when is_free                then 'Free to Play'
            when price_usd < 10         then 'Budget (under $10)'
            when price_usd < 30         then 'Mid-Range ($10-$29)'
            when price_usd < 60         then 'Premium ($30-$59)'
            else                             'AAA ($60+)'
        end as price_tier,

        -- ownership & reach
        owners_estimate,
        case
            when owners_estimate >= 100000000   then 'Mega (100M+)'
            when owners_estimate >= 35000000    then 'Huge (35M+)'
            when owners_estimate >= 15000000    then 'Large (15M+)'
            when owners_estimate >= 5000000     then 'Mid (5M+)'
            else                                     'Niche (<5M)'
        end as reach_tier,

        -- reviews
        positive_reviews,
        negative_reviews,
        total_reviews,
        review_score,
        case
            when review_score >= 0.95   then 'Overwhelmingly Positive'
            when review_score >= 0.85   then 'Very Positive'
            when review_score >= 0.70   then 'Mostly Positive'
            when review_score >= 0.40   then 'Mixed'
            else                             'Mostly Negative'
        end as review_category,

        -- flags
        case
            when is_free = false
             and review_score >= 0.85
             and owners_estimate >= 15000000    then true
            else false
        end as is_must_buy,

        case
            when review_score < 0.60            then true
            else false
        end as is_controversial

    from staged
)

select * from enriched
order by owners_estimate desc
