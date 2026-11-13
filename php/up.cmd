@echo off
bash "%~dp0..\ci\publish-image.sh" php || exit /b 1
