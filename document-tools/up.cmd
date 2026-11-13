@echo off
bash "%~dp0..\ci\publish-image.sh" document-tools || exit /b 1
