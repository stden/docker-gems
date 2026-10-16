@echo off
bash "%~dp0..\ci\publish-image.sh" wiremock || exit /b 1
