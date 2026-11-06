@echo off
bash "%~dp0..\ci\publish-image.sh" rust-node || exit /b 1
