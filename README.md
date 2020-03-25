# Compile Java code from a container

[toc]

Source: https://runnable.com/docker/java/dockerize-your-java-application

## Create a Dockerfile

### Original Dockerfile for phusion

```dockerfile
# Dockerfile
FROM  phusion/baseimage:0.9.17

RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list

RUN apt-get -y update

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -q python-software-properties software-properties-common

ENV JAVA_VER 8

# # Define commonly used JAVA_HOME variable
ENV JAVA_HOME /opt/java-jdk/jdk1.8.0_231

# copy Oracle Java8 to container
COPY jdk-8u231-linux-x64.tar.gz .

RUN mkdir /opt/java-jdk
RUN tar -C /opt/java-jdk -zxf ./jdk-8u231-linux-x64.tar.gz
RUN update-alternatives --install /usr/bin/java  java  /opt/java-jdk/jdk1.8.0_231/bin/java 1
RUN update-alternatives --install /usr/bin/javac javac /opt/java-jdk/jdk1.8.0_231/bin/javac 1

RUN echo "export JAVA_HOME=/opt/java-jdk/jdk1.8.0_231" >> ~/.bashrc
```



### Modified Dockerfile for Ubuntu

```
# Dockerfile

# FROM  phusion/baseimage:0.9.17
FROM ubuntu:16.04

# RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list

RUN apt-get -y update

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -q python-software-properties software-properties-common

ENV JAVA_VER 8

# # Define commonly used JAVA_HOME variable
ENV JAVA_HOME /opt/java-jdk/jdk1.8.0_231


# copy Oracle Java8 to container
COPY jdk-8u231-linux-x64.tar.gz .

RUN mkdir /opt/java-jdk
RUN tar -C /opt/java-jdk -zxf ./jdk-8u231-linux-x64.tar.gz
RUN update-alternatives --install /usr/bin/java  java  /opt/java-jdk/jdk1.8.0_231/bin/java 1
RUN update-alternatives --install /usr/bin/javac javac /opt/java-jdk/jdk1.8.0_231/bin/javac 1
RUN update-alternatives --install /usr/bin/javaws javaws /opt/java-jdk/jdk1.8.0_231/bin/javaws 1
RUN update-alternatives --install /usr/bin/jcontrol jcontrol /opt/java-jdk/jdk1.8.0_231/bin/jcontrol 1

# RUN echo "export JAVA_HOME=/opt/java-jdk/jdk1.8.0_231" >> ~/.bashrc
```



## Build the image

### phusion OS

```
docker build --file Dockerfile -t oracle-java-8:phusion .
```

### Ubuntu OS

```
docker build --file Dockerfile.ubuntu -t ubuntu/oracle-java:8 .
```



## Compile Java source code with the container

Ensure the Java code is in the same folder where you are running this command.

### phusion OS

```
docker run --rm -v $PWD:/app -w /app oracle-java-8:phusion javac Main.java
```

### Ubuntu OS

```
docker run --rm -v $PWD:/app -w /app ubuntu/oracle-java:8 javac Main.java
```



## Run the Java class

### phusion

```
docker run --rm -v $PWD:/app -w /app oracle-java-8:phusion java Main
```

### Ubuntu

```
docker run --rm -v $PWD:/app -w /app ubuntu/oracle-java:8 java Main
```



## Java source code

```java
public class Main
{
     public static void main(String[] args) {
        System.out.println("Hello, World");
    }
}
```

