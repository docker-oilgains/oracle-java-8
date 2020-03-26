# Compiling Java code from a container

[toc]



## Introduction

*   We started originally with the Dockerfile written for the image pulled from `phusion/baseimage`

*   As we already know, **Oracle** has changed its policies regarding Java downloads; they do not allow to download automatically their Java resources. For instance, this will not work anymore:

    ```
    RUN echo 'deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main' >> /etc/apt/sources.list && \
        echo 'deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main' >> /etc/apt/sources.list && \
        apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C2518248EEA14886 && \
        apt-get update && \
    ```

    The `webupd8team` PPA will throw error when we try to install Oracle JDK-8. So, bye, bye automation. At least from Oracle Java.

*   The Oracle JDK for any version has to be downloaded manually with an Oracle user account, and one has to agree with terms and conditions.

*   Therefore, the original `Dockerfile` has to be modified in order to install Oracle JDK-8 automatically.

*   After successfully building the Docker image with `phusion/baseimage`, we do the same for Ubuntu 16.04.

*   We will be adding more features and describing some findings. One of the challenging parts was how to deal with:

    *   the fact that the JDK cannot be downloaded automatically from Oracle
    *   the size of the JDK `tar.gz` file (194.1 MB) was too big for GitHub and drove us to install Git LFS to manage that size of file, which in the end did not work out due to limitations imposed by GitHub on the amount of transfers you can do with LFS. This means that you cannot exceed more than 1 GB equivalent of file transfers. I eat up that while testing with Travis. In the end, I had to get rid of `Git LFS` and try a different route, such as hosting that file in Google Drive.
    *   Getting the file through Google Drive while building the container is not an easy task either. It works but requires a little bit of search and quirks until we get it finally working.

*   After getting the file in the container build working we added Ubuntu 18.04, Debian 9, and Debian 10.

*   Although these containers can be built with OpenJDK without so much hassle as doing with Oracle Java, I just wanted to see how it feels to overcome the challenge with the license roadblocks implemented by Oracle.

*   This is also an exercise on to build multiple containers from diverse operating systems, albeit all Linux.



## Create a Dockerfile with Oracle Java 8

### Original Dockerfile for `phusion/baseimage`

Source: https://runnable.com/docker/java/dockerize-your-java-application

```dockerfile
# Original Dockerfile for phusion

FROM  phusion/baseimage:0.9.17

MAINTAINER  Author Name <author@email.com>

RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list

RUN apt-get -y update

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -q python-software-properties software-properties-common

ENV JAVA_VER 8
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

RUN echo 'deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main' >> /etc/apt/sources.list && \
    echo 'deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main' >> /etc/apt/sources.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C2518248EEA14886 && \
    apt-get update && \
    echo oracle-java${JAVA_VER}-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections && \
    apt-get install -y --force-yes --no-install-recommends oracle-java${JAVA_VER}-installer oracle-java${JAVA_VER}-set-default && \
    apt-get clean && \
    rm -rf /var/cache/oracle-jdk${JAVA_VER}-installer

RUN update-java-alternatives -s java-8-oracle

RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-oracle" >> ~/.bashrc

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

CMD ["/sbin/my_init"]
```

### Modified file for `phusion`

This is the modified version of the file above. This will work fine locally, I mean, if you download the JDK-8 from Oracle `jdk-8u231-linux-x64.tar.gz`, and put it in the same folder as the Dockerfile.

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

We save this file as `phusion.Dockerfile`.

### Dockerfile for Ubuntu 16.04

