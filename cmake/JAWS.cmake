# This is the JAWS module, part of the JAWS C++ project framework from
# http://jaws.rootdirectory.de.
#
# Provided under Creative Commons CC0 (Public Domain Dedication)
# https://creativecommons.org/publicdomain/zero/1.0/deed.en

###########################################################################
# General Settings
###########################################################################

if ( CMAKE_SIZEOF_VOID_P EQUAL 8 )
    set( JAWS_LIBEXT "64" )
else()
    set( JAWS_LIBEXT "" )
endif()

# Includes in the form of <project>/<unit>/<header>.hpp make it absolutely
# clear where headers come from. (Compare Boost includes.)
include_directories( ${CMAKE_SOURCE_DIR} )
include_directories( ${CMAKE_BINARY_DIR} )

set_property( GLOBAL PROPERTY USE_FOLDERS ON )

# Make Debug the default build type. For one, even the CMake docs are
# somewhat unclear as to the differences or similarities of the default
# (empty) and the Release build type. Second, during development the Debug
# build is the common default, especially since it allows coverage and
# memory testing. Since you *usually* build Debug much more often than you
# build Release, it should be the default.
if ( NOT CMAKE_BUILD_TYPE )
    message( "++ CMAKE_BUILD_TYPE not set. Defaulting to 'Debug'." )
    set( CMAKE_BUILD_TYPE Debug )
endif()

# The following file can hold "suppressions", definitions of Valgrind
# messages that should not be reported as errors. Check:
# http://www.valgrind.org/docs/manual/manual-core.html#manual-core.suppress
#set( MEMORYCHECK_SUPPRESSIONS_FILE "${CMAKE_SOURCE_DIR}/cmake/MemoryCheck.supp" CACHE INTERNAL "List of suppressed Valgrind messages." )

# Build test targets
include( CTest )
mark_as_advanced( BUILD_TESTING )

# Example for platform-dependent variable settings. Summary of the most
# useful flags:
# - WIN32  - True for Windows targets, including Win64, but not on Cygwin
# - APPLE  - True on Mac OS
# - UNIX   - True on Unix-like targets, including Mac OS and Cygwin
# - CYGWIN - True on Cygwin
# Or, seen from the other way:
# - defined on Windows: WIN32
# - defined on Linux:   UNIX
# - defined on Mac OS:  UNIX and APPLE
# - defined on Cygwin:  UNIX and CYGWIN

set( JAWS_CONFIGFILE "~/.config/${CMAKE_PROJECT_NAME}/${CMAKE_PROJECT_NAME}.cfg" )
if ( WIN32 )
    set( JAWS_CONFIGFILE "%APPDATA%/${CMAKE_PROJECT_NAME}/${CMAKE_PROJECT_NAME}.cfg" )
endif ( WIN32 )
if ( APPLE )
    set( JAWS_CONFIGFILE "~/Library/Application Support/${CMAKE_PROJECT_NAME}/${CMAKE_PROJECT_NAME}.cfg" )
endif ( APPLE )

###########################################################################
# Functions
###########################################################################

# Removing the extension of a filename.
function( remove_extension FILENAME )
    get_filename_component( EXTENSION "${${FILENAME}}" EXT )
    string( REGEX REPLACE "${EXTENSION}$" "" TRIMMED_FN ${${FILENAME}} )
    set( ${FILENAME} ${TRIMMED_FN} PARENT_SCOPE )
endfunction()

# 1) Prefixing all filenames in a given list with a given string,
# 2) Prefixing *that* with CMAKE_BINARY_DIR if the filename is in the list
#    of files that got variable replacement (as those reside there).
function( prefix_filenames FILELIST PREFIX )
    set( LOCAL_LIST "${${FILELIST}}" )
    list( LENGTH LOCAL_LIST COUNT )
    set( INDEX 0 )
    while ( INDEX LESS COUNT )
        # Get the filename out of the list
        list( GET LOCAL_LIST ${INDEX} FILENAME )
        list( REMOVE_AT LOCAL_LIST ${INDEX} )
        # Do the prefixing
        set( FILENAME "${PREFIX}/${FILENAME}" )
        # Check if it is a variable replacement file
        list( FIND JAWS_configure_files ${FILENAME} FOUND )
        if ( NOT FOUND EQUAL -1 )
            # Prefix it with CMAKE_BINARY_DIR if it is
            set( FILENAME "${CMAKE_BINARY_DIR}/${FILENAME}" )
        endif()
        # Re-insert the modified filename into the list
        list( INSERT LOCAL_LIST INDEX "${FILENAME}" )
        math( EXPR INDEX "${INDEX} + 1" )
    endwhile()
    # Forward changes to the caller
    set( ${FILELIST} ${LOCAL_LIST} PARENT_SCOPE )
