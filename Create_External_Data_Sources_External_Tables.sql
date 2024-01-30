-- SELECT t.name
-- FROM [B2B].sys.tables AS t
-- WHERE t.type_desc = 'USER_TABLE' and t.name not like '%_raw%'

-- References:
-- https://learn.microsoft.com/en-us/azure/azure-sql/database/elastic-query-getting-started-vertical?view=azuresql
-- https://www.youtube.com/watch?v=C73iDjnDn0o


--Step 0

-- Connect to target database B2BDW

--Step 1

-- Create a database master key if one does not already exist.  
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Check it in 1Password';

-- Create a database scoped credential if one does not already exist.
-- The credential to connect to the source Azure SQL logical server, to execute query
CREATE DATABASE SCOPED CREDENTIAL ElasticDBQueryCred
WITH IDENTITY = 'admin',
    SECRET = 'Check it in 1Password';  

--Step 2

--Create a external data source to connect the source database.
CREATE EXTERNAL DATA SOURCE B2B
    WITH (
            TYPE = RDBMS,
            LOCATION = 'company.database.windows.net',
            DATABASE_NAME = 'B2B',
            CREDENTIAL = ElasticDBQueryCred,
            );

--Step 3

-- Connect to source database B2B

--Step 4

--Run this query to generate external tables DDL for the target database from the source database.
IF OBJECT_ID('tempDB..#external_tables', 'U') IS NOT NULL
    DROP TABLE #external_tables
GO
CREATE TABLE #external_tables ([external_table] NVARCHAR(MAX))

DECLARE @sql NVARCHAR(MAX);
DECLARE @schema_name NVARCHAR(MAX);
DECLARE @table_name NVARCHAR(MAX);
DECLARE @column_name NVARCHAR(MAX);
DECLARE @data_type NVARCHAR(MAX);
DECLARE @data_type_length INT;
DECLARE @is_nullable NVARCHAR(MAX);

DECLARE table_cursor CURSOR FOR
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.is_external = 0 -- exclude existing external tables
    AND (t.name NOT LIKE '%_raw%');

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @schema_name, @table_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = 'CREATE EXTERNAL TABLE ' + QUOTENAME(@schema_name) + '.' + QUOTENAME(@table_name) + ' (' ;

    DECLARE column_cursor CURSOR FOR
    SELECT c.name AS column_name, 
           TYPE_NAME(c.system_type_id) AS data_type,
           CASE
               WHEN c.system_type_id IN (165, 167) THEN c.max_length / 2 -- Handle nvarchar, nchar
               WHEN c.system_type_id IN (231, 239) THEN c.max_length / 2 -- Handle varchar, char
               ELSE NULL
           END AS data_type_length,
           CASE WHEN c.is_nullable = 1 THEN 'NULL' ELSE 'NOT NULL' END AS is_nullable
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    JOIN sys.columns c ON t.object_id = c.object_id
    WHERE t.is_external = 0 -- exclude existing external tables
    AND t.name = @table_name;

    OPEN column_cursor;
    FETCH NEXT FROM column_cursor INTO @column_name, @data_type, @data_type_length, @is_nullable;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Append data type with length, if applicable
        IF @data_type_length = 0
        BEGIN
            SET @data_type = @data_type + '(max)';
        END
        
        ELSE IF @data_type_length IS NOT NULL AND @data_type_length <> 0
        BEGIN
            SET @data_type = @data_type + '(' + CAST(@data_type_length AS NVARCHAR(10)) + ')';
        END
        
        SET @sql += QUOTENAME(@column_name) + ' ' + @data_type + ' ' + @is_nullable + ', ';
        FETCH NEXT FROM column_cursor INTO @column_name, @data_type, @data_type_length, @is_nullable;
    END;

    CLOSE column_cursor;
    DEALLOCATE column_cursor;

    -- Remove the trailing comma and add the WITH clause as needed
    SET @sql = LEFT(@sql, LEN(@sql) - 1) + ') WITH (DATA_SOURCE = B2B);';
    
    INSERT INTO #external_tables VALUES(@sql)

    PRINT @sql; -- print the generated SQL statement

    FETCH NEXT FROM table_cursor INTO @schema_name, @table_name;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

SELECT *
FROM #external_tables

--Step 5

--Copy the result.
--Open a new script.
--Connect the new script to target database B2BDW.
--Paste the result to the new script.
--Execute the new script under target database B2BDW.
--External tables creation is done.



--Step 6 (Optional)

--If you modify the table schema in the source database, you have to drop the external table from the target database and then re-create it.
--Run this query to generate the drop script to drop all the external tables on the target database.
DECLARE @sql NVARCHAR(MAX) = '';

SELECT @sql += 'DROP EXTERNAL TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + '; '
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.is_external = 0 -- exclude existing external tables
AND (t.name NOT LIKE '%_raw%')
GROUP BY s.name, t.name;

PRINT @sql; -- print the generated SQL statements

--Step 7 (Optional)

--Copy the messages.
--Open a new script.
--Connect the new script to target database B2BDW.
--Paste the messages to the new script.
--Execute the new script under target database B2BDW.
--External tables drop is done.
