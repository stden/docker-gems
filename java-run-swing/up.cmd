@echo off
bash "%~dp0..\ci\publish-image.sh" java-run-swing || exit /b 1
