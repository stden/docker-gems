@echo off
bash "%~dp0..\ci\publish-image.sh" crossplane || exit /b 1
