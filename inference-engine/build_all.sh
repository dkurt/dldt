#!/bin/bash

NUM_THREADS=8

build_tbb() {
  # Download Android NDK 16b
  if [ ! -d android-ndk-r16b ]; then
    wget https://dl.google.com/android/repository/android-ndk-r16b-linux-x86_64.zip
    unzip android-ndk-r16b-linux-x86_64.zip
    rm android-ndk-r16b-linux-x86_64.zip
  fi

  # Build TBB
  if [ ! -d tbb ]; then
    git clone https://github.com/intel/tbb/ --depth 1
    cd tbb
    export NDK_ROOT=../android-ndk-r16b/
    ../android-ndk-r16b/ndk-build target=android arch=intel64 compiler=clang -j${NUM_THREADS} tbb tbbmalloc
    cd ..
  fi

  export TBB_ROOT=$(readlink -f ./tbb)
}

build_libusb() {
  if [ ! -d libusb ]; then
    git clone https://github.com/libusb/libusb/
    curr_dir=$(pwd)
    cd libusb/android/jni/
    git checkout 0034b2a
    ${ANDROID_NDK}/build/ndk-build
    cd ${curr_dir}
  fi

  export LIBUSB_ROOT=$(readlink -f ./libusb)
  export LIBUSB_LIBRARY=${LIBUSB_ROOT}/android/libs/armeabi-v7a/libusb1.0.so
}

build_ie() {
  mkdir -p build && cd build
  export INF_ENGINE_BUILD=$(readlink -f ./build)

  /usr/local/bin/cmake -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI="armeabi-v7a with NEON" \
    -DANDROID_PLATFORM=21 \
    -DENABLE_VPU=ON \
    -DTHREADING="SEQ" \
    -DLIBUSB_INCLUDE_DIR=${LIBUSB_ROOT}/libusb \
    -DLIBUSB_LIBRARY=${LIBUSB_LIBRARY} \
    -DENABLE_GNA=OFF \
    -DENABLE_ALTERNATIVE_TEMP=OFF \
    -DENABLE_SEGMENTATION_TESTS=OFF \
    -DENABLE_OBJECT_DETECTION_TESTS=OFF \
    -DENABLE_OPENCV=OFF \
    -DENABLE_CLDNN=OFF \
    -DENABLE_MKLDNN=OFF \
    -DENABLE_SSE42=OFF \
    -DENABLE_TESTS=OFF \
    -DENABLE_SAMPLES=ON \
    -DGEMM=JIT \
    -DENABLE_CPPLINT=OFF \
    -DCMAKE_CXX_FLAGS="-Wno-defaulted-function-deleted" \
    .. && make -j${NUM_THREADS}

  cd ..
}

build_ocv() {
  # Download OpenCV
  if [ ! -d opencv ]; then
    git clone https://github.com/opencv/opencv --depth 1
  fi

  if [ ! -d opencv_install ]; then
    mkdir -p opencv_build && cd opencv_build

    export ANDROID_HOME=${ANDROID_SDK}

    /usr/local/bin/cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=../opencv_install \
      -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake \
      -DANDROID_SDK=${ANDROID_SDK} \
      -DBUILD_EXAMPLES=OFF \
      -DBUILD_ANDROID_EXAMPLES=OFF \
      -DANDROID_ABI=x86_64 \
      -DBUILD_TESTS=OFF \
      -DBUILD_PERF_TESTS=OFF \
      -DBUILD_SHARED_LIBS=ON \
      -DBUILD_LIST=java,core,imgcodecs,videoio,imgproc ../opencv && \
      make -j${NUM_THREADS} && make install

    cd ..
  fi

  export OpenCV_DIR=$(readlink -f ./opencv_install/sdk/native/jni/)
}

# Download Android SDK and NDK 20
if [ ! -d android-sdk ]; then
  wget https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip
  mkdir android-sdk
  unzip sdk-tools-linux-4333796.zip -d android-sdk
  rm sdk-tools-linux-4333796.zip
  echo y | ./android-sdk/tools/bin/sdkmanager "ndk-bundle" "build-tools;29.0.2" --proxy_host="proxy-chain.intel.com" --proxy_port=911 --proxy=http
fi

export ANDROID_SDK=$(readlink -f ./android-sdk)
export ANDROID_NDK="${ANDROID_SDK}/ndk-bundle"

# Build TBB
# build_tbb

build_libusb

# Build OpenCV (without Inference Engine backend)
# build_ocv

