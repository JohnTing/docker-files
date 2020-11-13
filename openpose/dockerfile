# https://hub.docker.com/r/cwaffles/openpose
FROM nvidia/cuda:10.0-cudnn7-devel

#get deps
RUN apt-get update
# Set for all apt-get install, must be at the very beginning of the Dockerfile.
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get install -y python3-dev python3-pip git g++ wget make 
RUN apt-get install -y libprotobuf-dev 
RUN apt-get install -y protobuf-compiler
RUN apt-get install -y libgoogle-glog-dev 

RUN apt-get install -y libcaffe-cuda-dev 
RUN apt-get install -y libhdf5-dev 
RUN apt-get install -y libatlas-base-dev
# http://archive.ubuntu.com/ubuntu/pool/main/m/mesa/libgl1-mesa-dri_20.0.8-0ubuntu1~18.04.1_amd64.deb
RUN apt-get install -y libopencv-dev
# http://security.ubuntu.com/ubuntu/pool/main/i/icu/libicu-dev_60.2-3ubuntu3.1_amd64.deb
RUN apt-get install -y libboost-all-dev 
# Non-interactive modes get set back.
ENV DEBIAN_FRONTEND newt


#for python api
RUN pip3 install numpy opencv-python 

#replace cmake as old version has CUDA variable bugs
RUN wget https://github.com/Kitware/CMake/releases/download/v3.16.0/cmake-3.16.0-Linux-x86_64.tar.gz && \
tar xzf cmake-3.16.0-Linux-x86_64.tar.gz -C /opt && \
rm cmake-3.16.0-Linux-x86_64.tar.gz
ENV PATH="/opt/cmake-3.16.0-Linux-x86_64/bin:${PATH}"

#get openpose
WORKDIR /openpose
RUN git clone https://github.com/CMU-Perceptual-Computing-Lab/openpose.git .

#build it
WORKDIR /openpose/build
RUN cmake -DBUILD_PYTHON=ON .. && make -j `nproc`
WORKDIR /openpose
