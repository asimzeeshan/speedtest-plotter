# Copyright (c) 2019 Anton Semjonov
# Licensed under the MIT License

# ---------- build taganaka/SpeedTest binary ----------
FROM alpine:latest as compiler

# install build framework and libraries
RUN apk add --no-cache alpine-sdk cmake curl-dev libxml2-dev

# configure and build binary
WORKDIR /build
RUN git clone https://github.com/taganaka/SpeedTest.git . \
  && cmake -DCMAKE_BUILD_TYPE=Release . \
  && make

# --------- build application container ----------
FROM python:3-alpine

# install necessary packages and fonts
RUN apk add --no-cache gnuplot ttf-droid libcurl libxml2 libstdc++ libgcc

# copy build binary from first stage
COPY --from=compiler /build/SpeedTest /usr/local/bin/SpeedTest

# copy requirements file and install with pip
COPY requirements.txt /requirements.txt
RUN apk add --no-cache --virtual build-deps musl-dev gcc postgresql-dev \
  && apk add --no-cache postgresql-libs \
  && pip install --no-cache-dir -r /requirements.txt \
  && apk del --purge build-deps

# default cron interval
ENV MINUTES="15"

# listening port, set to empty string for no webserver
ENV PORT="8000"

# database uri (sqlalchemy uri)
ENV DATABASE="sqlite:////data/speedtests.db"

# copy entrypoint and scripts
WORKDIR /opt/speedtest-plotter
ENV PATH="/opt/speedtest-plotter:${PATH}"
COPY entrypoint.sh /entrypoint.sh
COPY plotscript speedtest-plotter ./

# start with entrypoint which exec's crond
CMD ["/bin/ash", "/entrypoint.sh"]
