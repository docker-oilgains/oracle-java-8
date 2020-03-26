FROM debian:10

RUN apt-get -y update

RUN DEBIAN_FRONTEND=noninteractive 
RUN apt-get install -y wget bzip2

ENV JAVA_VER 8

# # Define commonly used JAVA_HOME variable
ENV JAVA_HOME /opt/java-jdk/jdk1.8.0_231

ENV FILE_ID=1fN3KvH7UBEvIKTL2ZpTkk1PC3xDdA1gN


# Get Oracle Java JDK 8 and copy it to /opt
# COPY jdk-8u231-linux-x64.tar.gz .
# RUN wget --quiet https://github.com/docker-oilgains/oracle-java-8/raw/master/jdk-8u231-linux-x64.tar.gz
RUN wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$( \
    wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies \
    --no-check-certificate 'https://docs.google.com/uc?export=download&id=1fN3KvH7UBEvIKTL2ZpTkk1PC3xDdA1gN' \
    -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=1fN3KvH7UBEvIKTL2ZpTkk1PC3xDdA1gN" \
    -O jdk-8u231-linux-x64.tar.gz && rm -rf /tmp/cookies.txt

RUN ls -alh jdk-8u231-linux-x64.tar.gz
RUN mkdir /opt/java-jdk
RUN tar -C /opt/java-jdk -zxf ./jdk-8u231-linux-x64.tar.gz

# configure Java
RUN update-alternatives --install /usr/bin/java     java     /opt/java-jdk/jdk1.8.0_231/bin/java     1
RUN update-alternatives --install /usr/bin/javac    javac    /opt/java-jdk/jdk1.8.0_231/bin/javac    1
RUN update-alternatives --install /usr/bin/javaws   javaws   /opt/java-jdk/jdk1.8.0_231/bin/javaws   1
RUN update-alternatives --install /usr/bin/jcontrol jcontrol /opt/java-jdk/jdk1.8.0_231/bin/jcontrol 1

# add JAVA_HOME
RUN echo "export JAVA_HOME=/opt/java-jdk/jdk1.8.0_231" >> ~/.bashrc
