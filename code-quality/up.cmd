@echo off
bash "%~dp0..\ci\publish-image.sh" code-quality || exit /b 1
