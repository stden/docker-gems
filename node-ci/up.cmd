@echo off
bash "%~dp0..\ci\publish-image.sh" node-ci || exit /b 1
