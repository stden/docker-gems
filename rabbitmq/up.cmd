@echo off
bash "%~dp0..\ci\publish-image.sh" rabbitmq || exit /b 1
