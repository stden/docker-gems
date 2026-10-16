@echo off
bash "%~dp0..\ci\publish-image.sh" postgres-vector-graph || exit /b 1
