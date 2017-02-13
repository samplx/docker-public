FROM debian:8.7
MAINTAINER samplx <jb@samplx.org>

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Timezone parameters
ENV TIMEZONE America/Chicago

# Setup the timezone
RUN echo "${TIMEZONE}" > /etc/timezone \
    && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime

# Get dependencies
RUN apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends \
      apt-utils \
      locales \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# locale
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" \
      > /etc/apt/sources.list.d/webupd8team-java.list \
      && echo debconf shared/accepted-oracle-license-v1-1 select true | \
        debconf-set-selections \
      && echo debconf shared/accepted-oracle-license-v1-1 seen true | \
        debconf-set-selections

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 \
      && apt-get update -yqq \
      && apt-get install -yqq \
        oracle-java8-installer \
        oracle-java8-set-default \
        wget \
      && apt-get clean all \
      && rm -rf /var/cache/oracle-jdk8-installer
