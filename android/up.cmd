@echo off
bash "%~dp0..\ci\publish-image.sh" android || exit /b 1