endfunction()

# Generating the .h file from a given Java JNI interface via 'javah'.
function( javah JNIFILE )
    get_filename_component( UNIT ${JNIFILE} DIRECTORY )
    get_filename_component( CLASS ${JNIFILE} NAME_WE )
    get_target_property( JAWS_CLASS_DIR ${UNIT} CLASSDIR )
    add_custom_command( OUTPUT ${UNIT}/${CLASS}.h COMMAND ${Java_JAVAH_EXECUTABLE} -classpath ${JAWS_CLASS_DIR} -o ${UNIT}/${CLASS}.h MyProject.jniexample.${CLASS} )
endfunction()

###########################################################################
# Configure
###########################################################################

set( JAWS_DOC_DIR "share/doc/${CMAKE_PROJECT_NAME}" )
set( JAWS_DATA_DIR "share/${CMAKE_PROJECT_NAME}" )

# Used for configure of tools/check.cpp.
find_program( ASTYLE astyle )
mark_as_advanced( ASTYLE )

# To avoid formatting back and forth due to different versions of AStyle
# being employed, we check for the installed version and deny formatting
# with other versions than the specified one.
if ( ASTYLE )
    execute_process( COMMAND ${ASTYLE} --version ERROR_VARIABLE ASTYLE_VERSION_STRING OUTPUT_VARIABLE ASTYLE_VERSION_STRING ERROR_STRIP_TRAILING_WHITESPACE OUTPUT_STRIP_TRAILING_WHITESPACE )
    string( REGEX REPLACE "^Artistic Style Version ([0-9]\.[0-9]*).*" "\\1" ASTYLE_VERSION "${ASTYLE_VERSION_STRING}" )
    if ( NOT ${ASTYLE_VERSION} STREQUAL "2.05" )
        message( WARNING "AStyle version 2.05 expected, but found ${ASTYLE_VERSION}. Will not run code beautifier." )
        set( ASTYLE "ASTYLE-NOTFOUND" )
    endif()
endif()

# Looping through the files that need variable replacement.
foreach ( file ${JAWS_configure_files} )
    configure_file( "${file}.in" "${file}" @ONLY )
endforeach()

###########################################################################
# Documentation
###########################################################################

add_custom_target( docs )

find_package( Doxygen )
if ( DOXYGEN_FOUND AND DOXYGEN_DOT_FOUND )
    configure_file( docs/Doxyfile.in docs/Doxyfile @ONLY )
    # Usually source documentation is for developer use only. As Doxygen is
    # quite talkative during its run (and needs to be), and needs to do a
    # full run every time it is invoked, it is NOT included in the "all"
    # target. You need to trigger the "doxygen" target manually. Should you
    # wish to change this, add "ALL" after "doxygen" in the following line.
    add_custom_target( doxygen
                       ${DOXYGEN_EXECUTABLE}
                       ${CMAKE_BINARY_DIR}/docs/Doxyfile
                       WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                       VERBATIM
                       SOURCES docs/Doxyfile.in
                     )
    add_dependencies( docs doxygen )
    # By default, Doxygen documentation is not installed / shipped. Should
    # you wish to change this, uncomment the next line, and add the "ALL"
    # to the custom command above.
    #install( DIRECTORY ${CMAKE_BINARY_DIR}/docs/doxygen/html/ DESTINATION ${JAWS_DOC_DIR}/doxygen )
else()
    message( "++ Doxygen not found. Will not be able to build API documentation." )
    message( "++ Doxygen is available from http://www.doxygen.org." )
    message( "++ If you *have* Doxygen installed, add its path to -DCMAKE_PREFIX_PATH." )
endif()

