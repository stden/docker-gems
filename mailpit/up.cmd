@echo off
bash "%~dp0..\ci\publish-image.sh" mailpit || exit /b 1
