FROM debian:8.7
MAINTAINER samplx <jb@samplx.org>

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow parameters
ARG AIRFLOW_VERSION=1.7.1.3
# Directories
ENV AIRFLOW_HOME /usr/local/airflow
ENV AIRFLOW_DAGS ${AIRFLOW_HOME}/dags
ENV AIRFLOW_LOGS ${AIRFLOW_HOME}/logs

ENV AIRFLOW_AUTHENTICATE False
ENV AIRFLOW_AUTH_BACKEND airflow.contrib.auth.backends.ldap_auth
ENV AIRFLOW_DAGS_REPO ""
ENV AIRFLOW_DAGS_BRANCH master
ENV AIRFLOW_EXECUTOR SequentialExecutor
ENV AIRFLOW_HOST localhost
ENV AIRFLOW_LOAD_EXAMPLES True
ENV AIRFLOW_PASSWORD ""
ENV AIRFLOW_PORT 6800
ENV AIRFLOW_S3_LOG ""
ENV AIRFLOW_S3_ENCRYPT False
ENV AIRFLOW_WORKER_PORT 8793

ENV AIRFLOW_FERNET_KEY ""

# Celery parameters
ARG CELERY_VERSION=3.1.17

# Database parameters
ENV DATABASE_HOST mysql
ENV DATABASE_NAME airflow
ENV DATABASE_PASSWORD airflow-pw
ENV DATABASE_PORT 3306
ENV DATABASE_TYPE mysql
ENV DATABASE_USER airflow

# Flower parameters (when using Celery)
ENV FLOWER_PORT 5555

# LDAP parameters
ENV LDAP_URI ldap://10.150.130.250:389

# Redis parameters (when using Celery)
ENV REDIS_HOST redis
ENV REDIS_PORT 6379

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

RUN \
    BUILD_ONLY=' \
        build-essential \
        libblas-dev \
        libffi-dev \
        libkrb5-dev \
        liblapack-dev \
        libsasl2-dev \
        libssl-dev \
        libxml2-dev \
        libxslt-dev \
        python3.4-dev \
    ' \
    && apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends \
        $BUILD_ONLY \
        apt-utils \
        bzip2 \
        ca-certificates \
        cracklib-runtime \
        curl \
        git \
        libmysqlclient-dev \
        libpwquality-tools \
        mysql-client \
        netcat \
        python3.4 \
        wget \
    && useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow \
    && wget --quiet https://bootstrap.pypa.io/get-pip.py \
    && python3.4 get-pip.py \
    && rm -f get-pip.py \
    && pip install Cython \
    && pip install pytz==2015.7 \
    && pip install cryptography \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1 \
    && pip install airflow[celery,crypto,devel_hadoop,hdfs,hive,jdbc,ldap,mysql,s3,slack]==${AIRFLOW_VERSION} \
    && pip install celery[redis]==${CELERY_VERSION} \
    && pip install awscli \
    && apt-get remove --purge -yqq $BUILD_ONLY \
    && apt-get clean

# set airflow user password
RUN \
    password="${AIRFLOW_PASSWORD:-airflow}" \
    && echo "\$password" > /password.in \
    && echo "\$password"  >> /password.in
RUN cat /password.in | passwd -q airflow 

# setup the entrypoint script and airflow configuration file.
COPY entrypoint.sh.in /tmp/entrypoint.sh.in
COPY airflow.cfg.in ${AIRFLOW_HOME}/airflow.cfg.in

RUN sed \
        -e "s|@AIRFLOW_HOME@|${AIRFLOW_HOME}|g" \
        -e "s|@AIRFLOW_DAGS@|${AIRFLOW_DAGS}|g" \
        -e "s|@AIRFLOW_LOGS@|${AIRFLOW_LOGS}|g" \
        -e "s|@AIRFLOW_AUTHENTICATE@|${AIRFLOW_AUTHENTICATE}|g" \
        -e "s|@AIRFLOW_AUTH_BACKEND@|${AIRFLOW_AUTH_BACKEND}|g" \
        -e "s|@AIRFLOW_DAGS_REPO@|${AIRFLOW_DAGS_REPO}|g" \
        -e "s|@AIRFLOW_DAGS_REVISION@|${AIRFLOW_DAGS_REVISION}|g" \
        -e "s|@AIRFLOW_EXECUTOR@|${AIRFLOW_EXECUTOR}|g" \
        -e "s|@AIRFLOW_HOST@|${AIRFLOW_HOST}|g" \
        -e "s|@AIRFLOW_LOAD_EXAMPLES@|${AIRFLOW_LOAD_EXAMPLES}|g" \
        -e "s|@AIRFLOW_PASSWORD@|${AIRFLOW_PASSWORD}|g" \
        -e "s|@AIRFLOW_PORT@|${AIRFLOW_PORT}|g" \
        -e "s|@AIRFLOW_S3_LOG@|${AIRFLOW_S3_LOG}|g" \
        -e "s|@AIRFLOW_S3_ENCRYPT@|${AIRFLOW_S3_ENCRYPT}|g" \
        -e "s|@AIRFLOW_WORKER_PORT@|${AIRFLOW_WORKER_PORT}|g" \
        -e "s|@DATABASE_HOST@|${DATABASE_HOST}|g" \
        -e "s|@DATABASE_NAME@|${DATABASE_NAME}|g" \
        -e "s|@DATABASE_PASSWORD@|${DATABASE_PASSWORD}|g" \
        -e "s|@DATABASE_PORT@|${DATABASE_PORT}|g" \
        -e "s|@DATABASE_TYPE@|${DATABASE_TYPE}|g" \
        -e "s|@DATABASE_USER@|${DATABASE_USER}|g" \
        -e "s|@FLOWER_PORT@|${FLOWER_PORT}|g" \
        -e "s|@LDAP_URI@|${LDAP_URI}|g" \
        -e "s|@REDIS_HOST@|${REDIS_HOST}|g" \
        -e "s|@REDIS_PORT@|${REDIS_PORT}|g" \
        < /tmp/entrypoint.sh.in > /entrypoint.sh \
        && chmod +x /entrypoint.sh

# clean-up
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/man /usr/share/doc /usr/share/doc-base

# Update ownership
RUN chown -R airflow: ${AIRFLOW_HOME}

EXPOSE ${AIRFLOW_PORT}
EXPOSE ${AIRFLOW_WORKER_PORT}
EXPOSE ${FLOWER_PORT}

VOLUME ${AIRFLOW_LOGS}

USER airflow
WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT ["/entrypoint.sh"]

