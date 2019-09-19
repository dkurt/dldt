# Build TBB
# Android NDK, Revision 16b
# export NDK_ROOT=/home/dkurt/Downloads/android-ndk-r16b/
# ~/Downloads/android-ndk-r16b/ndk-build target=android arch=intel64 compiler=clang -j8 tbb tbbmalloc

# Build Inference Engine
# Modify inference-engine/thirdparty/ngraph/src/ngraph/CMakeLists.txt
# - target_link_libraries(ngraph PUBLIC dl pthread)
# + target_link_libraries(ngraph PUBLIC dl)

export ANDROID_NDK=/home/dkurt/Downloads/android-ndk-r20
export OpenCV_DIR=/home/dkurt/opencv_install/sdk/native/jni/

# Build OpenCV
# /usr/local/bin/cmake -DCMAKE_BUILD_TYPE=Release \
#   -DCMAKE_INSTALL_PREFIX=~/opencv_install \
#   -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake \
#   -DBUILD_EXAMPLES=OFF \
#   -DBUILD_ANDROID_EXAMPLES=OFF \
#   -DBUILD_ANDROID_PROJECTS=OFF \
#   -DANDROID_ABI=x86_64 \
#   -DBUILD_TESTS=OFF \
#   -DBUILD_PERF_TESTS=OFF \
#   -DBUILD_SHARED_LIBS=ON \
#   -DBUILD_LIST=core,imgcodecs,videoio,imgproc ..

# Build Inference Engine
/usr/local/bin/cmake -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=x86_64 \
  -DENABLE_VPU=OFF \
  -DTHREADING="TBB" \
  -DTBB_INCLUDE_DIRS=~/tbb/include \
  -DTBB_LIBRARIES_RELEASE=/home/dkurt/tbb/build/linux_intel64_clang_android_NDKr16b_version_android-21_release/libtbb.so \
  -DTBB_LIBRARIES_DEBUG=/home/dkurt/tbb/build/linux_intel64_clang_android_NDKr16b_version_android-21_debug/libtbb_debug.so \
  -DENABLE_GNA=OFF \
  -DENABLE_DLIA=OFF \
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
  .. && make -j8

cp /home/dkurt/tbb/build/linux_intel64_clang_android_NDKr16b_version_android-21_release/libtbb.so ../bin/intel64/Release/lib/
cp /home/dkurt/tbb/build/linux_intel64_clang_android_NDKr16b_version_android-21_release/libtbbmalloc.so ../bin/intel64/Release/lib/
cp /home/dkurt/tbb/build/linux_intel64_clang_android_NDKr16b_version_android-21_release/libc++_shared.so ../bin/intel64/Release/lib/
cp ${OpenCV_DIR}/../libs/x86_64/*.so ../bin/intel64/Release/lib/

  # -DANDROID_STL="c++_shared" \
  # -DCMAKE_SHARED_LINKER_FLAGS="-Wl,-E" \
  # -DANDROID_LINKER_FLAGS="-Wl,-E" \
  # -DANDROID_STL_FORCE_FEATURES=ON \


# Copy to /data/local
# chmod 777 -R bin
# export LD_LIBRARY_PATH=./bin/intel64/Release/lib
# NOTE: To run samples, use LD_PRELOAD=./bin/intel64/Release/lib/libMKLDNNPlugin.so (TBB linkage issue)


# https://android.googlesource.com/platform/ndk/+/master/docs/user/common_problems.md
# RTTI/Exceptions Not Working Across Library Boundaries
