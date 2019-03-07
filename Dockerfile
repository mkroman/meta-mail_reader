FROM ruby:2.6
MAINTAINER Mikkel Kroman <mk@maero.dk>

# Install dependencies.
RUN apt-get update && \
  apt-get install -y exiv2 exiftran ffmpeg file

# Set the timezone.
RUN ln -sf /usr/share/zoneinfo/Europe/Copenhagen /etc/localtime && \
  dpkg-reconfigure --frontend noninteractive tzdata

RUN gem install bundler

# Throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY . .

RUN bundle install

ENTRYPOINT ruby /usr/src/app/bin/meta-mail-reader
