# This makes sure that you are not running on an outdated, untested
# version of CMake.
cmake_minimum_required( VERSION 3.8.0 FATAL_ERROR )

if ( "${CTEST_SCRIPT_ARG}" STREQUAL "" )
    message( FATAL_ERROR "Usage: ctest -S ${CTEST_SCRIPT_NAME},[Experimental|Continuous|Nightly|(BuildType)]" )
endif()

# This file contains the settings for the CDash server for interactive,
# non-scripted calls to CMake ("make Experimental"). Instead of dublicating
# the settings, we import that file.

include( ${CTEST_SCRIPT_DIRECTORY}/CTestConfig.cmake )

if ( "${CTEST_SCRIPT_ARG}" STREQUAL "Release" )
    # For "Release" builds, we use the version number as install suffix
    # (so a subsequent "make install" will Do The Right Thing (tm)).
    # We need to read the version number from CMakeLists.txt.
    file( READ "${CTEST_SCRIPT_DIRECTORY}/CMakeLists.txt" _CMAKE_LISTS )
    string( REGEX REPLACE ".*JAWS_VERSION_MAJOR +\"([0-9]+)\".*JAWS_VERSION_MINOR +\"([0-9]+)\".*" "\\1.\\2" JAWS_INSTALL_SUFFIX "${_CMAKE_LISTS}" )
    # Obviously you want the Release build to be of Release BuildType.
    # But you usually don't want to run the test suite (which is running
    # on each Continuous / Nightly build anyway).
    set( CTEST_BUILD_CONFIGURATION "Release" )
    set( JAWS_TEST_AND_SUBMIT false )
elseif ( ( "${CTEST_SCRIPT_ARG}" STREQUAL "Experimental" )  OR ( "${CTEST_SCRIPT_ARG}" STREQUAL "Continuous" ) OR ( "${CTEST_SCRIPT_ARG}" STREQUAL "Nightly" ) )
    # This can be set to Debug or even Trace as well, but for the automated
    # testing you are usually not interested in debug symbols or trace logs
    set( CTEST_BUILD_CONFIGURATION "Release" )
    set( JAWS_TEST_AND_SUBMIT true )
    set( JAWS_INSTALL_SUFFIX "${CTEST_SCRIPT_ARG}" )
else()
    # This allows to run Debug, Trace, DebugTrace or any other BuildType.
    set( CTEST_BUILD_CONFIGURATION "${CTEST_SCRIPT_ARG}" )
    set( JAWS_TEST_AND_SUBMIT false )
    set( JAWS_INSTALL_SUFFIX "${CTEST_SCRIPT_ARG}" )
endif()

# Assuming that:
# - the script is located in the root directory of the project;
# - the project is already checked out in the appropriate location;
# - that for each <project> source tree there is a directory named
#   build/<project>-<mode> for the binaries.

set( CTEST_SOURCE_DIRECTORY ${CTEST_SCRIPT_DIRECTORY} )
set( CTEST_BINARY_DIRECTORY ${CTEST_SCRIPT_DIRECTORY}/../build/${CTEST_PROJECT_NAME}-${JAWS_INSTALL_SUFFIX} )

# Forcing output of called tools to English as CTest cannot parse
# other locales (e.g. Subversion output, or distinguishing between
# compiler warnings and errors).

set( ENV{LANG} "C" )

# The default is to cut off after 50 warnings. There are cases where
# you would like to increase this number.

#set( CTEST_CUSTOM_MAXIMUM_NUMBER_OF_WARNINGS 50 )

# Setting CTEST_SITE to the output of $(hostname). Strangely enough,
# the environment variable ${HOSTNAME} does not work everywhere.

execute_process( COMMAND hostname
                 OUTPUT_VARIABLE CTEST_SITE
                 OUTPUT_STRIP_TRAILING_WHITESPACE )

# Platform-specific settings

# This function will check a list of directories (passed as parameter 2..n)
# for existence, and set the variable named in target_var to the first dir
# from the list that actually exists.
# Since the function only ever sets the target variable if it was UNSET to
# begin with, you can override the hardcoded list of directories and set a
# directory manually (e.g. for debugging).
function( select_dir target_var )
    foreach( DIR IN LISTS ARGN )
        if ( NOT ${target_var}_FOUND )
            if ( EXISTS ${DIR} )
                set( ${target_var} ${DIR} PARENT_SCOPE )
                set( ${target_var}_FOUND 1 )
            endif()
        endif()
    endforeach()
endfunction()

# TARGET_DIR parameterized this way, should you want to use custom
# directories (e.g. ~/.local or D:/Software).
if ( WIN32 )
    select_dir( TARGET_DIR $ENV{ProgramFiles} )
else()
    select_dir( TARGET_DIR /opt )
endif()

# Again, parameterized should you want to use custom builds. If these
# custom directories (or directories set by the CTest command line) do
# not exist, system directories are searched anyway.
select_dir( BOOST_ROOT   "${TARGET_DIR}/boost" )
select_dir( ICU_ROOT     "${TARGET_DIR}/icu;${TARGET_DIR}/icu/include" )

