@echo off
bash "%~dp0..\ci\publish-image.sh" java || exit /b 1
