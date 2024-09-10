FROM ubuntu:latest

RUN apt-get update

RUN apt-get install ipmitool -y

ADD fancontrol.sh /app/fancontrol.sh

RUN chmod 0777 /app/fancontrol.sh

WORKDIR /app

CMD ["./fancontrol.sh"]