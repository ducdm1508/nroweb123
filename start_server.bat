@echo off
title NRO Web Server - Port 8080
powershell -ExecutionPolicy Bypass -File "%~dp0web_server.ps1"
pause