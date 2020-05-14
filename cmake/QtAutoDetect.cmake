#
# Collection of auto detection routines to improve the user experience when
# building Qt from source.
#
# Make sure to not run detection when building standalone tests, because the detection was already
# done when initially configuring qtbase.

function(qt_auto_detect_android)
    if(DEFINED CMAKE_TOOLCHAIN_FILE AND NOT DEFINED QT_AUTODETECT_ANDROID
            AND NOT QT_BUILD_STANDALONE_TESTS)

        file(READ ${CMAKE_TOOLCHAIN_FILE} toolchain_file_content OFFSET 0 LIMIT 80)
        string(FIND ${toolchain_file_content} "The Android Open Source Project" find_result REVERSE)
        if (NOT ${find_result} EQUAL -1)
            set(android_detected TRUE)
        else()
            set(android_detected FALSE)
        endif()

        if(android_detected)
            message(STATUS "Android toolchain file detected, checking configuration defaults...")
            if(NOT DEFINED ANDROID_NATIVE_API_LEVEL)
                message(STATUS "ANDROID_NATIVE_API_LEVEL was not specified, using API level 21 as default")
                set(ANDROID_NATIVE_API_LEVEL 21 CACHE STRING "")
            endif()
            if(NOT DEFINED ANDROID_STL)
                set(ANDROID_STL "c++_shared" CACHE STRING "")
            endif()
        endif()
        set(QT_AUTODETECT_ANDROID ${android_detected} CACHE STRING "")
    elseif (QT_AUTODETECT_ANDROID)
        message(STATUS "Android toolchain file detected")
    endif()
endfunction()

function(qt_auto_detect_vpckg)
    if(DEFINED ENV{VCPKG_ROOT} AND NOT QT_BUILD_STANDALONE_TESTS)
        set(vcpkg_toolchain_file "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake")
        get_filename_component(vcpkg_toolchain_file "${vcpkg_toolchain_file}" ABSOLUTE)

        if(DEFINED CMAKE_TOOLCHAIN_FILE)
            get_filename_component(supplied_toolchain_file "${CMAKE_TOOLCHAIN_FILE}" ABSOLUTE)
            if(NOT supplied_toolchain_file STREQUAL vcpkg_toolchain_file)
                set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${CMAKE_TOOLCHAIN_FILE}" CACHE STRING "")
            endif()
            unset(supplied_toolchain_file)
        endif()
        set(CMAKE_TOOLCHAIN_FILE "${vcpkg_toolchain_file}" CACHE STRING "" FORCE)
        message(STATUS "Using vcpkg from $ENV{VCPKG_ROOT}")
        if(DEFINED ENV{VCPKG_DEFAULT_TRIPLET} AND NOT DEFINED VCPKG_TARGET_TRIPLET)
            set(VCPKG_TARGET_TRIPLET "$ENV{VCPKG_DEFAULT_TRIPLET}" CACHE STRING "")
            message(STATUS "Using vcpkg triplet ${VCPKG_TARGET_TRIPLET}")
        endif()
        unset(vcpkg_toolchain_file)
        message(STATUS "CMAKE_TOOLCHAIN_FILE is: ${CMAKE_TOOLCHAIN_FILE}")
        if(DEFINED VCPKG_CHAINLOAD_TOOLCHAIN_FILE)
            message(STATUS "VCPKG_CHAINLOAD_TOOLCHAIN_FILE is: ${VCPKG_CHAINLOAD_TOOLCHAIN_FILE}")
        endif()
    endif()
endfunction()

