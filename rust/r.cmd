set IMAGE=rust
@echo ===== Build image =====
docker build -t %IMAGE% .
@echo ===== Run container =====
docker run --rm %IMAGE%
