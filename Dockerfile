FROM ubuntu:latest

RUN apt-get update

RUN apt-get install ipmitool -y

ADD healthcheck.sh /app/healthcheck.sh
ADD fancontrol.sh /app/fancontrol.sh

RUN chmod 0777 /app/healthcheck.sh /app/fancontrol.sh

WORKDIR /app

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD [ "/app/healthcheck.sh" ]

CMD ["./fancontrol.sh"]