```dockerfile
# Dockerfile

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

We save this file as `ubuntu16.Dockerfile`.

## Build the image

### `phusion/baseimage`

```bash
docker build --file phusion.Dockerfile -t oracle-java-8:phusion .
```

### Ubuntu 16.04

```bash
docker build --file ubuntu16.Dockerfile.ubuntu -t ubuntu/oracle-java-8:ubuntu16 .
```



## Compile Java source code with the container

Ensure the Java code is in the same folder where you are running this command.

### `phusion/baseimage`

```bash
docker run --rm -v $PWD:/app -w /app oracle-java-8:phusion javac Main.java
```

### Ubuntu 16.04

```bash
docker run --rm -v $PWD:/app -w /app ubuntu/oracle-java-8:ubuntu16 javac Main.java
```



## Run the Java class

### `phusion/baseimage`

```
docker run --rm -v $PWD:/app -w /app oracle-java-8:phusion java Main
```

### Ubuntu

```
docker run --rm -v $PWD:/app -w /app ubuntu/oracle-java:8 java Main
```



## Downloading big files from Google Drive

Solution here: https://gist.github.com/iamtekeste/3cdfd0366ebfd2c0d805

Since Oracle Java JDK-8 cannot be downloaded and installed automatically from a Docker container, after going through the pain of installing and make `Git LFS` work, and then trash it away because of greedy GitHub, finally found that hosting the big file in Google Drive works fine. Although it is not straight forward. These are steps:

1.  Copy the big file `jdk-8u231-linux-x64.tar.gz` to a folder in your Google Drive. I will use mine for this example. I use it in my container too.

2.  When the file has synchronized with the cloud, go to the Google Drive web UI, right click on the file and choose share.

3.  Click on `Advanced`

4.  Click on `Change`

5.  Select on `Public on the web`. Press `Save`.
    ![image-20200326161333922](assets/README/image-20200326161333922.png)

6.  Copy the long link under `Link to share`:
    ![image-20200326161431921](assets/README/image-20200326161431921.png)

    ```
    https://drive.google.com/file/d/1fN3KvH7UBEvIKTL2ZpTkk1PC3xDdA1gN/view?usp=sharing
    ```

    Press `Done`.

7.  Extract the file id, which in this example is:

    ```
    1fN3KvH7UBEvIKTL2ZpTkk1PC3xDdA1gN
    ```

8.  We should replace this file id wherever we find `FILEID` in this string, and `jdk-8u231-linux-x64.tar.gz` where it says `FILENAME`.  

    ```
    wget --load-cookies /tmp/cookies.txt \
    	"https://docs.google.com/uc?export=download&confirm=$( \
        wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies \
        --no-check-certificate \
        'https://docs.google.com/uc?export=download&id=`FILEID`' \
        -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=`FILEID`" \
        -O FILENAME \
        && rm -rf /tmp/cookies.txt
    ```

    After replacing the values we get:

    ```
    wget --load-cookies /tmp/cookies.txt \
    	"https://docs.google.com/uc?export=download&confirm=$( \
        wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies \
        --no-check-certificate \
        'https://docs.google.com/uc?export=download&id=1fN3KvH7UBEvIKTL2ZpTkk1PC3xDdA1gN' \
        -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=1fN3KvH7UBEvIKTL2ZpTkk1PC3xDdA1gN" \
        -O jdk-8u231-linux-x64.tar.gz \
        && rm -rf /tmp/cookies.txt
    ```

    You can test in your terminal. If the string is correct, you should get a file `jdk-8u231-linux-x64.tar.gz` of 194.1 MB size.

    We will make use of this command in our Dockerfile.



## Final Dockerfiles

After finding a way to download and install the Oracle JDK-8 from Google Drive, we write the final Dockerfiles for `phusion`, `Ubuntu 16.04`, `Ubuntu 18.04`, `Debian 9`, and `Debian 10`. I will only show here the Dockerfiles for Ubuntu 18.04 and Debian 10. 

### Dockerfile for Ubuntu 18.04

```dockerfile
FROM ubuntu:18.04

RUN apt-get -y update

RUN DEBIAN_FRONTEND=noninteractive 
# apt-get install -y -q python-software-properties software-properties-common
RUN apt-get install -y wget bzip2

ENV JAVA_VER 8

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /opt/java-jdk/jdk1.8.0_231


# copy Oracle Java 8 to container
# COPY jdk-8u231-linux-x64.tar.gz .
# RUN wget --quiet https://github.com/docker-oilgains/oracle-java-8/raw/master/jdk-8u231-linux-x64.tar.gz


