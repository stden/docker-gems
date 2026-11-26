@echo off
bash "%~dp0..\ci\publish-image.sh" kafka || exit /b 1
