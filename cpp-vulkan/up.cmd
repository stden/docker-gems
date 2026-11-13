@echo off
bash "%~dp0..\ci\publish-image.sh" cpp-vulkan || exit /b 1
