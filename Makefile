.ONESHELL:
.PHONY: deps download build clean

# OpenCV version to use.
OPENCV_VERSION?=4.5.4

# Jetson Nano
ARCH_BIN=5.3

# Go version to use when building Docker image
GOVERSION?=1.14.1

# Temporary directory to put files into.
TMP_DIR?=/tmp/

# Build shared or static library
BUILD_SHARED_LIBS?=ON

# Package list for each well-known Linux distribution
RPMS=cmake curl wget git gtk2-devel libpng-devel libjpeg-devel libtiff-devel tbb tbb-devel libdc1394-devel unzip
DEBS=unzip wget build-essential cmake curl git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev

# Detect Linux distribution
distro_deps=
ifneq ($(shell which dnf 2>/dev/null),)
	distro_deps=deps_fedora
else
ifneq ($(shell which apt-get 2>/dev/null),)
	distro_deps=deps_debian
else
ifneq ($(shell which yum 2>/dev/null),)
	distro_deps=deps_rh_centos
endif
endif
endif

# Install all necessary dependencies.
deps: $(distro_deps)

# Download OpenCV source tarballs.
download:
	rm -rf $(TMP_DIR)opencv
	mkdir $(TMP_DIR)opencv
	cd $(TMP_DIR)opencv
	curl -Lo opencv.zip https://github.com/opencv/opencv/archive/$(OPENCV_VERSION).zip
	unzip -q opencv.zip
	curl -Lo opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/$(OPENCV_VERSION).zip
	unzip -q opencv_contrib.zip
	rm opencv.zip opencv_contrib.zip
	cd -

build:
	cd $(TMP_DIR)opencv/opencv-$(OPENCV_VERSION)
	mkdir build
	cd build
	rm -rf *
	cmake \
		-D CMAKE_BUILD_TYPE=RELEASE \
		-D CMAKE_INSTALL_PREFIX=/usr/local \
		-D BUILD_SHARED_LIBS=${BUILD_SHARED_LIBS} \
		-D OPENCV_EXTRA_MODULES_PATH=$(TMP_DIR)opencv/opencv_contrib-$(OPENCV_VERSION)/modules \
		-D ENABLE_CXX11=ON \
		-D BUILD_DOCS=OFF \
		-D BUILD_EXAMPLES=OFF \
		-D BUILD_opencv_world=OFF \
		-D BUILD_TESTS=OFF \
		-D BUILD_PERF_TESTS=OFF \
		-D BUILD_opencv_java=OFF \
		-D BUILD_opencv_python=OFF \
		-D BUILD_opencv_python2=OFF \
		-D BUILD_opencv_python3=OFF \
		-D INSTALL_CREATE_DISTRIB=ON \
		-D WITH_JASPER=OFF \
		-D OPENCV_GENERATE_PKGCONFIG=ON \
		-D WITH_CUDA=OFF \
		-D CUDA_ARCH_BIN=${ARCH_BIN} \
		-D ENABLE_FAST_MATH=ON \
		-D WITH_V4L=ON \
		-D WITH_LIBV4L=OFF\
		-D WITH_GSTREAMER=ON \
		-D WITH_GSTREAMER_0_10=OFF \
		-D WITH_QT=OFF \
		-D WITH_EIGEN=OFF \
		-D WITH_OPENGL=OFF \
		-D BUILD_OPENCV_PYTHON3=OFF \
		-D ENABLE_NEON=OFF \
		-D CPACK_BINARY_DEB=ON \
		-D OPENCV_SKIP_PYTHON_LOADER=ON \
		..
		#-D PYTHON3_PACKAGES_PATH="/usr/local/lib/python3.6/dist-packages" \
		#-D OPENCV_PYTHON3_INSTALL_PATH="/usr/local/lib/python3.6/dist-packages" \
		#-D PYTHON3_EXECUTABLE=`which python3.6` \
		#-D PYTHON3_INCLUDE_DIR=`python3.6 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())"` \
		#-D PYTHON3_PACKAGES_PATH=`python3.6 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())"` \
		#-D PYTHON3_NUMPY_INCLUDE_DIRS=/usr/local/lib/python3.6/dist-packages/numpy/core/include \
		#-D PYTHON3_LIBRARY=/usr/lib/aarch64-linux-gnu/libpython3.6.so.1.0
	$(MAKE) -j $(shell nproc --all)
	#$(MAKE) package -j $(shell nproc --all)
	#cpack -V
	$(MAKE) preinstall
	cd -

clean:
	go clean --cache
	rm -rf $(TMP_DIR)opencv

# Install system wide.
sudo_install:
	cd $(TMP_DIR)opencv/opencv-$(OPENCV_VERSION)/build
	sudo $(MAKE) install
	sudo ldconfig
	cd -

deps_debian:
	sudo apt-get -y update
	sudo apt-get -y install $(DEBS)

#python3 ./modules/python/src2/gen2.py ./build/modules/python_bindings_generator ./build/modules/python_bindings_generator/headers.txt

# cpack fix
# https://askubuntu.com/questions/1143060/opencv-compiles-correctly-but-fails-during-deb-packaging
#
# sudo find /usr -name "*opencv*" -exec sudo rm -rf {} \;
# sudo find / -name "*opencv*" -exec sudo readlink {} \;
# sudo apt-get purge '*opencv*'
# sudo -H pip3 uninstall opencv-python
# python3 ./build/python_loader/setup.py bdist_wheel
# python3 setup.py bdist_wheel
# /bin:/usr/include/opencv4
# CPLUS_INCLUDE_PATH=${CPLUS_INCLUDE_PATH}:/usr/include/opencv4
# #include <opencv2/xfeatures2d/nonfree.hpp>
# pip3 download --no-deps opencv-python==4.3.0.38
