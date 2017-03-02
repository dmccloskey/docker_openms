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

## Install ProteoWizard

RUN ZIP=pwiz-bin-linux-x86_64-gcc48-release-3_0_9740.zip && \
    wget https://github.com/BioDocker/software-archive/releases/download/proteowizard/$ZIP -O /tmp/$ZIP && \
    unzip /tmp/$ZIP -d /home/user/pwiz/ && \
    chmod -R 755 /home/user/pwiz/* && \
    rm /tmp/$ZIP
ENV PATH /home/user/pwiz/pwiz-bin-linux-x86_64-gcc48-release-3_0_9740:$PATH

## Install OpenMS with pyopenms

# Install python packages using pip3
RUN pip3 install --no-cache-dir \
		autowrap \
		nose \
                wheel \
	&&pip3 install --upgrade

# Clone the repository
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
RUN git checkout tags/Release2.1.0
WORKDIR /home/user/
RUN mkdir openms-build
WORKDIR /home/user/openms-build/

# build the openms executables
RUN cmake -DPYOPENMS=ON -DPYTHON_EXECUTABLE:FILEPATH=/usr/local/bin/python3 -DCMAKE_PREFIX_PATH="/home/user/contrib-build/;/home/user/contrib/;/usr/;/usr/local" -DBOOST_USE_STATIC=OFF -DHAS_XSERVER=Off ../OpenMS && \
  make 
  #  ctest

# add openms to the list libraries
ENV LD_LIBRARY_PATH /home/user/openms-build/lib/:$LD_LIBRARY_PATH

# build pyopenms
RUN make pyopenms

# install pyopenms
WORKDIR /home/user/openms-build/pyOpenMS/
RUN python setup.py install

# add openms to the PATH
ENV PATH /home/user/openms-build/bin/:$PATH

# switch back to user
WORKDIR $HOME
USER user

# set the command
CMD ["python3"]
