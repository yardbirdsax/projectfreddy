FROM arm64v8/telegraf:1.19.3


LABEL org.opencontainers.image.authors="Josh Feierman"
LABEL org.opencontainers.image.ref.name="Dockerized Telegraf for monitoring temperature sensors via lm_sensors"

RUN apt-get update && apt-get install lm-sensors
COPY telegraf.conf /etc/telegraf/telegraf.conf