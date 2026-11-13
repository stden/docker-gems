@echo off
bash "%~dp0..\ci\publish-image.sh" rust-ci || exit /b 1
