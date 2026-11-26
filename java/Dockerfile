# Base image: maven:3-amazoncorretto-25 ships JDK 25 LTS and Maven 3 together.
# Corretto is the AWS-managed OpenJDK distribution.
FROM maven:3-amazoncorretto-25

# The maven base image sets ENTRYPOINT to its init script.
# Clear ENTRYPOINT so that 'java', 'mvn', and 'bash' all work as direct commands.
ENTRYPOINT []
WORKDIR /workspace

# Verify the tools at build time. A missing tool stops the build before publication.
RUN java -version && mvn -version

CMD ["bash"]