# Get the JDK-8 from Google Drive
RUN wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$( \
    wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies \
    --no-check-certificate 'https://docs.google.com/uc?export=download&id=1fN3KvH7UBEvIKTL2ZpTkk1PC3xDdA1gN' \
    -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=1fN3KvH7UBEvIKTL2ZpTkk1PC3xDdA1gN" \
    -O jdk-8u231-linux-x64.tar.gz && rm -rf /tmp/cookies.txt
RUN mkdir /opt/java-jdk
RUN tar -C /opt/java-jdk -zxf ./jdk-8u231-linux-x64.tar.gz

# configure Java
RUN update-alternatives --install /usr/bin/java     java  /opt/java-jdk/jdk1.8.0_231/bin/java 1
RUN update-alternatives --install /usr/bin/javac    javac /opt/java-jdk/jdk1.8.0_231/bin/javac 1
RUN update-alternatives --install /usr/bin/javaws   javaws /opt/java-jdk/jdk1.8.0_231/bin/javaws 1
RUN update-alternatives --install /usr/bin/jcontrol jcontrol /opt/java-jdk/jdk1.8.0_231/bin/jcontrol 1

RUN echo "export JAVA_HOME=/opt/java-jdk/jdk1.8.0_231" >> ~/.bashrc
```

I save this file as `ubuntu18.Dockerfile`.

### Dockerfile for Debian 10

```
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

```

I save this file as `debian10.Dockerfile`.



## Java source code for `Main.java`

```java
public class Main
{
     public static void main(String[] args) {
        System.out.println("Hello, World");
    }
}
```





## How to deal with the 194 MB JDK-8 file

>   This section is for reference only. The `Git LFS` option did not work well due to limitations on the bandwidth by GitHub.

In this case the JDK-8 file `jdk-8u231-linux-x64.tar.gz` (194.1 MB) could not be able to be pushed to Git as the other files; we have to use `Git LFS`.

First, we have to install `Git LFS`, and then follow some instructions to push it as an `LFS` file. We have to be careful of not pushing the big file with the rest of small files in the Git repo otherwise we get stuck without being able to push anything.

### Install `Git LFS`

### Make the 194 MB  `tar` file a `LFS` file

```
 git lfs track "*.tar.gz"
 git add .gitattributes
 git add jdk-8u231-linux-x64.tar.gz
 git commit -m "Add Oracle jdk-8 tar.gz file"
 git push origin master
```

Now, we can deal with the smaller files.

As a way of testing the file went right, we download the 194 MB file from GitHub. Just click on the download button:

![image-20200325181522513](assets/README/image-20200325181522513.png)

And save it as we usually do with any file:

<img src="assets/README/image-20200325181624337.png" alt="image-20200325181624337" style="zoom:80%;" />



### Get the 194 MB file from GitHub with `wget`

In DockerHub we will not be able to use the `Dockerfile` command `COPY` to copy the file `jdk-8u231-linux-x64.tar.gz` that is living in the **GitHub** repo; we have to obtaining it using the Linux command `wget`. So, we add this line to the Dockerfile to "download" the 194 MB file:

```
RUN wget --quiet https://github.com/docker-oilgains/oracle-java-8/raw/master/jdk-8u231-linux-x64.tar.gz
```

>   This will run in **DockerHub** and **Travis**.

### Notes on using `Git LFS`

1.  To build the container based on Oracle JDK-8, at some point we made use of `Git LFS`. The `tar` file was downloaded manually from Oracle and then pushed as a `LFS`  file.

2.  The way a Docker image is built in **DockerHub** is different than the way the image is built in **Travis**. In Travis the command `COPY` works for the Java `tar` file while in DockerHub only copies the string with the Git address to the file. Maybe this is because the file was pushed as a LFS file instead of a normal file.

3.  Downloading multiple times from LFS in GitHub produces this error:

    ![image-20200325190818762](assets/README/image-20200325190818762.png)

    ```
    Error downloading object: jdk-8u231-linux-x64.tar.gz (76062c8): Smudge error: Error downloading jdk-8u231-linux-x64.tar.gz (76062c86e9177baf1417e714bd399ee05ee76dcaf7a33a5e18ac7459ff61afe2): batch response: This repository is over its data quota. Account responsible for LFS bandwidth should purchase more data packs to restore access.
    ```

    About Git LFS excess bandwidth, read here:

    *   https://help.github.com/en/github/managing-large-files/about-storage-and-bandwidth-usage
    *   https://github.com/nabla-c0d3/nassl/issues/17
    *   https://stackoverflow.com/questions/56410647/how-to-get-large-files-from-git-lfs-when-error-even-though-you-have-credits