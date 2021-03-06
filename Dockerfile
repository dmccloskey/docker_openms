# Dockerfile to build openMS images for MS data processing
# Based on Ubuntu

# Add python3_scientific
FROM dmccloskey/python3scientific:latest

# File Author / Maintainer
LABEL maintainer Douglas McCloskey <dmccloskey87@gmail.com>

# Switch to root for install
USER root

# OpenMS versions
ENV OPENMS_CONTRIB_VERSION master
# ENV OPENMS_VERSION tags/Release2.1.0 
# ENV OPENMS_VERSION develop
# ENV OPENMS_REPOSITORY https://github.com/OpenMS.git
ENV OPENMS_VERSION feature/tml_dataweights
# ENV OPENMS_VERSION develop
ENV OPENMS_REPOSITORY https://github.com/dmccloskey/OpenMS.git

# Instal openMS dependencies
RUN apt-get -y update && \
    apt-get install -y \
    # cmake \
    g++ \
    autoconf \
    qt4-dev-tools \
	# qtconnectivity5-dev \
	qtbase5-dev \
	# qtmobility-dev \
	qttools5-dev \
	# qtmultimedia5-dev \
	# libqt5opengl5-dev \
	# qtpositioning5-dev \
	# qtdeclarative5-dev \
	# qtscript5-dev \
	# libqt5svg5-dev \
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
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    # install cmake from source
    cd /usr/local/ && \
    wget http://www.cmake.org/files/v3.8/cmake-3.8.2.tar.gz && \
    tar xf cmake-3.8.2.tar.gz && \
    cd cmake-3.8.2 && \
    ./configure && \
    make && \
    # install proteowizard
    cd /usr/local/  && \
    ZIP=pwiz-bin-linux-x86_64-gcc48-release-3_0_9740.zip && \
    wget https://github.com/BioDocker/software-archive/releases/download/proteowizard/$ZIP -O /tmp/$ZIP && \
    unzip /tmp/$ZIP -d /home/user/pwiz/ && \
    chmod -R 755 /home/user/pwiz/* && \
    rm /tmp/$ZIP && \
    # Install python packages using pip3
    pip3 install --no-cache-dir \
        autowrap \
        nose \
        wheel \
    &&pip3 install --upgrade

# add pwiz to the path
ENV PATH /usr/local/pwiz/pwiz-bin-linux-x86_64-gcc48-release-3_0_9740:$PATH

# add cmake to the path
ENV PATH /usr/local/cmake-3.8.2/bin:$PATH

# Clone the OpenMS/contrib repository
RUN cd /usr/local/  && \
    git clone https://github.com/OpenMS/contrib.git && \
    cd /usr/local/contrib && \
    git checkout ${OPENMS_CONTRIB_VERSION} && \
    mkdir /usr/local/contrib-build/  && \
    # Build OpenMS/contrib
    cd /usr/local/contrib-build/  && \
    cmake -DBUILD_TYPE=SEQAN ../contrib && \
    cmake -DBUILD_TYPE=WILDMAGIC ../contrib && \
    cmake -DBUILD_TYPE=EIGEN ../contrib && \
    cmake -DBUILD_TYPE=COINOR ../contrib && \
    cmake -DBUILD_TYPE=ZLIB ../contrib && \
    cmake -DBUILD_TYPE=BZIP2 ../contrib && \
    cmake -DBUILD_TYPE=GLPK ../contrib && \
    cmake -DBUILD_TYPE=LIBSVM ../contrib && \
    cmake -DBUILD_TYPE=SQLITE ../contrib && \
    cmake -DBUILD_TYPE=XERCESC ../contrib && \
    cmake -DBUILD_TYPE=BOOST ../contrib && \
    # clone the OpenMS repository
    cd /usr/local/ && \
    git clone ${OPENMS_REPOSITORY} && \
    cd /usr/local/OpenMS/ && \
    git checkout ${OPENMS_VERSION} && \
    cd /usr/local/ && \
    mkdir openms-build && \
    cd /usr/local/openms-build/ && \
    # build the OpenMS executables
    #Release
    cmake -DPYOPENMS=ON -DPYTHON_EXECUTABLE:FILEPATH=/usr/local/bin/python3 -DCMAKE_PREFIX_PATH="/usr/local/contrib-build/;/usr/local/contrib/;/usr/;/usr/local" -DBOOST_USE_STATIC=OFF -DHAS_XSERVER=Off ../OpenMS && \
    # #Debug
    # RUN cmake -DCMAKE_BUILD_TYPE=Debug -DPYOPENMS=ON -DPYTHON_EXECUTABLE:FILEPATH=/usr/local/bin/python3 -DCMAKE_PREFIX_PATH="/usr/local/contrib-build/;/usr/local/contrib/;/usr/;/usr/local" -DBOOST_USE_STATIC=OFF -DHAS_XSERVER=Off ../OpenMS && \
    make -j8
    #  ctest

# add openms to the list of libraries
ENV LD_LIBRARY_PATH /usr/local/openms-build/lib/:$LD_LIBRARY_PATH

# build pyopenms
RUN cd /usr/local/openms-build/ && \
    make -j8 pyopenms && \
    cd /usr/local/openms-build/pyOpenMS/ && \
    # install pyopenms
    python setup.py install

# add openms to the PATH
ENV PATH /usr/local/openms-build/bin/:$PATH

# switch back to user
WORKDIR $HOME
USER user

# set the command
CMD ["python3"]
