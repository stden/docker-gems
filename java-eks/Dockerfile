# Build with the official Maven 3 image and Amazon Corretto 25 (LTS).
FROM maven:3-amazoncorretto-25 AS builder

WORKDIR /app
COPY . .

RUN mvn -B clean package -DskipTests

FROM amazoncorretto:25

WORKDIR /app

# Copy the JAR file from the build stage.
COPY --from=builder /app/target/*.jar app.jar

# Set Java options for the container.
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseG1GC -XX:+ExitOnOutOfMemoryError"

EXPOSE 8080

# The same user as runAsUser and runAsGroup in kubernetes/deployment.yaml, so that
# docker run also starts the API without root. The application writes only to /tmp.
USER 10001:10001

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
