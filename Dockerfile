# Dockerfile to build openMS images for MS data processing
# Based on Ubuntu

# Add python3_scientific
FROM dmccloskey/docker-openms-contrib:develop

# File Author / Maintainer
LABEL maintainer Douglas McCloskey <dmccloskey87@gmail.com>

# Switch to root for install
USER root

RUN pip3 install --no-cache-dir \
		autowrap==0.14.0 \
	&&pip3 install --upgrade 

# OpenMS versions
ENV OPENMS_VERSION develop
ENV OPENMS_REPOSITORY https://github.com/dmccloskey/OpenMS.git

RUN cd /usr/local/  && \
    # clone the OpenMS repository
    git clone ${OPENMS_REPOSITORY} && \
    cd /usr/local/OpenMS/ && \
    git checkout ${OPENMS_VERSION} && \
    cd /usr/local/ && \
    mkdir openms-build && \
    cd /usr/local/openms-build/ && \
    # define QT environment
    QT_ENV=$(find /opt -name 'qt*-env.sh') && \
    # build the OpenMS executables
    # source ${QT_ENV} && cmake -DPYOPENMS=OFF -DPYTHON_EXECUTABLE:FILEPATH=/usr/local/bin/python3 -DCMAKE_PREFIX_PATH="/usr/local/contrib-build/;/usr/local/contrib/;/usr/;/usr/local" -DBOOST_USE_STATIC=OFF -DHAS_XSERVER=Off ../OpenMS && \
    /bin/bash -c "source ${QT_ENV} && cmake -DWITH_GUI=OFF -DPYOPENMS=ON -DPYTHON_EXECUTABLE:FILEPATH=/usr/local/bin/python3 -DCMAKE_PREFIX_PATH='/usr/local/contrib-build/;/usr/local/contrib/;/usr/;/usr/local' -DBOOST_USE_STATIC=OFF -DHAS_XSERVER=Off ../OpenMS" && \
    #Release (no pyopenms)
    # cmake -DPYOPENMS=OFF -DPYTHON_EXECUTABLE:FILEPATH=/usr/local/bin/python3 -DCMAKE_PREFIX_PATH="/usr/local/contrib-build/;/usr/local/contrib/;/usr/;/usr/local" -DBOOST_USE_STATIC=OFF -DHAS_XSERVER=Off ../OpenMS && \
    #Release (no pyopenms)
    # cmake -DWITH_GUI=OFF -DPYOPENMS=ON -DPYTHON_EXECUTABLE:FILEPATH=/usr/local/bin/python3 -DCMAKE_PREFIX_PATH="/usr/local/contrib-build/;/usr/include/qt5" -DBOOST_USE_STATIC=OFF -DHAS_XSERVER=Off ../OpenMS && \
    #Debug
    # cmake -DCMAKE_BUILD_TYPE=Debug -DPYOPENMS=ON -DPYTHON_EXECUTABLE:FILEPATH=/usr/local/bin/python3 -DCMAKE_PREFIX_PATH="/usr/local/contrib-build/;/usr/local/contrib/;/usr/;/usr/local" -DBOOST_USE_STATIC=OFF -DHAS_XSERVER=Off ../OpenMS && \
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
