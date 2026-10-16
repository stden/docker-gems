@echo off
bash "%~dp0..\ci\publish-image.sh" open-webui || exit /b 1
