# summit_2026_hands_on_lab_casino

dbt project for the Summit 2026 hands-on lab, themed as **Level Up Labs**, a
fictional video game studio, modeled on
[dbt-labs/Jaffle-Games](https://github.com/dbt-labs/Jaffle-Games). Source
data comes from the
[summit_2026_connector_sdk](https://github.com/fivetran/summit_2026_connector_sdk)
Fivetran connector -- 11 tables covering the studio's title/platform/SKU
catalog and player activity (sessions, transactions, leaderboard scores,
reviews, marketing spend).

## Architecture

```
models/
  staging/            stg_levelup__ views, 1:1 with source tables
  intermediate/        int_ ephemeral business logic (revenue signing, session
                        enrichment, player/title rollups)
  marts/
    core/               dim_ and fct_ conformed dimensions and facts
    leadership/         mart_studio_kpis, mart_title_performance
    finance/            mart_monetization
    live_ops/           mart_live_ops_health
    player_experience/  mart_player_retention, mart_player_leaderboard
  semantic/             MetricFlow metrics + saved queries
  exposures.yml         downstream dashboards per stakeholder group
macros/                 clean_country_code, to_utc, signed_net_amount
tests/                  singular business-rule tests
snapshots/              player account-status and title price/sunset history
```

Source declarations live in [models/sources.yml](models/sources.yml).

## Running

```
dbt deps
dbt run
dbt test
```
