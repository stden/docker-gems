@echo off
bash "%~dp0..\ci\publish-image.sh" python-media || exit /b 1
