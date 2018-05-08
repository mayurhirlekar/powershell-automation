@echo off
title Get Updated File List
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ". .\GetUpdatedFileList.ps1; Get-Updated-File-List;"
pause