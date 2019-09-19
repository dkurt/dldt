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

build_ie() {
  mkdir -p build && cd build
  export INF_ENGINE_BUILD=$(readlink -f ./build)

  /usr/local/bin/cmake -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI=x86_64 \
    -DENABLE_VPU=OFF \
    -DTHREADING="TBB" \
    -DTBB_INCLUDE_DIRS=${TBB_ROOT}/include \
    -DTBB_LIBRARIES_RELEASE=${TBB_ROOT}/build/linux_intel64_clang_android_NDKr16b_version_android-21_release/libtbb.so \
    -DTBB_LIBRARIES_DEBUG=${TBB_ROOT}/build/linux_intel64_clang_android_NDKr16b_version_android-21_debug/libtbb_debug.so \
    -DENABLE_GNA=OFF \
    -DENABLE_ALTERNATIVE_TEMP=OFF \
    -DENABLE_SEGMENTATION_TESTS=OFF \
    -DENABLE_OBJECT_DETECTION_TESTS=OFF \
    -DENABLE_OPENCV=ON \
    -DENABLE_CLDNN=OFF \
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
build_tbb

# Build OpenCV (without Inference Engine backend)
build_ocv

# Build Inference Engine (with OpenCV)
# Modify inference-engine/thirdparty/ngraph/src/ngraph/CMakeLists.txt
# - target_link_libraries(ngraph PUBLIC dl pthread)
# + target_link_libraries(ngraph PUBLIC dl)
sed -i -E 's|target_link_libraries\(ngraph PUBLIC dl pthread\)|target_link_libraries\(ngraph PUBLIC dl\)|' thirdparty/ngraph/src/ngraph/CMakeLists.txt
build_ie

# Copy TBB and OpenCV to the bin folder
cp ${TBB_ROOT}/build/linux_intel64_clang_android_NDKr16b_version_android-21_release/libtbb.so ./bin/intel64/Release/lib/
cp ${TBB_ROOT}/build/linux_intel64_clang_android_NDKr16b_version_android-21_release/libtbbmalloc.so ./bin/intel64/Release/lib/
cp ${TBB_ROOT}/build/linux_intel64_clang_android_NDKr16b_version_android-21_release/libc++_shared.so ./bin/intel64/Release/lib/
cp ${OpenCV_DIR}/../libs/x86_64/*.so ./bin/intel64/Release/lib/

# Copy binaries to /data/local
# chmod 777 -R bin
# export LD_LIBRARY_PATH=./bin/intel64/Release/lib
# NOTE: To run samples, use LD_PRELOAD=./bin/intel64/Release/lib/libMKLDNNPlugin.so (TBB linkage issue)

# Known issues: RTTI/Exceptions Not Working Across Library Boundaries
# https://android.googlesource.com/platform/ndk/+/master/docs/user/common_problems.md
