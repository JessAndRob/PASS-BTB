$install = @{
    SqlInstance     = 'sql1','sql2'
    Version         = '2022'
    Feature         = 'Engine','Replication'
    Path            = '\\jumpy\installationmedia'
    Credential      = $cred
    AdminAccount    = 'sqlbits2024\sqladmin'
    Verbose         = $true
    Confirm         = $false
}
Install-DbaInstance @install

$install = @{
    SqlInstance     = 'sql2'
    Version         = '2022'
    Feature         = 'Engine','Replication'
    Path            = '\\jumpy\installationmedia'
    Credential      = $cred
    AdminAccount    = 'sqlbits2024\sqladmin'
    Verbose         = $true
    Confirm         = $false

}
Install-DbaInstance @install

## firewall 
New-NetFirewallRule -Name 'SQL Server In' -DisplayName 'SQL Server In ' -Direction Inbound -Protocol TCP -LocalPort 1433 -CimSession sql1,sql2

# Set the configurations to old defaults
Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true -PassThru | Register-DbatoolsConfig
Set-DbatoolsConfig -FullName sql.connection.encrypt -Value $false -PassThru | Register-DbatoolsConfig

## connect test
Connect-DbaInstance -SqlInstance sql1,sql2


# need to give full control for sqladmin@sqlbits2024.io to repldata folder here:
# gave to everyone because sql1\sql2 aren't running under a service account 
# \\sql1\c$\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL

$cred = get-credential password

Update-DbaServiceAccount -ComputerName sql1  -ServiceName MSSQLSERVER, SQLSERVERAGENT  -Username JessAndRob\sqladmin -SecurePassword $cred.Password
Update-DbaServiceAccount -ComputerName sql2  -ServiceName MSSQLSERVER, SQLSERVERAGENT  -Username JessAndRob\sqladmin -SecurePassword $cred.Password

# also need a database
Invoke-WebRequest -Uri https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksLT2022.bak -OutFile \\sql1\c$\temp\AdventureWorks2022LT.bak
Restore-DbaDatabase -SqlInstance sql1 -Path C:\temp\AdventureWorks2022LT.bak -UseDestinationDefaultDirectories