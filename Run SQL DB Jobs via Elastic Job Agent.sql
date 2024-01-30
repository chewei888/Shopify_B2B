-- Step 0: Connect to jobs.database.windows.net.

-- Step 1: Select the database in the drop-down list.

-- Step 2: Highlight one of the queries below, and click "Execute".

-- Execute the latest version of a job "ShopifyEntityLog"
EXEC jobs.sp_start_job 'ShopifyEntityLog';

-- Execute the latest version of a job "LoadFact"
EXEC jobs.sp_start_job 'LoadFact';

-- Step 3: Go to Azure Elastic Job agent > jobagent > Job definitions
-- You should see the last job execution timestamp has been updated by the time you execute the query.