function(qt_auto_detect_ios)
    if(CMAKE_SYSTEM_NAME STREQUAL iOS
            OR CMAKE_SYSTEM_NAME STREQUAL watchOS
            OR CMAKE_SYSTEM_NAME STREQUAL tvOS)
        message(STATUS "Using internal CMake ${CMAKE_SYSTEM_NAME} toolchain file.")

        # The QT_UIKIT_SDK check simulates the input.sdk condition for simulator_and_device in
        # configure.json.
        # If the variable is explicitly provided, assume simulator_and_device to be off.
        if(QT_UIKIT_SDK)
            set(simulator_and_device OFF)
        elseif(QT_FORCE_SIMULATOR_AND_DEVICE)
            # TODO: Once we get simulator_and_device support in upstream CMake, only then allow
            # usage of simulator_and_device without forcing.
            set(simulator_and_device ON)
        else()
            # If QT_UIKIT_SDK is not provided, default to simulator.
            set(simulator_and_device OFF)
            set(QT_UIKIT_SDK "iphonesimulator" CACHE "STRING" "Chosen uikit SDK.")
        endif()

        message(STATUS "simulator_and_device set to: \"${simulator_and_device}\".")

        # Choose relevant architectures.
        # Using a non xcode generator requires explicit setting of the
        # architectures, otherwise compilation fails with unknown defines.
        if(CMAKE_SYSTEM_NAME STREQUAL iOS)
            if(simulator_and_device)
                set(osx_architectures "arm64;x86_64")
            elseif(QT_UIKIT_SDK STREQUAL "iphoneos")
                set(osx_architectures "arm64")
            elseif(QT_UIKIT_SDK STREQUAL "iphonesimulator")
                set(osx_architectures "x86_64")
            else()
                if(NOT DEFINED QT_UIKIT_SDK)
                    message(FATAL_ERROR "Please proviude a value for -DQT_UIKIT_SDK."
                        " Possible values: iphoneos, iphonesimulator.")
                else()
                    message(FATAL_ERROR
                            "Unknown SDK argument given to QT_UIKIT_SDK: ${QT_UIKIT_SDK}.")
                endif()
            endif()
        elseif(CMAKE_SYSTEM_NAME STREQUAL tvOS)
            if(simulator_and_device)
                set(osx_architectures "arm64;x86_64")
            elseif(QT_UIKIT_SDK STREQUAL "appletvos")
                set(osx_architectures "arm64")
            elseif(QT_UIKIT_SDK STREQUAL "appletvsimulator")
                set(osx_architectures "x86_64")
            else()
                if(NOT DEFINED QT_UIKIT_SDK)
                    message(FATAL_ERROR "Please proviude a value for -DQT_UIKIT_SDK."
                        " Possible values: appletvos, appletvsimulator.")
                else()
                    message(FATAL_ERROR
                            "Unknown SDK argument given to QT_UIKIT_SDK: ${QT_UIKIT_SDK}.")
                endif()
            endif()
        elseif(CMAKE_SYSTEM_NAME STREQUAL watchOS)
            if(simulator_and_device)
                set(osx_architectures "armv7k;i386")
            elseif(QT_UIKIT_SDK STREQUAL "watchos")
                set(osx_architectures "armv7k")
            elseif(QT_UIKIT_SDK STREQUAL "watchsimulator")
                set(osx_architectures "i386")
            else()
                if(NOT DEFINED QT_UIKIT_SDK)
                    message(FATAL_ERROR "Please proviude a value for -DQT_UIKIT_SDK."
                        " Possible values: watchos, watchsimulator.")
                else()
                    message(FATAL_ERROR
                            "Unknown SDK argument given to QT_UIKIT_SDK: ${QT_UIKIT_SDK}.")
                endif()
            endif()
        endif()

        # For non simulator_and_device builds, we need to explicitly set the SYSROOT aka the sdk
        # value.
        if(QT_UIKIT_SDK)
            set(CMAKE_OSX_SYSROOT "${QT_UIKIT_SDK}" CACHE STRING "")
        endif()
        message(STATUS "CMAKE_OSX_SYSROOT set to: \"${CMAKE_OSX_SYSROOT}\".")

        message(STATUS "CMAKE_OSX_ARCHITECTURES set to: \"${osx_architectures}\".")
        set(CMAKE_OSX_ARCHITECTURES "${osx_architectures}" CACHE STRING "")

        if(NOT DEFINED BUILD_SHARED_LIBS)
            set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build Qt statically or dynamically" FORCE)
        endif()

        if(BUILD_SHARED_LIBS)
            message(FATAL_ERROR
                "Building Qt for ${CMAKE_SYSTEM_NAME} as shared libraries is not supported.")
        endif()

        # Disable qt rpaths for iOS, just like mkspecs/common/uikit.conf does, due to those
        # bundles not being able to use paths outside the app bundle. Not sure this is strictly
        # needed though.
        set(QT_DISABLE_RPATH "OFF" CACHE BOOL "Disable automatic Qt rpath handling." FORCE)
    endif()
