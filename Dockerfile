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
#WORKDIR /home/user/ #files downloaded to home folder appear not to persist!
WORKDIR /usr/local/

## Install ProteoWizard
RUN ZIP=pwiz-bin-linux-x86_64-gcc48-release-3_0_9740.zip && \
    wget https://github.com/BioDocker/software-archive/releases/download/proteowizard/$ZIP -O /tmp/$ZIP && \
    unzip /tmp/$ZIP -d /home/user/pwiz/ && \
    chmod -R 755 /home/user/pwiz/* && \
    rm /tmp/$ZIP
ENV PATH /usr/local/pwiz/pwiz-bin-linux-x86_64-gcc48-release-3_0_9740:$PATH

## Install OpenMS with pyopenms
# ENV OPENMS_VERSION tags/Release2.1.0 
# ENV OPENMS_VERSION develop
# ENV OPENMS_REPOSITORY https://github.com/OpenMS.git
ENV OPENMS_CONTRIB_VERSION master
ENV OPENMS_VERSION fix/mrm_pp
ENV OPENMS_REPOSITORY https://github.com/hroest/OpenMS.git

# Install python packages using pip3
RUN pip3 install --no-cache-dir \
		autowrap \
		nose \
                wheel \
	&&pip3 install --upgrade

# Clone the repository
RUN git clone https://github.com/OpenMS/contrib.git && \
    cd /usr/local/contrib && \
    git checkout ${OPENMS_CONTRIB_VERSION} && \
    mkdir /usr/local/contrib-build/

# Change wordir to start building
WORKDIR /usr/local/contrib-build/

RUN cmake -DBUILD_TYPE=SEQAN ../contrib && \
    cmake -DBUILD_TYPE=WILDMAGIC ../contrib && \
    cmake -DBUILD_TYPE=EIGEN ../contrib

WORKDIR /usr/local/
RUN git clone ${OPENMS_REPOSITORY}
WORKDIR /usr/local/OpenMS/
RUN git checkout ${OPENMS_VERSION}
WORKDIR /usr/local/
RUN mkdir openms-build
WORKDIR /usr/local/openms-build/

# build the openms executables
RUN cmake -DPYOPENMS=ON -DPYTHON_EXECUTABLE:FILEPATH=/usr/local/bin/python3 -DCMAKE_PREFIX_PATH="/usr/local/contrib-build/;/usr/local/contrib/;/usr/;/usr/local" -DBOOST_USE_STATIC=OFF -DHAS_XSERVER=Off ../OpenMS && \
  make 
  #  ctest

# add openms to the list of libraries
ENV LD_LIBRARY_PATH /usr/local/openms-build/lib/:$LD_LIBRARY_PATH

# build pyopenms
RUN make pyopenms

# install pyopenms
WORKDIR /usr/local/openms-build/pyOpenMS/
RUN python setup.py install

# add openms to the PATH
ENV PATH /usr/local/openms-build/bin/:$PATH

# switch back to user
WORKDIR $HOME
USER user

# set the command
CMD ["python3"]
