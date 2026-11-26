set IMAGE=java-run-swing
@echo ===== Build image =====
docker build -t %IMAGE% .
@echo ===== Run container =====
docker run %IMAGE%
