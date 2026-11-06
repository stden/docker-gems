# Mock HTTP services for integration tests with WireMock.
FROM wiremock/wiremock:latest

# Add a /demo stub that the smoke test uses to verify the admin API.
COPY mappings/demo.json /home/wiremock/mappings/demo.json

RUN java -version && test -f /home/wiremock/mappings/demo.json

EXPOSE 8080
