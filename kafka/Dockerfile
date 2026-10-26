# Run a single-node Apache Kafka broker in KRaft mode for message testing.
FROM apache/kafka:latest

# Verify the client scripts are in place.
RUN test -f /opt/kafka/bin/kafka-broker-api-versions.sh \
 && test -f /opt/kafka/bin/kafka-topics.sh \
 && test -f /opt/kafka/bin/kafka-console-producer.sh \
 && test -f /opt/kafka/bin/kafka-console-consumer.sh

EXPOSE 9092
