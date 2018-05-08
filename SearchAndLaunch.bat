@echo off
title Search And Launch Site
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ". .\SearchAndLaunch.ps1; Search-And-Launch;"
pause