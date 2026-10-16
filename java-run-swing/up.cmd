set USER=stden
set IMAGE=java-run-swing
set TAG=latest
@echo ===== Build image =====
docker build -t %IMAGE% . || exit /b 1
@echo ===== Test image =====
bash "%~dp0..\test-images.sh" --no-build %IMAGE% || exit /b 1
@echo ===== Tag image =====
docker tag %IMAGE%:%TAG% %USER%/%IMAGE%:%TAG% || exit /b 1
@echo ===== Push to https://hub.docker.com/repository/docker/stden/java-run-swing =====
docker push %USER%/%IMAGE%:%TAG% || exit /b 1
