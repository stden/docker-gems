@echo off
bash "%~dp0..\ci\publish-image.sh" cpp-ci || exit /b 1
