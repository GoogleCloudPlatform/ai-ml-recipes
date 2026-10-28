/* @datacloud.settings
{
  "version": 1,
  "service": "SPARK",
  "connectionInfo": {
    "sessionTemplate": "interactive-analysis"
  },
  "dialect": "ANSI_SQL"
}
*/

/*----------------------------------------------------------------------------------------
  GETTING STARTED: INTERACTIVE SPARK SQL ON SERVERLESS SPARK

  1. Create a Runtime Profile (first-time setup):
     In the Activity Bar, open Data Agent Kit > Apache Spark > Serverless >
     New Runtime Profile.
  2. Connect this Editor:
     Click the connection selector at the top of this editor (displaying
     "Querying Managed Apache Spark") and choose your Runtime Profile.
  3. Run Queries:
     Click the "Run" button in the top-right corner (or highlight a single statement
     to run only the selection).
  Tip: Your first query starts a new Serverless Spark session and may take ~30-60s.
       Subsequent queries reuse the active session and run in seconds.
----------------------------------------------------------------------------------------*/

SELECT * FROM `lakehouse-public-data`.chicago_taxi_trips.taxi_trips LIMIT 100;