if ( JAWS_latex_documents OR JAWS_latex_documents_NOINSTALL )
    find_package( LATEX )
    if ( LATEX_COMPILER AND DVIPS_CONVERTER AND PS2PDF_CONVERTER )
        set( LATEX_OUTPUT_PATH ${CMAKE_BINARY_DIR}/docs )
        include( UseLATEX )
        foreach( file ${JAWS_latex_documents} ${JAWS_latex_documents_NOINSTALL} )
            add_latex_document( docs/${file}.tex
                                IMAGE_DIRS docs/images
                                INPUTS docs/_Preamble.tex
                                FORCE_PDF
                              )
        endforeach()
        # SOURCES here does NOT automatically include subdocuments added by
        # \include or \input in the LaTeX sources. These need to be added to
        # INPUTS above.
        add_dependencies( docs pdf )
    else()
        message( "++ No LaTeX installation found. Will not be able to build manuals." )
        message( "++ LaTeX installations are available e.g. from http://www.texlive.org." )
        message( "++ If you *have* LaTeX installed, add its path to -DCMAKE_PREFIX_PATH." )
        set( JAWS_NOLATEX true )
    endif()
endif()

###########################################################################
# Java
###########################################################################

if ( JAWS_JARS OR JAWS_JARS_NOINSTALL )
    set( JAWS_JAVA_COMPONENTS "Development" )
    if ( BUILD_TESTING )
        list( APPEND JAWS_JAVA_COMPONENTS "Runtime" )
    endif()
    find_package( Java ${JAWS_JAVA_VERSION} COMPONENTS ${JAWS_JAVA_COMPONENTS} )
    if ( Java_Development_FOUND )
        include( UseJava )
        foreach( jar ${JAWS_JARS} ${JAWS_JARS_NOINSTALL} )
            # First source in each Java unit is set as entry point
            list( GET JAWS_${jar}_SOURCES 0 JAWS_JAR_ENTRY_POINT )
            remove_extension( JAWS_JAR_ENTRY_POINT )
            set( JAWS_JAR_ENTRY_POINT "${CMAKE_PROJECT_NAME}.${jar}.${JAWS_JAR_ENTRY_POINT}" )
            if ( JAWS_JAR_PACKAGE_DOMAIN )
                set( JAWS_JAR_ENTRY_POINT "${JAWS_JAR_PACKAGE_DOMAIN}.${JAWS_JAR_ENTRY_POINT}" )
            endif()
            prefix_filenames( JAWS_${jar}_SOURCES "${CMAKE_PROJECT_NAME}/${jar}" )
            add_jar( ${jar}
                     SOURCES ${JAWS_${jar}_SOURCES}
                     ENTRY_POINT ${JAWS_JAR_ENTRY_POINT}
                     VERSION "${JAWS_VERSION_MAJOR}.${JAWS_VERSION_MINOR}"
                   )
            list( APPEND JAWS_JAVA_PACKAGES ${CMAKE_PROJECT_NAME}.${jar} )
            list( FIND JAWS_JARS ${jar} JAR_TO_BE_INSTALLED )
            if ( JAR_TO_BE_INSTALLED GREATER -1 )
                install_jar( ${jar} bin )
            endif()
        endforeach()
        # The UseJava module actually provides a function create_javadoc(),
        # but it cannot be set to quiet mode, and it does not give a nice
        # intuitive "javadoc" target.
        add_custom_target( javadoc ALL
                           COMMAND ${Java_JAVADOC_EXECUTABLE} -quiet -d ${CMAKE_BINARY_DIR}/docs/javadoc ${JAWS_JAVA_PACKAGES}
                           WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                           VERBATIM )
                           install( DIRECTORY ${CMAKE_BINARY_DIR}/docs/javadoc DESTINATION ${JAWS_DOC_DIR} )
        add_dependencies( docs javadoc )
    else()
        message( "++ Java development environment not found." )
        message( "++ If you HAVE a JDK installed, add its path to -DCMAKE_PREFIX_PATH." )
        message( "++ Will NOT build ${JAWS_JARS}. Required package not found." )
    endif()
    if ( BUILD_TESTING AND NOT Java_Runtime_FOUND )
        message( "++ Java runtime environment not found." )
        message( "++ If you HAVE a JRT installed, add its path to -DCMAKE_PREFIX_PATH." )
        message( "++ Will NOT test ${JAWS_JARS}. Required package not found." )
    endif()
    find_package( JNI ${JAWS_JAVA_VERSION} )
    if ( NOT JNI_FOUND )
        message( "++ Java JNI components not found." )
        message( "++ If you HAVE JNI installed, add its path to -DCMAKE_PREFIX_PATH." )
        message( "++ Will NOT build JNI components. Required package not found." )
    endif()
    #get_target_property( JAWS_JNI_CLASS_DIR jniexample CLASSDIR )
    #add_custom_target( jni_header COMMAND ${Java_JAVAH_EXECUTABLE} -classpath ${JAWS_JNI_CLASS_DIR} -o MyProject/jniexample/JniInterface.h MyProject.jniexample.JniInterface )
    #javah( "MyProject/jniexample/JniInterface.java" )
