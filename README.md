# Automation

Powershell scripts to help automate day to day task.

## Getting Started

You can grab any script file and run it in powershell. 

### Prerequisites

You might need to set execution policy

[How to set execution policy](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-6)

```
Set-ExecutionPolicy -ExecutionPolicy
```

### Installing

Just to make sure script doesn't get blocked and execution policy is properly set

```
Unblock-File -Path "SearchAndLaunch.ps1"
```

```
Unblock-File -Path "GetUpdatedFileList.ps1"
```

## Running the program

### Search-And-Launch

```
Import-Module .\SearchAndLaunch.ps1
```

```
Search-And-Launch -SiteToSearch SITENAME
```

##### OR

```
Click on SearchAndLaunch.bat
```

### Get-Updated-File-List

```
Import-Module .\GetUpdatedFileList.ps1
```

```
Get-Updated-File-List -UpdatesPath PATH -NumberOfDays 1
```

#### OR

```
Click on GetUpdatedFileList.bat
```

## Coding style

I am still learning powershell any advice?




