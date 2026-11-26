@echo off
bash "%~dp0..\ci\publish-image.sh" rust-desktop || exit /b 1