endfunction()

function(qt_auto_detect_cmake_config)
    if(CMAKE_CONFIGURATION_TYPES)
        # Allow users to specify this option.
        if(NOT QT_MULTI_CONFIG_FIRST_CONFIG)
            list(GET CMAKE_CONFIGURATION_TYPES 0 first_config_type)
            set(QT_MULTI_CONFIG_FIRST_CONFIG "${first_config_type}")
            set(QT_MULTI_CONFIG_FIRST_CONFIG "${first_config_type}" PARENT_SCOPE)
        endif()

        set(CMAKE_TRY_COMPILE_CONFIGURATION "${QT_MULTI_CONFIG_FIRST_CONFIG}" PARENT_SCOPE)
        if(CMAKE_GENERATOR STREQUAL "Ninja Multi-Config")
            # Create build-<config>.ninja files for all specified configurations.
            set(CMAKE_CROSS_CONFIGS "all" CACHE STRING "")

            # The configuration that will be considered the main one (for example when
            # configuring standalone tests with a single-config generator like Ninja).
            set(CMAKE_DEFAULT_BUILD_TYPE "${QT_MULTI_CONFIG_FIRST_CONFIG}" CACHE STRING "")

            # By default when ninja is called without parameters, it will build all configurations.
            set(CMAKE_DEFAULT_CONFIGS "all" CACHE STRING "")
        endif()
    endif()
endfunction()

function(qt_auto_detect_darwin)
    if(APPLE)
        # If no CMAKE_OSX_DEPLOYMENT_TARGET is provided, default to a value that Qt defines.
        # This replicates the behavior in mkspecs/common/macx.conf where
        # QMAKE_MACOSX_DEPLOYMENT_TARGET is set.
        set(description
            "Minimum OS X version to target for deployment (at runtime); newer APIs weak linked. Set to empty string for default value.")
        if(NOT CMAKE_OSX_DEPLOYMENT_TARGET)
            if(NOT CMAKE_SYSTEM_NAME)
                # macOS
                set(version "10.14")
            elseif(CMAKE_SYSTEM_NAME STREQUAL iOS)
                set(version "12.0")
            elseif(CMAKE_SYSTEM_NAME STREQUAL watchOS)
                set(version "5.0")
            elseif(CMAKE_SYSTEM_NAME STREQUAL tvOS)
                set(version "12.0")
            endif()
            if(version)
                set(CMAKE_OSX_DEPLOYMENT_TARGET "${version}" CACHE STRING "${description}")
            endif()
        endif()
        if(CMAKE_OSX_DEPLOYMENT_TARGET)
            message(STATUS
                "CMAKE_OSX_DEPLOYMENT_TARGET set to: \"${CMAKE_OSX_DEPLOYMENT_TARGET}\".")
        endif()
    endif()
endfunction()

function(qt_auto_detect_pch)
    set(default_value "ON")

    if(CMAKE_OSX_ARCHITECTURES AND CMAKE_VERSION VERSION_LESS 3.18.0 AND NOT QT_FORCE_PCH)
        list(LENGTH CMAKE_OSX_ARCHITECTURES arch_count)
        # CMake versions lower than 3.18 don't support PCH when multiple architectures are set.
        # This is the case for simulator_and_device builds.
        if(arch_count GREATER 1)
            set(default_value "OFF")
            message(WARNING "PCH support disabled due to usage of multiple architectures.")
        endif()
    endif()

    option(BUILD_WITH_PCH "Build Qt using precompiled headers?" "${default_value}")
endfunction()

qt_auto_detect_cmake_config()
qt_auto_detect_darwin()
qt_auto_detect_ios()
qt_auto_detect_android()
qt_auto_detect_vpckg()
qt_auto_detect_pch()
