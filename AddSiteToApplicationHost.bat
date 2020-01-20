@echo off
title Add site to IIS Express Configuration
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ". .\AddSiteToApplicationHostFile.ps1; Add-Site-to-IISExpress-Config;"
pause