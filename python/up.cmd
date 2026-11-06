@echo off
bash "%~dp0..\ci\publish-image.sh" python || exit /b 1
