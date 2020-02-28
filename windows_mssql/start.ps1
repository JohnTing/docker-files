# The script sets the sa password and start the SQL Service 
# Also it attaches additional database from the disk
# The format for attach_dbs

param(
[Parameter(Mandatory=$false)]
[string]$sa_password,

[Parameter(Mandatory=$false)]
[string]$ACCEPT_EULA,

[Parameter(Mandatory=$false)]
[string]$attach_dbs
)


if($ACCEPT_EULA -ne "Y" -And $ACCEPT_EULA -ne "y")
{
	Write-Verbose "ERROR: You must accept the End User License Agreement before this container can start."
	Write-Verbose "Set the environment variable ACCEPT_EULA to 'Y' if you accept the agreement."

    exit 1 
}

# start the service
Write-Verbose "Starting SQL Server"
start-service MSSQL`$SQLEXPRESS

if($sa_password -eq "_") {
    $secretPath = $env:sa_password_path
    if (Test-Path $secretPath) {
        $sa_password = Get-Content -Raw $secretPath
    }
    else {
        Write-Verbose "WARN: Using default SA password, secret file not found at: $secretPath"
    }
}

if($sa_password -ne "_")
{
    Write-Verbose "Changing SA login credentials"
    $sqlcmd = "ALTER LOGIN sa with password=" +"'" + $sa_password + "'" + ";ALTER LOGIN sa ENABLE;"
    & sqlcmd -Q $sqlcmd
}

$attach_dbs_cleaned = $attach_dbs.TrimStart('\\').TrimEnd('\\')

$dbs = $attach_dbs_cleaned | ConvertFrom-Json

if ($null -ne $dbs -And $dbs.Length -gt 0)
{
    Write-Verbose "Attaching $($dbs.Length) database(s)"
	    
    Foreach($db in $dbs) 
    {            
        $files = @();
        Foreach($file in $db.dbFiles)
        {
            $files += "(FILENAME = N'$($file)')";           
        }

        $files = $files -join ","
        $sqlcmd = "IF EXISTS (SELECT 1 FROM SYS.DATABASES WHERE NAME = '" + $($db.dbName) + "') BEGIN EXEC sp_detach_db [$($db.dbName)] END;CREATE DATABASE [$($db.dbName)] ON $($files) FOR ATTACH;"

        Write-Verbose "Invoke-Sqlcmd -Query $($sqlcmd)"
        & sqlcmd -Q $sqlcmd
    }
}

Write-Verbose "Started SQL Server."
$lastCheck = (Get-Date).AddSeconds(-2) 


# 這裡負責stdb 和 cdb 資料庫的回復和建立使用者。
# RESTORE DATABASE
Write-Verbose "RESTORE DATABASE [FST_STDB]."
Invoke-Sqlcmd -Query "RESTORE DATABASE [FST_STDB] FROM  DISK = N'C:\temp\FST_STDB_2019-06-05.bak' WITH  FILE = 1,  MOVE N'FATEK_STDB' TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQL\DATA\FST_STDB.ndf',  MOVE N'FATEK_STDB_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQL\DATA\FST_STDB_log.ldf',  NOUNLOAD,  STATS = 5" -QueryTimeout 65534

Write-Verbose "RESTORE DATABASE [FST_CDB]."
Invoke-Sqlcmd -Query "RESTORE DATABASE [FST_CDB] FROM  DISK = N'C:\temp\FST_CDB_2019-06-05.bak' WITH  FILE = 1,  MOVE N'Fatek_Giant_CDB_test_0506' TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQL\DATA\FST_CDB.mdf',  MOVE N'Fatek_Giant_CDB_test_0506_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQL\DATA\FST_CDB_log.ldf',  NOUNLOAD,  STATS = 5" -QueryTimeout 65534

# CREATE LOGIN
Invoke-Sqlcmd -Query "USE [master];CREATE LOGIN [FST_STDB] WITH PASSWORD=N'FST_STDB', DEFAULT_DATABASE=[FST_STDB], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF"
Invoke-Sqlcmd -Query "USE [FST_STDB]; DROP USER FST_STDB"
Invoke-Sqlcmd -Query "USE [FST_STDB]; CREATE USER [FST_STDB] FOR LOGIN [FST_STDB]"
Invoke-Sqlcmd -Query "USE [FST_STDB]; ALTER ROLE [db_owner] ADD MEMBER [FST_STDB]"

Invoke-Sqlcmd -Query "USE [master];CREATE LOGIN [FST_CDB] WITH PASSWORD=N'FST_CDB', DEFAULT_DATABASE=[FST_CDB], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF"
Invoke-Sqlcmd -Query "USE [FST_CDB]; DROP USER FST_CDB"
Invoke-Sqlcmd -Query "USE [FST_CDB]; CREATE USER [FST_CDB] FOR LOGIN [FST_CDB]"
Invoke-Sqlcmd -Query "USE [FST_CDB]; ALTER ROLE [db_owner] ADD MEMBER [FST_CDB]"

while ($true) 
{ 
    Get-EventLog -LogName Application -Source "MSSQL*" -After $lastCheck | Select-Object TimeGenerated, EntryType, Message	 
    $lastCheck = Get-Date 
    Start-Sleep -Seconds 2 
}
