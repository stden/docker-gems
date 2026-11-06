@echo off
bash "%~dp0..\ci\publish-image.sh" toolchains || exit /b 1
