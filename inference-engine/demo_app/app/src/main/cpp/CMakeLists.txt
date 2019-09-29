# For more information about using CMake with Android Studio, read the
# documentation: https://d.android.com/studio/projects/add-native-code.html

# Sets the minimum version of CMake required to build the native library.

cmake_minimum_required(VERSION 3.4.1)

#project(ie_demo)
set(TARGET_NAME "native-lib")

if (CMAKE_BUILD_TYPE STREQUAL "")
    message(STATUS "CMAKE_BUILD_TYPE not defined, 'Release' will be used")
    set(CMAKE_BUILD_TYPE "Release")
endif()

add_subdirectory(common/format_reader)

find_package(InferenceEngine 2.0 REQUIRED)

# Creates and names a library, sets it as either STATIC
# or SHARED, and provides the relative paths to its source code.
# You can define multiple libraries, and CMake builds them for you.
# Gradle automatically packages shared libraries with your APK.

add_library( # Sets the name of the library.
             #native-lib
	         ${TARGET_NAME}

             # Sets the library as a shared library.
             SHARED

             # Provides a relative path to your source file(s).
             main.cpp )

# Searches for a specified prebuilt library and stores the path as a
# variable. Because CMake includes system libraries in the search path by
# default, you only need to specify the name of the public NDK library
# you want to add. CMake verifies that the library exists before
# completing its build.

find_library( # Sets the name of the path variable.
              log-lib

              # Specifies the name of the NDK library that
              # you want CMake to locate.
              log )


include_directories (PRIVATE
        ${InferenceEngine_INCLUDE_DIRS}
)

link_directories(PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/lib/)
message(STATUS "-------> ${CMAKE_CURRENT_SOURCE_DIR}/lib/")

target_include_directories(${TARGET_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/common")

# Specifies libraries CMake should link to your target library. You
# can link multiple libraries, such as libraries you define in this
# build script, prebuilt third-party libraries, or system libraries.

target_link_libraries( # Specifies the target library.
	                   # native-lib
	                   ${TARGET_NAME}
					   ${InferenceEngine_LIBRARIES}
					   format_reader
					   IE::ie_cpu_extension
                       # Links the target library to the log library
                       # included in the NDK.
                       ${log-lib} )
