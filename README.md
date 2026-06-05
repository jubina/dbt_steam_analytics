# dbt-steam-analytics

A gaming analytics pipeline built with dbt and BigQuery. Models a Steam game library from raw data through staging, dimension, and fact layers — answering questions like "which games gave the best value per dollar?" and "what's my completion rate by genre?"

Part of the [DunnHub](https://github.com/jubina/DunnHub) personal data infrastructure ecosystem.

---

## Why This Exists

Every gamer has intuitions about their library — "I play too many roguelikes", "that AAA game was a ripoff", "I never finish anything". This pipeline turns those intuitions into answerable questions with a proper dimensional model and documented, tested SQL.

It's also a demonstration of the modern data stack: seed data → dbt staging → dimension + fact models → BigQuery, with schema tests and documentation throughout.

---

## Pipeline Architecture

```
seeds/
  raw_steam_library.csv       ← Raw game library (25 games, real titles)
        │
        ▼
models/gaming/
  stg_steam_games.sql         ← Staging: cast types, standardize strings,
        │                        derive achievement_completion_pct
        │
        ├──► dim_games.sql    ← Dimension: genre taxonomy, era bucketing,
        │                        price tier, roguelike flag
        │
        └──► fct_playtime.sql ← Fact: playtime + value metrics per game
                                 engagement tier, cost_per_hour, value tier,
                                 days_since_played, is_recently_played
```

**Lineage:** `raw_steam_library` → `stg_steam_games` → `dim_games` + `fct_playtime`

---

## Models

### `stg_steam_games`
Staging layer. Casts all types, lowercases/trims strings, derives `achievement_completion_pct`. Filters out null titles and negative playtime.

### `dim_games`
Game dimension table. Adds:
- `release_era` — Classic / Mid Era / Modern / Current
- `price_tier` — Free to Play / Budget / Mid-Range / Premium
- `is_roguelike` — boolean flag (genre or subgenre matches)
- `is_achievement_heavy` — boolean flag (>100 total achievements)

### `fct_playtime`
Core analytical model. One row per game with:

| Metric | Description |
|--------|-------------|
| `cost_per_hour` | Purchase price ÷ hours played |
| `engagement_tier` | Unplayed / Sampled / Played / Invested / Obsessed |
| `value_tier` | Free / Excellent / Good / Fair / Poor Value |
| `days_since_played` | Staleness metric |
| `is_recently_played` | Played in last 90 days |
| `achievement_completion_pct` | Achievements earned ÷ total available |

---

## Tests

15 data tests across all models:

| Test | Models |
|------|--------|
| `unique` | app_id on all three models |
| `not_null` | app_id, game_title, playtime_hours, engagement_tier, value_tier |
| `accepted_values` | release_era, price_tier, engagement_tier |

All 15 passing.

---

## Sample Questions This Pipeline Answers

```sql
-- Best value games (lowest cost per hour, minimum 10hrs played)
select game_title, genre, cost_per_hour, playtime_hours
from dbt_jdunn.fct_playtime
where cost_per_hour is not null and playtime_hours >= 10
order by cost_per_hour asc
limit 10;

-- Playtime by genre
select genre, sum(playtime_hours) as total_hours, count(*) as game_count
from dbt_jdunn.fct_playtime
group by genre
order by total_hours desc;

-- Completion rate by engagement tier
select engagement_tier,
       avg(achievement_completion_pct) as avg_completion,
       count(*) as games
from dbt_jdunn.fct_playtime
group by engagement_tier
order by avg_completion desc;

-- Roguelike addiction check
select game_title, playtime_hours, engagement_tier
from dbt_jdunn.fct_playtime
where is_roguelike = true
order by playtime_hours desc;
```

---

## Stack

- **dbt Cloud** — transformation layer, testing, documentation
- **BigQuery** — data warehouse
- **Seed data** — 25 games from a real Steam library

---

## Setup

1. Clone this repo and connect to dbt Cloud
2. Configure a BigQuery connection in your dbt Cloud project
3. Run `dbt seed` to load the game library
4. Run `dbt run` to build all models
5. Run `dbt test` to validate (15/15 should pass)

---

## Roadmap

- [ ] Connect to live Steam API (replace seed with real library data)
- [ ] Add `fct_sessions` model for session-level playtime analysis
- [ ] Power BI dashboard on top of `fct_playtime`
- [ ] Expand to multi-user comparison (friend group library overlap)

---

## Related Projects

- [DunnHub](https://github.com/jubina/DunnHub) — Personal AI agent infrastructure (MCP server, SQLite, local LLM)
- [Algo-Trading](https://github.com/jubina/Algo-Trading) — BTC/ETH pairs trading bot