endif()

###########################################################################
# ICU
###########################################################################

# The ICU library (http://icu-project.org) is THE standard for handling
# Unicode texts. Look no further.

# List components in this order for successful static linking:
# io i18n lx le uc dt
find_package( ICU REQUIRED io i18n uc data )
include_directories( ${ICU_INCLUDE_DIRS} )
set( JAWS_LINK_LIBRARIES ${ICU_LIBRARIES} )
string( REGEX REPLACE "([0-9]+).[0-9]+" "\\1" ICU_VERSION_MAJOR "${ICU_VERSION}" )
list( APPEND JAWS_DEBIAN_PACKAGE_DEPENDENCIES "libicu${ICU_VERSION_MAJOR}" )
list( APPEND JAWS_RPM_PACKAGE_DEPENDENCIES "libicu" )
if ( NOT SHARED )
    add_definitions( -DU_STATIC_IMPLEMENTATION )
endif()

###########################################################################
# Boost
###########################################################################

# The Boost libraries (http://www.boost.org) are a two-edged sword. On the
# one hand it is very versatile, giving us e.g. command line parsing, unit
# testing, portable path and filename handling etc. in one single package.
# Many C++ projects will use it anyway.

# On the other hand it is not exactly lightweight. Careless use of lots of
# Boost headers can increase compilation times significantly.

# There is also the issue of Unicode support. Boost.Regex and Boost.Locale
# require a Boost build linked with the ICU libraries for this purpose. On
# many platforms, however, available binary builds of Boost come *without*
# ICU linked in, requiring you to build the libraries manually. Since both
# ICU and Boost release new packages frequently, and the build process has
# been known to change and break between releases, this might be more than
# you are willing to handle.

# You have been warned.

set( Boost_USE_STATIC_LIBS OFF )
set( Boost_USE_MULTITHREADED ON )
set( Boost_USE_STATIC_RUNTIME OFF )
# In case your Boost version is newer than the newest supported by the
# FindBoost.cmake of your CMake installation.
set( Boost_ADDITIONAL_VERSIONS "1.63.0;1.63" )

# Add any sub-libraries that require linking (i.e., for which you get
# "unresolved external symbol" errors). Header-only libraries do not
# need to be listed. See TODO at top of file for Windows' strange
# requirements.

set( JAWS_Boost_COMPONENTS date_time filesystem program_options system thread unit_test_framework )

# Boost Thread for Windows depends on Date_Time and, since 1.47.0, also on
# Chrono (which did not exist in previous versions).

if ( WIN32 )
    set( Boost_USE_STATIC_LIBS ON )
    message( STATUS "Checking for Boost 1.47.1 or later" )
    find_package( Boost 1.47.1 COMPONENTS ${JAWS_Boost_COMPONENTS} chrono )
endif()
if ( NOT Boost_FOUND )
    message( STATUS "Checking for Boost 1.34.1 or later" )
    find_package( Boost 1.34.1 COMPONENTS ${JAWS_Boost_COMPONENTS} )
endif()

if ( Boost_FOUND )
    include_directories( ${Boost_INCLUDE_DIRS} )
    list( APPEND JAWS_LINK_LIBRARIES ${Boost_LIBRARIES} )
    # Disable the auto-link feature on Windows (which can collide with
    # $(Boost_LIBRARIES) above for non-default Boost layout settings).
    add_definitions( -DBOOST_ALL_NO_LIB )
else()
    message( "++ Boost libraries not found. (http://www.boost.org)" )
    message( "++ If you HAVE Boost installed, add its path to -DBOOST_ROOT." )
    message( "++ Also check the setting of Boost_ADDITIONAL_VERSIONS in the" )
    message( "++ file cmake/JAWS.cmake." )
    message( FATAL_ERROR "Required package not found." )
