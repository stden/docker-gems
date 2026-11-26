@echo off
bash "%~dp0..\ci\publish-image.sh" minio || exit /b 1
