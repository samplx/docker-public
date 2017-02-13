FROM debian:8.7
MAINTAINER samplx <jb@samplx.org>

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# MySQL Parameters
ENV MYSQL_PORT 3306

# Timezone parameters
ENV TIMEZONE America/Chicago

# Setup the timezone
RUN echo "${TIMEZONE}" > /etc/timezone \
    && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime

# Get dependencies
RUN apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends locales \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# locale
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN apt-get install -yqq --no-install-recommends \
        apt-utils \
        cracklib-runtime \
        libpwquality-tools \
        mysql-server \
        wget \
    && apt-get clean

COPY entrypoint.sh /entrypoint.sh
COPY my.cnf /etc/mysql/conf.d/my.cnf

RUN chmod +x /entrypoint.sh \
    && chown mysql:mysql /etc/mysql/conf.d/my.cnf \
    && echo "port = ${MYSQL_PORT}" >> /etc/mysql/conf.d/my.cnf \
    && sed -i -e 's/^key_buffer/key_buffer_size/' \
       -e 's/^myiasm-recover/myiasm-recover-options/' /etc/mysql/my.cnf

# clean-up
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/man /usr/share/doc /usr/share/doc-base

EXPOSE ${MYSQL_PORT}

VOLUME ["/var/lib/mysql"]

ENTRYPOINT ["/entrypoint.sh"]
