@echo off
bash "%~dp0..\ci\publish-image.sh" ocr || exit /b 1
