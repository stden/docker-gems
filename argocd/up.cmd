@echo off
bash "%~dp0..\ci\publish-image.sh" argocd || exit /b 1
