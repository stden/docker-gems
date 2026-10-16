@echo off
bash "%~dp0..\ci\publish-image.sh" codegraph || exit /b 1
