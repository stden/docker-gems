@echo off
bash "%~dp0..\ci\publish-image.sh" web-qa || exit /b 1
