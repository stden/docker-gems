@echo off
bash "%~dp0..\ci\publish-image.sh" java-ui-browser || exit /b 1