endif()
mark_as_advanced( BOOST_THREAD_LIBRARY )

foreach ( component ${JAWS_Boost_COMPONENTS} )
    if ( ${component} STREQUAL "unit_test_framework" )
        # The one Boost component where the component name does not match
        # the common package name (as far as I am aware of).
        set( component "test" )
    endif()
    string( REGEX REPLACE "_" "-" DEPENDENCY "${component}" )
    list( APPEND JAWS_DEBIAN_PACKAGE_DEPENDENCIES "libboost-${DEPENDENCY}${Boost_MAJOR_VERSION}.${Boost_MINOR_VERSION}.${Boost_SUBMINOR_VERSION}" )
    list( APPEND JAWS_RPM_PACKAGE_DEPENDENCIES "libboost_${component}${Boost_MAJOR_VERSION}_${Boost_MINOR_VERSION}_${Boost_SUBMINOR_VERSION}" )
endforeach()

###########################################################################
# wxWidgets
###########################################################################

# If you need to build a GUI, wxWidgets is a good choice. It is portable,
# free, and open source, while allowing for proprietary releases as well
# (which sets it apart from Qt, which requires a payed license for this).
# It is also natively C++ (other than GTK+). Sorry for the shameless plug.

# FIXME: This does not (yet) update the package dependencies according to
# the wxWidgets version found.

if ( GUI )
    find_package( wxWidgets 2.9.0 )
    if ( wxWidgets_FOUND )
        include( ${wxWidgets_USE_FILE} )
        list( APPEND JAWS_LINK_LIBRARIES ${wxWidgets_LIBRARIES} )
    else()
        message( "++ wxWidgets (>= 2.9.0) not found. (http://www.wxwidgets.org)" )
        message( "++ If you HAVE wxWidgets installed, add its path to -DCMAKE_PREFIX_PATH." )
        message( FATAL_ERROR "Required package not found." )
    endif()
endif()

###########################################################################
# CPack
###########################################################################