# Build Inference Engine (with OpenCV)
# Modify inference-engine/thirdparty/ngraph/src/ngraph/CMakeLists.txt
# - target_link_libraries(ngraph PUBLIC dl pthread)
# + target_link_libraries(ngraph PUBLIC dl)
sed -i -E 's|target_link_libraries\(ngraph PUBLIC dl pthread\)|target_link_libraries\(ngraph PUBLIC dl\)|' thirdparty/ngraph/src/ngraph/CMakeLists.txt
build_ie

# Copy TBB and OpenCV to the bin folder
# cp ${TBB_ROOT}/build/linux_intel64_clang_android_NDKr16b_version_android-21_release/libtbb.so ./bin/intel64/Release/lib/
# cp ${TBB_ROOT}/build/linux_intel64_clang_android_NDKr16b_version_android-21_release/libtbbmalloc.so ./bin/intel64/Release/lib/
# cp ${TBB_ROOT}/build/linux_intel64_clang_android_NDKr16b_version_android-21_release/libc++_shared.so ./bin/intel64/Release/lib/
# cp ${LIBUSB_LIBRARY} ./bin/intel64/Release/lib/
# cp ${OpenCV_DIR}/../libs/x86_64/*.so ./bin/intel64/Release/lib/

# Copy binaries to /data/local
# chmod 777 -R bin
# export LD_LIBRARY_PATH=./bin/intel64/Release/lib
# NOTE: To run samples, use LD_PRELOAD=./bin/intel64/Release/lib/libMKLDNNPlugin.so (TBB linkage issue)

# Known issues: RTTI/Exceptions Not Working Across Library Boundaries
# https://android.googlesource.com/platform/ndk/+/master/docs/user/common_problems.md


#
# Test GPU plugin with Intel Celadon
#
# 1. Build Celadon with OpenCL support =========================================
#
# source: https://01.org/projectceladon/documentation/getting_started/build-source
#
# mkdir -p ~/bin
# curl https://storage.googleapis.com/git-repo-downloads/repo >  ~/bin/repo
# chmod a+x ~/bin/repo
# export PATH=~/bin:$PATH
#
# mkdir celadon
# cd celadon
# repo init -u https://github.com/projectceladon/manifest.git
# repo init -u https://github.com/projectceladon/manifest -b celadon/p/mr0/master -m default.xml

# Open file .repo/manifests/include/bsp-celadon.xml
# Find "libva" dependency and replace location from
# "vendor/intel/external/project-celadon/libva"
# to
# "hardware/intel/external/libva"

# Find "gmmlib" and replace revision from "celadon/p/mr0/master" to "master"

# Add dependencies for OpenCL runtime (https://github.com/projectceladon/manifest/pull/68)
# <project name="compute-runtime" path="hardware/intel/external/opencl/compute-runtime" remote="github" revision="master"/>
# <project name="intel-graphics-compiler" path="hardware/intel/external/opencl/intel-graphics-compiler" remote="github" revision="master"/>
# <project name="OpenCL-ICD-Loader" path="hardware/intel/external/opencl/opencl-icd-loader" remote="github" revision="master"/>

# Start build (https://github.com/projectceladon/manifest/wiki):
# repo sync -j8
# source build/envsetup.sh

# Remove libva patches:
# rm ./vendor/intel/utils/android_p/google_diff/cel_apl/vendor/intel/external/project-celadon/libva/0001-use-the-private-drm-lib-name.patch
# rm ./vendor/intel/utils/android_p/google_diff/celadon/vendor/intel/external/project-celadon/libva/0001-use-the-private-drm-lib-name.patch
# rm ./vendor/intel/utils/android_p/google_diff/clk/vendor/intel/external/project-celadon/libva/0001-use-the-private-drm-lib-name.patch
# rm ./vendor/intel/utils/android_p/google_diff/cel_kbl/vendor/intel/external/project-celadon/libva/0001-use-the-private-drm-lib-name.patch

# lunch celadon-userdebug
# make project_celadon-efi SPARSE_IMG=true -j8

# Install Celadon to the device
#
# Patch libOpenCL.so: celadon_root/out/target/product/celadon/system/lib64/libOpenCL.so:
# patchelf --set-soname libOpenCL.so.1 libOpenCL.so
# mv libOpenCL.so libOpenCL.so.1
# Copy libOpenCL.so.1 nearby Inference Engine libaries: bin/intel64/Release/lib

# Patch libgmm_umd.so: celadon_root/out/target/product/celadon/vendor/lib64/libgmm_umd.so
# patchelf --set-soname libigdgmm.so.9 libgmm_umd.so
# mv libgmm_umd.so libigdgmm.so.9
# Copy libigdgmm.so.9 nearby Inference Engine libaries: bin/intel64/Release/lib
