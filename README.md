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

## Running the program

### Search-And-Launch

```
. .\SearchAndLaunch.ps1
```

```
Search-And-Launch -SiteToSearch SITENAME
```

## Coding style

I am still learning powershell any advice?




