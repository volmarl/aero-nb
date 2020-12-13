#
# Aerospike Server Dockerfile
#
# http://github.com/aerospike/aerospike-server.docker
#

FROM ubuntu:18.04
#FROM debian:10 

#ENV AEROSPIKE_VERSION 5.2.0.5
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/
# Install Aerospike Server and Tools
ENV LOGFILE /var/log/aerospike/aerospike.log

ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}
USER root


RUN \
    adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER} \
  && chown -R ${NB_UID} ${HOME} \
  && apt-get update -y \
  && apt-get install -y maven curl openjdk-11-jdk  procps curl iproute2 dumb-init wget python build-essential  lua5.2 gettext-base libcurl4-openssl-dev libssl-dev zlib1g-dev vim net-tools telnet python3-pip python3-dev git  \
  && pip3 -q install pip --upgrade \
  && pip3 install --no-cache-dir vdom==0.5 notebook cryptography psutil jupyter findspark numpy pandas matplotlib sklearn ipython\
  && pip3 install aerospike \
  && wget "https://www.aerospike.com/download/server/latest/artifact/ubuntu18" -O aerospike-server.tgz \
  && mkdir aerospike \
  && tar xzf aerospike-server.tgz --strip-components=1 -C aerospike \
  && dpkg -i aerospike/aerospike-server-*.deb \
  && dpkg -i aerospike/aerospike-tools-*.deb \
  && mkdir -p /var/log/aerospike/ \
  && mkdir -p /var/run/aerospike/ \
  && wget -O java.tgz 'http://aerospike.com/download/client/java/latest/artifact/tgz' \
  && mkdir java_client \
  && tar xzf java.tgz -C java_client \
  && mvn package -f /java_client/aerospike-client-java-*/examples/ \
  && git clone https://github.com/SpencerPark/IJava.git \
  && cd IJava/ && ./gradlew installKernel \
  && rm -rf aerospike-server.tgz aerospike /var/lib/apt/lists/* \
  && rm -rf /opt/aerospike/lib/java \
  && apt-get purge -y \
  && apt autoremove -y 

  


# Add the Aerospike configuration specific to this dockerfile
#COPY aerospike.conf /etc/aerospike/aerospike.conf
COPY aerospike.template.conf /etc/aerospike/aerospike.template.conf
COPY entrypoint.sh /entrypoint.sh
COPY aerospike /etc/init.d/
COPY notebooks* /home/${NB_USER}/notebooks

RUN chown -R ${NB_UID} /etc/aerospike \
  && chown -R ${NB_UID} /opt/aerospike \
  && chown -R ${NB_UID} /var/log/aerospike \
  && chown -R ${NB_UID} /var/run/aerospike \
  && chown -R ${NB_UID} /etc/init.d \
  && chown -R ${NB_UID} /usr/local/bin \
  && chown -R ${NB_UID} ${HOME}


RUN echo "Versions:" > /home/${NB_USER}/notebooks/README.md \
  && python -V >> /home/${NB_USER}/notebooks/README.md \
  && java -version 2>> /home/${NB_USER}/notebooks/README.md \
  && asd --version >> /home/${NB_USER}/notebooks/README.md \
  && echo -e "Aerospike Python Client `pip show aerospike|grep Version|sed -e 's/Version://g'`" >> /home/${NB_USER}/notebooks/README.md \
  && echo -e "Aerospike Java Client 5.0.0" >> /home/${NB_USER}/notebooks/README.md



#COPY jupyter_notebook_config.py /root/.jupyter/jupyter_notebook_config.py

# Mount the Aerospike data directory
# VOLUME ["/opt/aerospike/data"]
# Mount the Aerospike config directory
# VOLUME ["/etc/aerospike/"]


# Expose Aerospike ports
#
#   3000 – service port, for client connections
#   3001 – fabric port, for cluster communication
#   3002 – mesh port, for cluster heartbeat
#   3003 – info port
#   8888 - Jupyter notebook
#
EXPOSE 3000 3001 3002 3003 8888

# Execute the run script in foreground mode
#ENTRYPOINT ["/entrypoint.sh"]
#CMD ["asd"]

# Runs as PID 1 /usr/bin/dumb-init -- /my/script --with --args"
# https://github.com/Yelp/dumb-init

ENTRYPOINT ["/usr/bin/dumb-init", "--", "/entrypoint.sh"]
# Execute the run script in foreground mode
CMD ["asd"]

WORKDIR ${HOME}
USER ${NB_USER}
