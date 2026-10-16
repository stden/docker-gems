# Build and test Java projects with JDK 25 (LTS) and Maven.
FROM maven:3-amazoncorretto-25

# Clear the default entry point to allow both java and mvn commands.
ENTRYPOINT []
WORKDIR /workspace

RUN java -version && mvn -version

CMD ["bash"]
