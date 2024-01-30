-- https://www.mssqltips.com/sqlservertip/5242/adding-users-to-azure-sql-databases/

-- Execute this query in master db first.
-- create SQL auth login from master 
create LOGIN developer
with PASSWORD = 'PASSWORD'

-- select your db in the dropdown and create a user mapped to a login 
CREATE USER [developer] 
FOR LOGIN [developer] 
WITH DEFAULT_SCHEMA = dbo; 

-- Execute the following queries in the new db you just created.  
-- add user to role(s) in db 
ALTER ROLE db_datareader ADD MEMBER [developer]; 
ALTER ROLE db_datawriter ADD MEMBER [developer];

-- create a custom role
CREATE ROLE [db_executor] AUTHORIZATION [dbo]
GO

-- give the custom role to execute.
GRANT EXECUTE TO [db_executor]
GO

-- give the user execution permission.
ALTER ROLE db_executor ADD MEMBER [developer]; 