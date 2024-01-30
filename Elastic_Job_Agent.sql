-- References:
-- https://learn.microsoft.com/en-us/azure/azure-sql/database/elastic-jobs-tsql-create-manage?view=azuresql#sp_add_jobstep
-- https://www.sqlshack.com/azure-sql-elastic-job-agent/#:~:text=SQL%20Server%20Agent%20is%20a,feature%20called%20elastic%20job%20agent.
-- https://youtu.be/lNjT12P6VBs?si=nyG74fx2EbjyzqVt

-- Step 0

-- Connect to Jobs database

--Step 1

-- Create a database master key if one does not already exist.  
CREATE MASTER KEY ENCRYPTION BY PASSWORD='Check it in 1Password';  
  
-- Create a database scoped credential if one does not already exist.
-- The credential to connect to the Azure SQL logical server, to execute jobs
CREATE DATABASE SCOPED CREDENTIAL JobRun WITH IDENTITY = 'admin',
    SECRET = 'Check it in 1Password';  
GO

--Step 2

-- -- Add a target group containing server(s)
-- EXEC jobs.sp_add_target_group 'ServerGroup1';

-- -- Add a server target member
-- EXEC jobs.sp_add_target_group_member
-- @target_group_name = 'ServerGroup1',
-- @target_type = 'SqlServer',
-- @refresh_credential_name = 'refresh_credential', --credential required to refresh the databases in a server
-- @server_name = 'server1.database.windows.net';

-- Add a target group containing database(s)
EXEC jobs.sp_add_target_group 'DatabaseGroup_B2B'
GO

-- Add a server target member
EXEC jobs.sp_add_target_group_member
@target_group_name = 'DatabaseGroup_B2B',
@target_type =  N'SqlDatabase',
@server_name='company.database.windows.net',
@database_name =N'B2B'
GO

--View the recently created target group and target group members
SELECT * FROM jobs.target_groups WHERE target_group_name='DatabaseGroup_B2B';
SELECT * FROM jobs.target_group_members WHERE target_group_name='DatabaseGroup_B2B';

--Step 3

--Add a unplanned job
EXEC jobs.sp_add_job @job_name = 'CreateTableTest', @description = 'Create Table Test';

-- Add job step for the unplanned job
EXEC jobs.sp_add_jobstep @job_name = 'CreateTableTest',
@command = N'IF NOT EXISTS (SELECT * FROM sys.tables WHERE object_id = object_id(''Test''))
CREATE TABLE [dbo].[Test]([TestId] [int] NOT NULL);',
@credential_name = 'JobRun',
@target_group_name = 'DatabaseGroup_B2B';

-- Execute a unplanned job
EXEC jobs.sp_start_job 'CreateTableTest';

-- View the jobs, job steps, job executions
SELECT * FROM jobs.[jobs]
SELECT * FROM jobs.[jobsteps]
SELECT * FROM jobs.job_executions ORDER BY start_time DESC;


--Add a scheduled job

EXEC jobs.sp_add_job @job_name='TestScheduledJob', @description='Print hi for testing'

-- Add job step for the scheduled job
EXEC jobs.sp_add_jobstep @job_name='TestScheduledJob',
@step_name ='Print hi',
@command=N' print ''hi''',
@credential_name='JobRun',
@target_group_name='DatabaseGroup_B2B'

-- Add a new step to the existing job
EXEC jobs.sp_add_jobstep @job_name='TestScheduledJob',
@step_name ='Print hello',
@command=N' print ''hello''',
@credential_name='JobRun',
@target_group_name='DatabaseGroup_B2B'

-- Update the job with schedule
EXEC jobs.sp_update_job
@job_name = 'TestScheduledJob',
@enabled=1,
@schedule_interval_type = 'Minutes',
@schedule_interval_count = 1,
@schedule_start_time = '2023-10-23 20:52:00.0000000', -- in UTC
@schedule_end_time = '2023-10-23 20:55:00.0000000'; -- in UTC. The end time will not be included. For example, it won't execute at '2023-10-23 20:55:00'. After the end time, the job status maintains as enabled.

-- Update the job with schedule
EXEC jobs.sp_update_job
@job_name = 'TestScheduledJob',
@enabled=1,
@schedule_interval_type = 'Days',
@schedule_interval_count = 1,
@schedule_start_time = '2023-10-23 06:30:00.0000000'; -- in UTC


-- Update the job steps
EXEC jobs.sp_update_jobstep
@job_name = 'TestScheduledJob',
@step_id = 2,
@new_id = 1,
@new_name = 'Print Hello first';

-- Delete the job
EXEC jobs.sp_delete_job @job_name = 'CreateTableTest'

-- Delete the steps in the existing job
EXEC jobs.sp_delete_jobstep @job_name = 'TestScheduledJob',
-- @step_id = 2,
@step_name = 'Print hi'



/*From A - Z*/
-- Add a target group containing database(s)
EXEC jobs.sp_add_target_group 'DatabaseGroup_B2B'
GO

-- Add a server target member
EXEC jobs.sp_add_target_group_member
@target_group_name = 'DatabaseGroup_B2B',
@target_type =  N'SqlDatabase',
@server_name='compnay.database.windows.net',
@database_name =N'B2B'
GO

--Add a scheduled job
EXEC jobs.sp_add_job @job_name = 'ShopifyEntityLog',
    @description = 'Log all the Shopify entity data count for further validation.',
    @enabled = 1,
    @schedule_interval_type = 'Days',
    @schedule_interval_count = 1,
    @schedule_start_time = '2023-12-07 12:30:00.0000000' -- UTC

-- Add job step for the scheduled job
EXEC jobs.sp_add_jobstep @job_name = 'ShopifyEntityLog',
    @step_name = 'pop_daily_shopify_all_log',
    @command = 'EXEC pop_daily_shopify_all_log',
    @credential_name = 'JobRun',
    @target_group_name = 'DatabaseGroup_B2B'

-- Add a target group containing database(s)
EXEC jobs.sp_add_target_group 'DatabaseGroup_B2BDW'
GO

-- Add a server target member
EXEC jobs.sp_add_target_group_member
@target_group_name = 'DatabaseGroup_B2BDW',
@target_type =  N'SqlDatabase',
@server_name='company.database.windows.net',
@database_name =N'B2BDW'
GO

--Add a scheduled job
EXEC jobs.sp_add_job @job_name = 'LoadFact',
    @description = 'Load all the fact tables.',
    @enabled = 1,
    @schedule_interval_type = 'Days',
    @schedule_interval_count = 1,
    @schedule_start_time = '2023-12-07 12:35:00.0000000' -- UTC

-- Add job step for the scheduled job
EXEC jobs.sp_add_jobstep @job_name = 'LoadFact',
    @step_name = 'pop_fact_all',
    @command = 'EXEC pop_fact_all',
    @credential_name = 'JobRun',
    @target_group_name = 'DatabaseGroup_B2BDW'
