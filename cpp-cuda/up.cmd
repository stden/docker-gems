@echo off
bash "%~dp0..\ci\publish-image.sh" cpp-cuda || exit /b 1