# Create packaging configuration
# Note that this *does* set necessary variables for building RPM / DEB
# packages, but whether the created packages are actually instalable /
# runable on a given RPM / DEB based system has not been tested, and
# thus TGZ has been set as package generator to play it safe.
# Windows packaging requires NSIS (http://nsis.sourceforge.net).
include( InstallRequiredSystemLibraries )
set( CPACK_PACKAGE_VERSION_MAJOR ${JAWS_VERSION_MAJOR} )
set( CPACK_PACKAGE_VERSION_MINOR ${JAWS_VERSION_MINOR} )
#set( CPACK_PACKAGE_VERSION_PATCH "0" )
set( CPACK_PACKAGE_CONTACT "${JAWS_PROJECT_AUTHOR} <${JAWS_PROJECT_CONTACTMAIL}>" )
set( CPACK_PACKAGE_DESCRIPTION_SUMMARY "${JAWS_PROJECT_LONGNAME} - ${JAWS_PROJECT_DESCRIPTION}" )
set( CPACK_DEBIAN_PACKAGE_SECTION "${JAWS_PROJECT_CATEGORY}" )
set( CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE.txt" )
set( CPACK_PACKAGE_VENDOR "${JAWS_PROJECT_AUTHOR} -- ${JAWS_PROJECT_WEBSITE}" )
set( CPACK_PACKAGE_NAME "${CMAKE_PROJECT_NAME}" )
string( REGEX REPLACE ";" ", " CPACK_DEBIAN_PACKAGE_DEPENDS "${JAWS_DEBIAN_PACKAGE_DEPENDENCIES}" )
string( REGEX REPLACE ";" ", " CPACK_RPM_PACKAGE_REQUIRES "${JAWS_RPM_PACKAGE_DEPENDENCIES}" )
set( CPACK_NSIS_MODIFY_PATH ON )
if ( WIN32 )
    set( CPACK_GENERATOR "NSIS${JAWS_LIBEXT}" )
    set( CPACK_SOURCE_GENERATOR "ZIP" )
else()
    if ( CPACK_GENERATOR )
        message( STATUS "CPACK_GENERATOR explicitly set to '${CPACK_GENERATOR}'." )
    else()
        message( "++ CPACK_GENERATOR not set, defaulting to 'DEB'." )
        set( CPACK_GENERATOR "DEB" )
        set( CPACK_SOURCE_GENERATOR "DEB" )
    endif()
endif()
include( CPack )

###########################################################################
# RPATH
###########################################################################

# We want executables linked against local libraries in the build directory
# but against installed libraries when installed.

# Use, i.e. don't skip the full RPATH for the build tree.
set( CMAKE_SKIP_BUILD_RPATH FALSE )

# Do not use the installation path in the build tree.
set( CMAKE_BUILD_WITH_INSTALL_RPATH FALSE )

# LIBRARY DESTINATION, see install() command below.
set( CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib${JAWS_LIBEXT}" )

# Add automatically determined paths of third-party libs to install RPATH
set( CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE )

# The RPATH to be used when installing, excluding system directories
list( FIND CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES
      "${CMAKE_INSTALL_PREFIX}/lib${JAWS_LIBEXT}"
      isSystemDir
    )
if ( "${isSystemDir}" STREQUAL "-1" )
    set( CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib${JAWS_LIBEXT}" )
endif()

###########################################################################
# Sources, Libs, Tests, Executables
###########################################################################

# JAWS_UNITS is a list of "units", or "modules", in the source tree. Each
# is a subdirectory in MyProject/, with its own folder in an IDE and its
# own test driver.
foreach ( library ${JAWS_LIBS} )
    list( APPEND JAWS_UNITS ${JAWS_${library}_UNITS} )
endforeach()

# A given unit may be used in more than one library.
list( REMOVE_DUPLICATES JAWS_UNITS )

# Processing source file lists
foreach ( unit ${JAWS_UNITS} )
    # In CMakeLists.txt, we only gave plain filenames. This here does the
    # proper prefixing to get absolute paths.
    prefix_filenames( JAWS_${unit}_SOURCES "${CMAKE_PROJECT_NAME}/${unit}/src" )
    prefix_filenames( JAWS_${unit}_HEADERS "${CMAKE_PROJECT_NAME}/${unit}" )
    prefix_filenames( JAWS_${unit}_TESTS   "${CMAKE_PROJECT_NAME}/${unit}/test" )
    # This is grouping the sources for graphical IDEs
    source_group( "Source Files\\${unit}" FILES ${JAWS_${unit}_SOURCES} )
    source_group( "Header Files\\${unit}" FILES ${JAWS_${unit}_HEADERS} )
    source_group( "Source Files\\${unit}" FILES ${JAWS_${unit}_TESTS} )

    add_library( ${unit}_obj OBJECT ${JAWS_${unit}_SOURCES} ${JAWS_${unit}_HEADERS} )
    list( APPEND JAWS_OBJ_TARGETS $<TARGET_OBJECTS:${unit}_obj> )
    list( APPEND JAWS_BIN_TARGETS ${unit}_obj )
    if ( SHARED )
        set_property( TARGET ${unit}_obj PROPERTY POSITION_INDEPENDENT_CODE 1 )
        target_compile_definitions( ${unit}_obj PUBLIC -D${CMAKE_PROJECT_NAME}_EXPORTS )
    endif()
endforeach()

# Declaring library targets
foreach ( library ${JAWS_LIBS} )
    set( JAWS_SOURCELIST )
    foreach ( unit ${JAWS_${library}_UNITS} )
        list( APPEND JAWS_SOURCELIST $<TARGET_OBJECTS:${unit}_obj> )
    endforeach()
    if ( SHARED )
        add_library( ${library} SHARED ${JAWS_SOURCELIST} )
        set_target_properties( ${library} PROPERTIES
                               VERSION "${JAWS_VERSION_MAJOR}.${JAWS_VERSION_MINOR}"
                               SOVERSION "${JAWS_VERSION_API}"
                             )
    else()
        add_library( ${library} STATIC ${JAWS_SOURCELIST} )
    endif()
    target_link_libraries( ${library} ${JAWS_${library}_DEPENDENCIES} ${JAWS_LINK_LIBRARIES} )
endforeach()

# This generates a header file with convenience macros for the import and
# export of symbols necessary for Windows DLLs.
include( GenerateExportHeader )
generate_export_header( ${CMAKE_PROJECT_NAME} EXPORT_FILE_NAME ${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}/${CMAKE_PROJECT_NAME}_export.h )
if ( NOT SHARED )
    add_definitions( -D${CMAKE_PROJECT_NAME}_STATIC_DEFINE )
endif()

# Declaring unit test driver binaries (linked with the object libs),
# and adding each as test to be run.
foreach ( unit ${JAWS_UNITS} )
    if ( JAWS_${unit}_TESTS AND BUILD_TESTING )
        add_executable( ${unit}_tu ${JAWS_${unit}_TESTS} ${JAWS_OBJ_TARGETS} )
        target_compile_definitions( ${unit}_tu PUBLIC -D${CMAKE_PROJECT_NAME}_EXPORTS )
        target_link_libraries( ${unit}_tu ${JAWS_LINK_LIBRARIES} )
        add_test( NAME ${unit}_tu COMMAND ${unit}_tu )
        list( APPEND JAWS_BIN_TARGETS ${unit}_tu )
    endif()
endforeach()

# Declaring installable executables (linked with the static / shared libs)
foreach ( exe ${JAWS_EXES} ${JAWS_EXES_NOINSTALL} )
    prefix_filenames( JAWS_${exe}_SOURCES "${CMAKE_PROJECT_NAME}/executables" )
    source_group( "Source Files\\${exe}" FILES ${JAWS_${exe}_SOURCES} )
    add_executable( ${exe} ${JAWS_${exe}_SOURCES} )
    target_link_libraries( ${exe} ${JAWS_${exe}_DEPENDENCIES} ${JAWS_LINK_LIBRARIES} )
    list( APPEND JAWS_BIN_TARGETS ${exe} )
endforeach()

# Declaring the 'check' test program and adding it as test to be run.
list( APPEND JAWS_BIN_TARGETS check )
add_executable( check ${CMAKE_BINARY_DIR}/tools/check.cpp )
target_link_libraries( check ${Boost_LIBRARIES} )
add_test( NAME check COMMAND check ${CMAKE_SOURCE_DIR} ${JAWS_CHECK_EXTENSIONS} )
# Workaround for a bug in locale handling resulting in crashes.
set_tests_properties( check PROPERTIES ENVIRONMENT "LANG=C" )

###########################################################################
# Installation
###########################################################################

# Compiled libraries
install( TARGETS ${JAWS_LIBS}
         RUNTIME DESTINATION bin
         ARCHIVE DESTINATION lib${JAWS_LIBEXT}
         LIBRARY DESTINATION lib${JAWS_LIBEXT}
       )

# Compiled executables
install( TARGETS ${JAWS_EXES} RUNTIME DESTINATION bin )

# _NOINSTALL binaries are for debugging / developer use only
if ( NOT ( ${CMAKE_BUILD_TYPE} STREQUAL "Release" ) )
    install( TARGETS ${JAWS_EXES_NOINSTALL} RUNTIME DESTINATION bin )
endif()

# If your project has data to be installed that would be out-of-place in
# either the binary or the documentation directory.
#install( DIRECTORY data
#         DESTINATION ${JAWS_DATA_DIR}
#         PATTERN ".svn" EXCLUDE )

# Verbatim documentation files
install( FILES CHANGES.txt README.txt DESTINATION ${JAWS_DOC_DIR} )

# Compiled documentation
if ( JAWS_NOLATEX )
    message( "++ Skipping installation of documentation (no LaTeX installation found)..." )
else()
    foreach( file ${JAWS_latex_documents} )
        install( FILES ${CMAKE_BINARY_DIR}/docs/${file}.pdf DESTINATION ${JAWS_DOC_DIR} )
    endforeach()
endif()

# Header files
install( FILES ${JAWS_INCLUDES} ${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}/${CMAKE_PROJECT_NAME}_export.h DESTINATION include/${CMAKE_PROJECT_NAME} )

###########################################################################
# Compiler-Specific Settings
###########################################################################

if ( CMAKE_COMPILER_IS_GNUCC )
    # GNU g++ - check for ..._GNUC for gcc
    set( JAWS_COMPILER_WARNINGS "-Wall -Wextra -pedantic -Wmissing-include-dirs -Wfloat-equal -Wundef -Wcast-align -Wwrite-strings -Wlogical-op -Wmissing-declarations -Wredundant-decls -Wshadow -Wno-system-headers -Wno-deprecated -Woverloaded-virtual -Wunused-variable -Wunused-parameter -Wunused-function -Wunused -Wabi -Wswitch-default -Wsign-conversion -Wconversion" )
    set( JAWS_COMPILER_NOWARNINGS "" )
    set( JAWS_COMPILER_COVERAGE "-fprofile-arcs -ftest-coverage" )
elseif ( MSVC )
    # Microsoft Visual C
    # 4996: CRT_SECURE_WARNINGS (which strangely enough are not completely disabled by /D...)
    set( JAWS_COMPILER_WARNINGS "/W3 /D_CRT_SECURE_NO_WARNINGS /wd4996" )
    set( JAWS_COMPILER_NOWARNINGS "/D_CRT_SECURE_NO_WARNINGS /wd4996" )
    set( JAWS_COMPILER_COVERAGE "" )
elseif ( "${CMAKE_SYSTEM_NAME}" STREQUAL "AIX" )
    # IBM Visual Age / xlC
    include( CheckAIXEnvironment )
    CheckAIXEnvironment()
    # -qsuppress=1540-0095 -- ignore a template warning generated by boost/mpl/set/aux_/set0.hpp
    # -qmaxmem=-1 -- ignore 8k memory limit on optimizations.
    set( JAWS_COMPILER_WARNINGS "-qalloca -qrtti=all -qsuppress=1540-0095 -qmaxmem=-1" )
    set( JAWS_COMPILER_NOWARNINGS "-qalloca -qrtti=all -qsuppress=1540-0095 -qmaxmem=-1" )
    set( JAWS_COMPILER_COVERAGE "" )
    # -bhalt:5 to suppress "duplicate symbols" warnings from the linker
    set_property( TARGET ${JAWS_LIBS} ${JAWS_BIN_TARGETS} APPEND_STRING PROPERTY LINK_FLAGS "-bhalt:5 -bbigtoc" )
endif()

# Activate compiler warnings unless WARNINGS option has been explicitly
# disabled. (If getting compiler warnings requires additional effort, too
# many developers won't bother.)

if ( WARNINGS )
    set_property( TARGET ${JAWS_LIBS} ${JAWS_BIN_TARGETS} APPEND_STRING PROPERTY COMPILE_FLAGS ${JAWS_COMPILER_WARNINGS} )
else()
    set_property( TARGET ${JAWS_LIBS} ${JAWS_BIN_TARGETS} APPEND_STRING PROPERTY COMPILE_FLAGS ${JAWS_COMPILER_NOWARNINGS} )
endif()

# Adding profiling / coverage output to debug builds

if ( JAWS_WITH_COV_AND_MEM AND JAWS_COMPILER_COVERAGE )
    set( CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${JAWS_COMPILER_COVERAGE}" )
    set( CMAKE_C_FLAGS_DEBUG     "${CMAKE_C_FLAGS_DEBUG} ${JAWS_COMPILER_COVERAGE}" )
    set( CMAKE_SHARED_LINKER_FLAGS_DEBUG                "${JAWS_COMPILER_COVERAGE}" )
    set( CMAKE_EXE_LINKER_FLAGS_DEBUG                   "${JAWS_COMPILER_COVERAGE}" )
endif()

###########################################################################
# Postfix Naming
###########################################################################

# Appending non-release builds with postfix names to the library and its
# executables, to allow parallel installation of all build types into a
# single directory.

set_property( TARGET ${JAWS_LIBS} ${JAWS_BIN_TARGETS} PROPERTY DEBUG_POSTFIX "-debug" )
set_property( TARGET ${JAWS_LIBS} ${JAWS_BIN_TARGETS} PROPERTY TRACE_POSTFIX "-trace" )
set_property( TARGET ${JAWS_LIBS} ${JAWS_BIN_TARGETS} PROPERTY DEBUGTRACE_POSTFIX "-debugtrace" )
set_property( TARGET ${JAWS_LIBS} ${JAWS_BIN_TARGETS} PROPERTY RELWITHDEBINFO_POSTFIX "-relwithdebinfo" )
set_property( TARGET ${JAWS_LIBS} ${JAWS_BIN_TARGETS} PROPERTY MINSIZEREL_POSTFIX "-minsizerel" )
