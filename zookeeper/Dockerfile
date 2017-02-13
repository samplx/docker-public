FROM samplx/java8:latest
MAINTAINER samplx <jb@samplx.org>

ARG DIST_GPG_KEY=C823E3E5B12AF29C67F81976F5CECB3CB5E9BD2D
ARG DIST_NAME=zookeeper-3.4.9

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Timezone parameters
ENV TIMEZONE America/Chicago

# Zookeeper parameters
ENV ZOO_CLIENT_PORT=2181
ENV ZOO_CONF_DIR=/var/lib/zookeeper/conf
ENV ZOO_DATA_DIR=/var/lib/zookeeper/data
ENV ZOO_DATA_LOG_DIR=/var/lib/zookeeper/datalog
ENV ZOO_ELECTION_PORT=3888
ENV ZOO_FOLLOWER_PORT=2888
ENV ZOO_INSTALL_DIR=/usr/local
ENV ZOO_SYNC_LIMIT=2
ENV ZOO_TICK_TIME=2000
ENV ZOO_USER=zookeeper

# Setup the timezone
RUN echo "${TIMEZONE}" > /etc/timezone \
    && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime

# Set locale
RUN apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends \
      apt-utils \
      gnupg \
      locales \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# locale
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Create user and directories
RUN useradd -ms /bin/bash "$ZOO_USER" \
    && mkdir -p "$ZOO_DATA_LOG_DIR" "$ZOO_DATA_DIR" "$ZOO_CONF_DIR" "$ZOO_INSTALL_DIR" \
    && chown "$ZOO_USER:$ZOO_USER" "$ZOO_DATA_LOG_DIR" "$ZOO_DATA_DIR" "$ZOO_CONF_DIR"

RUN set -x \
    && echo "deb http://ftp.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list \
    && apt-get update \
    && apt-get install -yqq -t jessie-backports gosu \
    && wget --quiet "http://www.apache.org/dist/zookeeper/$DIST_NAME/$DIST_NAME.tar.gz" \
    && wget --quiet "http://www.apache.org/dist/zookeeper/$DIST_NAME/$DIST_NAME.tar.gz.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-key "$DIST_GPG_KEY" \
    && gpg --batch --verify "$DIST_NAME".tar.gz.asc "$DIST_NAME".tar.gz \
    && tar -C "$ZOO_INSTALL_DIR" -xvf "$DIST_NAME".tar.gz \
    && mv "$ZOO_INSTALL_DIR/$DIST_NAME/conf/"* "$ZOO_CONF_DIR" \
    && rm -rf "$GNUPGHOME" "$DIST_NAME".* \
      "$ZOO_INSTALL_DIR/$DIST_NAME/contrib" \
      "$ZOO_INSTALL_DIR/$DIST_NAME/dist-maven" \
      "$ZOO_INSTALL_DIR/$DIST_NAME/docs" \
      "$ZOO_INSTALL_DIR/$DIST_NAME/recipes" \
      "$ZOO_INSTALL_DIR/$DIST_NAME/src" \
    && apt-get clean all

VOLUME ["$ZOO_DATA_DIR", "$ZOO_DATA_LOG_DIR"]
WORKDIR "$ZOO_INSTALL_DIR/$DIST_NAME"

ENV PATH="$PATH:$ZOO_INSTALL_DIR/$DIST_NAME/bin"
ENV ZOOCFGDIR="$ZOO_CONF_DIR"

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["zkServer.sh", "start-foreground"]
