export ANDROID_NDK=/home/dkurt/Downloads/android-ndk-r20
export ANDROID_SDK=/home/dkurt/Android/Sdk/
export ANDROID_HOME=/home/dkurt/Android/Sdk/

/usr/local/bin/cmake -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=x86_64 \
  -DENABLE_VPU=OFF \
  -DTHREADING="SEQ" \
  -DENABLE_GNA=OFF \
  -DENABLE_DLIA=OFF \
  -DENABLE_ALTERNATIVE_TEMP=OFF \
  -DENABLE_SEGMENTATION_TESTS=OFF \
  -DENABLE_OBJECT_DETECTION_TESTS=OFF \
  -DENABLE_OPENCV=OFF \
  -DENABLE_CLDNN=OFF \
  -DENABLE_TESTS=OFF \
  -DENABLE_SAMPLES=ON \
  -DGEMM=JIT \
  -DENABLE_CPPLINT=OFF \
  -DCMAKE_CXX_FLAGS="-Wno-defaulted-function-deleted" \
  .. && make -j8

  # -DANDROID_STL="c++_shared" \
  # -DCMAKE_SHARED_LINKER_FLAGS="-Wl,-E" \
  # -DANDROID_LINKER_FLAGS="-Wl,-E" \
  # -DANDROID_STL_FORCE_FEATURES=ON \



# Comment inference-engine/samples/CMakeLists.txt
# target_link_libraries(${IE_SAMPLE_NAME} PRIVATE pthread)

# Copy to /data/local
# chmod 777 -R bin
# export LD_LIBRARY_PATH=./bin/intel64/Release/lib


# https://android.googlesource.com/platform/ndk/+/master/docs/user/common_problems.md
# RTTI/Exceptions Not Working Across Library Boundaries