if ( WIN32 )
    set( CTEST_CMAKE_GENERATOR "NMake Makefiles" )
    # Additions to CMAKE_PREFIX_PATH required for Windows
    set( PLATFORM_OPTIONS "" )
    # You might have to extend the PATH to find the DLLs
    set( ENV{PATH} "$ENV{PATH};${ICU_ROOT}/bin;${BOOST_ROOT}/lib" )
else()
    set( CTEST_CMAKE_GENERATOR "Unix Makefiles" )
    # No additions to CMAKE_PREFIX_PATH required for Unix
    set( PLATFORM_OPTIONS "" )
    # Coverage and memory check only supported for Unix
    # and taking too much time really to do on anything
    # other than Nightly.
    if ( "${CTEST_SCRIPT_ARG}" STREQUAL "Nightly" )
        find_program( CTEST_COVERAGE_COMMAND gcov )
        find_program( CTEST_MEMORYCHECK_COMMAND valgrind )
        set( CTEST_MEMORYCHECK_COMMAND_OPTIONS "-q --tool=memcheck --leak-check=yes --workaround-gcc296-bugs=yes --num-callers=50" )
        set( JAWS_WITH_COV_AND_MEM "-DJAWS_WITH_COV_AND_MEM=ON" )
    endif()
endif()

# Build name is what appears on CDash (e.g. "Linux-x86_64").

set( CTEST_BUILD_NAME "${CMAKE_SYSTEM_NAME}" )

# If your tests trip a timeout, you can expand it. The value is in seconds.
#set( CTEST_TEST_TIMEOUT 900 )

# Assuming that "ctest", "cmake" and "svn" are in the command PATH.

find_program( CTEST_COMMAND ctest )
if ( ${CTEST_COMMAND} STREQUAL "CTEST_COMMAND-NOTFOUND" )
    message( FATAL_ERROR "** No CTest executable found in PATH." )
endif()
find_program( CMAKE_COMMAND cmake )
if ( ${CMAKE_COMMAND} STREQUAL "CMAKE_COMMAND-NOTFOUND" )
    message( FATAL_ERROR "** No CMake executable found in PATH." )
endif()
if ( EXISTS .svn )
    find_program( CTEST_SVN_COMMAND svn )
    if ( ${CTEST_SVN_COMMAND} STREQUAL "CTEST_SVN_COMMAND-NOTFOUND" )
        message( FATAL_ERROR "** No SVN executable found in PATH." )
    endif()
elseif ( EXISTS .git )
    find_program( CTEST_GIT_COMMAND git )
    if ( ${CTEST_GIT_COMMAND} STREQUAL "CTEST_GIT_COMMAND-NOTFOUND" )
        message( FATAL_ERROR "** No GIT executable found in PATH." )
    endif()
else()
    message( "++ Source directory found to be neither SVN nor GIT working directory." )
endif()

# Piecing together the configuration command line. Preferring this over
# alternative approaches (like the OPTIONS parameter to ctest_configure())
# for documentation purposes: This is how you would build this project
# interactively as well.

set( CTEST_CONFIGURE_COMMAND "\"${CMAKE_COMMAND}\" \
     -DCMAKE_BUILD_TYPE=${CTEST_BUILD_CONFIGURATION} \
     ${PLATFORM_OPTIONS} \
     -DICU_ROOT=${ICU_ROOT} \
     -DBOOST_ROOT=${BOOST_ROOT} \
     -DCMAKE_INSTALL_PREFIX=${TARGET_DIR}/${CTEST_PROJECT_NAME}-${JAWS_INSTALL_SUFFIX} \
     ${JAWS_WITH_COV_AND_MEM} \
     -G \"${CTEST_CMAKE_GENERATOR}\" \
     ${CTEST_SOURCE_DIRECTORY}" )

#message( STATUS "${CTEST_CONFIGURE_COMMAND}" )

# In case you need special proxy settings, these can be configured here.
# Better, of course, to have the correct values set globally.

#set( ENV{http_proxy} "" )
#set( ENV{HTTP_PROXY} "" )

# Actual processing.

# ctest_empty_binary_directory() sometimes gives (inconsequential)
# warning messages ("problem removing the binary directory").
# file( REMOVE_RECURSE ... ) does not, for whatever reason.
file( REMOVE_RECURSE ${CTEST_BINARY_DIRECTORY} )
#ctest_empty_binary_directory( ${CTEST_BINARY_DIRECTORY} )

ctest_start( ${JAWS_INSTALL_SUFFIX} )

ctest_update( RETURN_VALUE UPDATED )

if ( ( NOT ${CTEST_SCRIPT_ARG} STREQUAL "Continuous" ) OR ( UPDATED GREATER 0 ) )

    ctest_configure()

    ctest_build()

    if ( JAWS_TEST_AND_SUBMIT )

        ctest_test()

        if ( CTEST_COVERAGE_COMMAND )
            ctest_coverage()
        endif()

        if( CTEST_MEMORYCHECK_COMMAND )
            ctest_memcheck()
        endif()

        ctest_submit()

    endif()

endif()
