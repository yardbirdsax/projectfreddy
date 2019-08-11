FROM resin/raspberrypi3-debian:stretch

RUN apt-get update && apt-get upgrade -y && apt-get install -y cmake build-essential curl libcurl4-openssl-dev \
    libssl1.0-dev uuid-dev apt-utils python python-pip python-virtualenv python3 python3-pip python3-virtualenv \
    libboost-python-dev pkg-config valgrind

COPY app/ /bin/temp2aziot/

RUN pip3 install -r /bin/temp2aziot/requirements.txt

RUN echo "dtoverlay=w1-gpio" >> /boot/config.txt

ENTRYPOINT [ "python3","-u","/bin/temp2aziot/temp2aziot.py" ]