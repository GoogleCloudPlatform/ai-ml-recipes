"""Auto-loads `dbt_wrapper` when `PYTHONPATH=.` is set so `dbt build` connects via Dataproc Spark Connect."""

import dbt_wrapper  # noqa: F401

