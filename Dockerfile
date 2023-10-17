# 1st stage: build environment
FROM python:3.9-slim-buster AS builder

RUN apt-get update \
    && apt-get install -y build-essential libpq-dev \
    && apt-get clean

WORKDIR /app

COPY requirements.txt .
RUN python -m venv /opt/venv
RUN /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# 2nd stage: final environment
FROM python:3.9-slim-buster

RUN apt-get update \
    && apt-get install -y curl git gnupg2 unzip wget ffmpeg neofetch \
    && apt-get clean

# copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

# install chrome
RUN mkdir -p /tmp/ && \
    cd /tmp/ && \
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    # -f ==> is required to --fix-missing-dependancies
    dpkg -i ./google-chrome-stable_current_amd64.deb; apt -fqqy install && \
    # clean up the container "layer", after we are done
    rm ./google-chrome-stable_current_amd64.deb

# install chromedriver
RUN mkdir -p /tmp/ && \
    cd /tmp/ && \
    wget -O /tmp/chromedriver.zip http://chromedriver.storage.googleapis.com/$(curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE)/chromedriver_linux64.zip  && \
    unzip /tmp/chromedriver.zip chromedriver -d /usr/bin/ && \
    # clean up the container "layer", after we are done
    rm /tmp/chromedriver.zip

ENV GOOGLE_CHROME_DRIVER /usr/bin/chromedriver
ENV GOOGLE_CHROME_BIN /usr/bin/google-chrome-stable

# install node-js
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs && \
    npm i -g npm

# install rar
RUN mkdir -p /tmp/ && \
    cd /tmp/ && \
    wget -O /tmp/rarlinux.tar.gz http://www.rarlab.com/rar/rarlinux-x64-6.0.0.tar.gz && \
    tar -xzvf rarlinux.tar.gz && \
    cd rar && \
    cp -v rar unrar /usr/bin/ && \
    # clean up
    rm -rf /tmp/rar*

# copy the rest of the application files
COPY . .

# command to run on container start
CMD [ "bash", "./run" ]
