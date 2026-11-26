set IMAGE=my-python-app
@echo ===== Build image =====
docker build -t %IMAGE% .
@echo ===== Run container =====
docker run %IMAGE%
