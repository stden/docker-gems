@echo off
bash "%~dp0..\ci\publish-image.sh" cpp || exit /b 1
