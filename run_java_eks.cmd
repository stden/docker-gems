@echo ===== Run Java EKS =====
set PORT=82
docker run -d -p %PORT%:8080 --name java_eks stden/java-eks
@echo ===== Open http://localhost:82 =====
start chrome "http://localhost:%PORT%/swagger-ui/index.html"


