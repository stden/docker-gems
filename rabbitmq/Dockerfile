# Run a RabbitMQ broker with the management UI and a demo exchange and queue.
FROM rabbitmq:management-alpine

COPY rabbitmq.conf /etc/rabbitmq/rabbitmq.conf
COPY definitions.json /etc/rabbitmq/definitions.json

RUN test -f /etc/rabbitmq/rabbitmq.conf && test -f /etc/rabbitmq/definitions.json

EXPOSE 5672 15672
