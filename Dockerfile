FROM jupyter/scipy-notebook:228ae7a44e0c
MAINTAINER Shane Husson shane.a.husson@gmail.com

USER root

RUN echo "deb http://http.debian.net/debian jessie-backports main" >> /etc/apt/sources.list && \
    apt-get update --fix-missing && \
    apt-get upgrade -y && \
    apt-get install -y \
    ca-certificates \
    cmake \
    curl \
    g++ \
    git \
    openjdk-8-jdk \
    wget

ENV SPARK_HOME=/usr/spark/spark-2.1.0-bin-hadoop2.7 \
    HAIL_HOME=/usr/hail \
    PATH=/opt/conda/bin:$PATH:/usr/spark/spark-2.1.0-bin-hadoop2.7/bin:/usr/hail/build/install/hail/bin/

# install spark
RUN mkdir /usr/spark && \
    curl -sL --retry 3 \
    "http://apache.mirror.serversaustralia.com.au/spark/spark-2.1.0/spark-2.1.0-bin-hadoop2.7.tgz" \
    | gzip -d \
    | tar x -C /usr/spark && \
    chown -R root:root $SPARK_HOME

# build and install hail
RUN git clone https://github.com/broadinstitute/hail.git ${HAIL_HOME} && \
    cd ${HAIL_HOME} && \
    ./gradlew shadowJar

ENV PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.4-src.zip:$HAIL_HOME/python \
    SPARK_CLASSPATH=$HAIL_HOME/build/libs/hail-all-spark.jar

# setup jupyter note book for spawning through jupyter hub
RUN mkdir /srv/singleuser/ && \
    wget -q https://raw.githubusercontent.com/jupyterhub/dockerspawner/0.6.0/singleuser/singleuser.sh -O /srv/singleuser/singleuser.sh && \
    chown jovyan /srv/singleuser/singleuser.sh && \
    wget --quiet https://storage.googleapis.com/hail-tutorial/Hail_Tutorial_Data-v1.tgz && \
    tar -zxf Hail_Tutorial_Data-v1.tgz && \
    rm -rf Hail_Tutorial_Data-v1.tgz

COPY data/tutorial.ipynb data/plots.ipynb data/genepattern.ipynb data/ ./

USER jovyan

# RUN sh /srv/singleuser/singleuser.sh -h
CMD ["sh", "/srv/singleuser/singleuser.sh"]
