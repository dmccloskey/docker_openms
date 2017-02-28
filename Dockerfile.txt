# Dockerfile to build openMS images for MS data processing
# Based on Ubuntu

# Add python3_scientific
FROM dmccloskey/python3scientific:latest

# File Author / Maintainer
LABEL maintainer Douglas McCloskey <dmccloskey87@gmail.com>

# Switch to root for install
USER root

# Instal openMS dependencies
RUN apt-get -y update && \
    apt-get install -y \
    cmake \
    g++ \
    autoconf \
    qt4-dev-tools \
    patch \
    libtool \
    make \
    git \
    software-properties-common \
    python-software-properties \
    libboost-all-dev \
    libsvm-dev \
    libglpk-dev \
    libzip-dev \
    zlib1g-dev \
    libxerces-c-dev \
    libbz2-dev && \
    apt-get clean && \
    apt-get purge && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Change to working dir
WORKDIR /home/user/

RUN git clone https://github.com/OpenMS/contrib.git && \
    mkdir /home/user/contrib-build/

# Change wordir to start building
WORKDIR /home/user/contrib-build/

RUN cmake -DBUILD_TYPE=SEQAN ../contrib && \
    cmake -DBUILD_TYPE=WILDMAGIC ../contrib && \
    cmake -DBUILD_TYPE=EIGEN ../contrib

WORKDIR /home/user/

RUN git clone https://github.com/OpenMS/OpenMS.git

WORKDIR /home/user/OpenMS/

RUN git checkout tags/Release2.0.0

WORKDIR /home/user/

RUN mkdir openms-build

WORKDIR /home/user/openms-build/

RUN cmake -DCMAKE_PREFIX_PATH="/home/user/contrib-build/;/home/user/contrib/;/usr/;/usr/local" -DBOOST_USE_STATIC=OFF -DHAS_XSERVER=Off ../OpenMS && \
  make
  #  ctest

ENV PATH /home/user/openms-build/bin/:$PATH

# switch back to user
WORKDIR $HOME
USER user

# set the command
CMD ["python3"]