Import-Module sqlps -WarningAction Ignore
$currentPath = $pwd.Path

Function SQL-To-CSV(){
param(
 [Parameter(Mandatory=$true)][string]$ServerName,
 [Parameter(Mandatory=$true)][string]$Database,
 [Parameter(Mandatory=$true)][string]$ExportFilePath,
 [Parameter(Mandatory=$true)][string]$SqlQuery
)


$result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $Database -Query $SqlQuery
$result| Export-Csv $ExportFilePath -NoTypeInformation
}

cd $currentPath