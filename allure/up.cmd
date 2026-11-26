@echo off
bash "%~dp0..\ci\publish-image.sh" allure || exit /b 1
