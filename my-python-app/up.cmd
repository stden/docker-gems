@echo off
bash "%~dp0..\ci\publish-image.sh" my-python-app || exit /b 1
