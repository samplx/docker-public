FROM samplx/java8:latest
MAINTAINER samplx <jb@samplx.org>

ARG DIST_NAME=hadoop-2.7.3
ARG DIST_KEYS_URL=http://www.apache.org/dist/hadoop/common/KEYS
ENV DIST_HOST=http://www-us.apache.org

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Hadoop directories
ENV HADOOP_INSTALL_DIR /usr/local
ENV HADOOP_HOME ${HADOOP_INSTALL_DIR}/${DIST_NAME}

ENV HADOOP_COMMON_HOME ${HADOOP_HOME}
ENV HADOOP_HDFS_HOME ${HADOOP_HOME}
ENV HADOPP_MAPRED_HOME ${HADOOP_HOME}
ENV HADOOP_YARN_HOME ${HADOOP_HOME}

ENV HADOOP_CONF_DIR ${HADOOP_HOME}/etc/hadoop
ENV HADOOP_INPUT_DIR ${HADOPP_HOME}/input
ENV HADOOP_LOG_DIR ${HADOOP_HOME}/logs
ENV HADOOP_PID_DIR ${HADOOP_HOME}/run

ENV HADOOP_USER=hadoop
ENV HADOOP_USER_HOME=/home/hadoop

# locale
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Get dependencies
RUN set -x \
    && apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends \
      rsync \
      ssh

# Create user, directories, setup SSH
RUN set -x \
  && useradd -ms /bin/bash -d "$HADOOP_USER_HOME" "$HADOOP_USER" \
  && mkdir -p "$HADOOP_USER_HOME/.ssh" \
  && ssh-keygen -t rsa -P '' -f "$HADOOP_USER_HOME/.ssh/id_rsa" \
  && cp "$HADOOP_USER_HOME/.ssh/id_rsa.pub" "$HADOOP_USER_HOME/.ssh/authorized_keys" \
  && echo 'StrictHostKeyChecking no' > "$HADOOP_USER_HOME/.ssh/config" \
  && chmod 600 "$HADOOP_USER_HOME/.ssh/authorized_keys" \
  && chmod 700 "$HADOOP_USER_HOME/.ssh" \
  && chown -R "$HADOOP_USER:$HADOOP_USER" "$HADOOP_USER_HOME"

RUN set -x \
  && wget --quiet "$DIST_KEYS_URL" \
  && wget --quiet "$DIST_HOST/dist/hadoop/common/$DIST_NAME/$DIST_NAME.tar.gz" \
  && wget --quiet "$DIST_HOST/dist/hadoop/common/$DIST_NAME/$DIST_NAME.tar.gz.asc" \
  && export GNUPGHOME="$(mktemp -d)" \
  && gpg --import KEYS \
  && gpg --batch --verify "$DIST_NAME".tar.gz.asc "$DIST_NAME".tar.gz \
  && tar -C "$HADOOP_INSTALL_DIR" -xf "$DIST_NAME".tar.gz \
  && rm -f KEYS "$DIST_NAME".tar.gz "$DIST_NAME".tar.gz.asc \
  && ln -s "$HADOOP_INSTALL_DIR/$DIST_NAME" "$HADOOP_INSTALL_DIR/hadoop" \
  && mkdir -p "$HADOOP_LOG_DIR" "$HADOOP_PID_DIR" "$HADOOP_INPUT_DIR" \
  && cp "$HADOOP_CONF_DIR"/*.xml "$HADOOP_INPUT_DIR" \
  && chown -R "$HADOOP_USER:$HADOOP_USER" "$HADOOP_INSTALL_DIR/$DIST_NAME"

COPY etc/core-site.xml.template "$HADOOP_CONF_DIR"/core-site.xml.template
RUN set -x \
  && sed -e 's/HOSTNAME/localhost/' "$HADOOP_CONF_DIR/core-site.xml.template" \
    > "$HADOOP_CONF_DIR/core-site.xml"
COPY etc/hdfs-site.xml "$HADOOP_CONF_DIR/hdfs-site.xml"
COPY etc/mapred-site.xml "$HADOOP_CONF_DIR/mapred-site.xml"
COPY etc/yarn-site.xml "$HADOOP_CONF_DIR/yarn-site.xml"
COPY etc/hadoop-env.sh "$HADOOP_CONF_DIR/hadoop-env.sh"

ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
ENV PATH "$PATH:$JAVA_HOME/bin"

RUN set -x \
    && echo "deb http://ftp.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list \
    && apt-get update \
    && apt-get install -yqq -t jessie-backports gosu \
    && apt-get clean

RUN set -x \
  && chmod +x "$HADOOP_CONF_DIR"/*-env.sh \
  && gosu $HADOOP_USER $HADOOP_HOME/bin/hdfs namenode -format

COPY entrypoint.sh /entrypoint.sh

RUN set -x \
  && chmod 755 /entrypoint.sh \
  && chown $HADOOP_USER:$HADOOP_USER /entrypoint.sh \
  && /etc/init.d/ssh start \
  && gosu $HADOOP_USER "$HADOOP_HOME"/sbin/start-dfs.sh \
  && gosu $HADOOP_USER "$HADOOP_HOME"/bin/hdfs dfs -mkdir -p /user/hadoop \
  && gosu $HADOOP_USER "$HADOOP_HOME"/bin/hdfs dfs -put "$HADOOP_CONF_DIR"/ input

ENV HADOOP_MAPRED_PID_DIR ${HADOOP_PID_DIR}
ENV HADOOP_MAPRED_IDENT_STRING ${HADOOP_USER}

# HDFS Ports
EXPOSE 8020 9000 50010 50020 50070 50075 50090

# Mapred Ports
EXPOSE 10020 19888

# YARN Ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088

# Other Ports
EXPOSE 2122 49707

ENTRYPOINT ["/entrypoint.sh"]
CMD ["-d"]
