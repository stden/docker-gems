@echo off
bash "%~dp0..\ci\publish-image.sh" java-17 || exit /b 1
