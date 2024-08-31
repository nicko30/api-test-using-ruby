# Use a base image with a minimal Linux distribution
FROM debian:bullseye-slim

# Set working directory
WORKDIR /app

RUN apt-get update && \
    apt-get install -y curl \
    wget \
    tar \
    unzip \
    zip \
    gnupg \
    build-essential \
    grep \
    bzip2 \
    patch \
    gcc \
    bison \
    zlib1g-dev \
    libyaml-dev \
    libssl-dev \
    jq \
    libgdbm-dev \
    libreadline-dev \
    libncurses5-dev \
    libffi-dev \
    python3 \
    python3-pip \
    postgresql-client \
    libpq-dev \
    freetds-dev \
    ruby-dev \
    tzdata && \
    rm -rf /var/lib/apt/lists/*

# Optionally, set an environment variable for Python 3
ENV PYTHON3_HOME=/usr/bin/python3

RUN wget https://github.com/postmodern/ruby-install/releases/download/v0.9.3/ruby-install-0.9.3.tar.gz && \
    tar -xzvf ruby-install-0.9.3.tar.gz && \
    cd ruby-install-0.9.3/ && \
    make install

# install ruby 3.0.0
RUN ruby-install --system ruby 3.0.0

# Install bundler with version 2.5.14
RUN gem install bundler:2.5.14

# Copy Gemfile and Gemfile.lock separately to avoid cache invalidation
COPY Gemfile ./

# Install all ruby gems
RUN bundle install

COPY . .
