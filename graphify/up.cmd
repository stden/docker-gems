@echo off
bash "%~dp0..\ci\publish-image.sh" graphify || exit /b 1
