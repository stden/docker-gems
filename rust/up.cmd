@echo off
bash "%~dp0..\ci\publish-image.sh" rust || exit /b 1
