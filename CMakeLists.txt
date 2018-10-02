# Usually a CMakeLists.txt is stuffed with all kinds of conditionals and
# commands, which can make orientation rather difficult for the CMake
# novice.
#
# With JAWS, you merely set a number of variables, and leave the "CMake
# magic" to the JAWS module.
#
# Variables are all prefixed with "JAWS_*", so you can tell apart what is
# basic CMake functionality, and what is the JAWS layer on top of that.

# This makes sure that you are not running on an outdated, untested
# version of CMake.
#
# Up to and including CMake 3.7.2, FindICU.cmake has a bug that means it
# does not find ICU_INCLUDE_DIR in a given ICU_ROOT. This has been
# resolved with CMake 3.8.0-rc1.
cmake_minimum_required( VERSION 3.8.0 FATAL_ERROR )

# Project Info
##############

# These obviously need changing according to YOUR project.
# These variables are mainly used for CPack, i.e. for packaging metadata.
# The LONGNAME is also used for the config file example below.
project( MyProject )          # One-word project/package name
set( JAWS_PROJECT_LONGNAME    "Just A Working Setup" )
set( JAWS_PROJECT_DESCRIPTION "a C++ project framework" )
set( JAWS_PROJECT_AUTHOR      "Martin Baute" )
set( JAWS_PROJECT_CONTACTMAIL "solar@rootdirectory.de" )
set( JAWS_PROJECT_WEBSITE     "http://jaws.rootdirectory.de" )
set( JAWS_PROJECT_CATEGORY    "misc" )

# Options
#########

# Can be set on the command line ("cmake -DWARNINGS=OFF"), or in
# the GUI. These are named by you. They have not been prefixed
# with "JAWS_*" because they are representing options of your
# project, not the JAWS framework.
# Note that, should you remove any of the example options, you
# should also check cmake/JAWS.cmake for necessary changes.

option( WARNINGS "Enable compiler warnings. Default: ON." ON )
option( GUI      "Compile with GUI support. Default: OFF." OFF )
option( SHARED   "Compile shared (.so / .dll) or static (.a / .lib). Default: ON (shared)." ON )

# Version
#########

# These numbers are used in various places, e.g. to create the binary's
# version string or the package version. Do not forget to bump this!
# The "API" version is used by the linker for shared library versioning.
# Bump this only if you are making incompatible changes to the API;
# consider keeping this in sync with the "MAJOR" version.

# For now, there is only one version used for all libraries, executables
# and documents coming out of the build process, to keep things simple.
# If you require a more tailor-made versioning of your components, feel
# free to customize. See "General Configuration" below.

set( JAWS_VERSION_MAJOR "0" )
set( JAWS_VERSION_MINOR "1" )
set( JAWS_VERSION_API ${JAWS_VERSION_MAJOR} )

# General Configuration
#######################

# Feel free to add custom variables here. If you want them to be forwarded
# to your source files, the procedure is to:
# - append ".in" to the file name to indicate it has to be pre-processed,
# - in the source, refer to the variable as @VARIABLE_NAME@
# - make sure you do NOT have any other @...@ sequences in that source, as
#   they would be replaced by the value of the corresponding CMake variable
#   (i.e., probably nothing), likely resulting in errors.
# - add the source file (WITHOUT the ".in") to JAWS_configure_files below.

# Maximum allowed length of a file name.
# Used by the "check" test (for making sure no source filename is actually
# longer than this).

set( JAWS_MAX_FILENAME_LEN "25" )

# The minimum required version of the Java SDK (for building configured
# Java targets). If the project does not include Java sources, this will
# be ignored.

set( JAWS_JAVA_VERSION 1.3 )

# The "check" test executable checks source files for filename length, use
# of characters outside the basic character set (which might cause trouble),
# and coding style (the latter requiring AStyle installed in your PATH, see
# http://astyle.sourceforge.net).
# This here is a list of filename extensions that should be checked this
# way.

set( JAWS_CHECK_EXTENSIONS .cpp .cpp.in .c .c.in .hpp .hpp.in .h .h.in .java .java.in )

# Targets, units, and dependencies
##################################

# The JAWS setup allows for 1..n libraries, each consisting of 1..n units,
# and 0..n executables.
# Each library could be linked against others, as could the executables.
# That should be flexible enough for the majority of all projects.

# The C++ libraries.

set( JAWS_LIBS
     MyProject
   )

# If you have more than one library, and one of them depends on another,
# list such dependencies here, as JAWS_<library>_DEPENDENCIES.

set( JAWS_MyProject_DEPENDENCIES
     # ...none.
   )

# The units for each library, each unit located at MyProject/<unit>,
# listed as JAWS_<library>_UNITS.

set( JAWS_MyProject_UNITS
     core
   )

# The C++ executables.  _NOINSTALL executables do not get installed with
# Release builds.

set( JAWS_EXES
     options_example
   )

set( JAWS_EXES_NOINSTALL
     # ...none.
   )

# Conditional compilation -- appending to the lists above depending on which
# options are set.

if ( GUI )
    list( APPEND JAWS_EXES
          gui_example
        )

    list( APPEND JAWS_EXES_NOINSTALL
          # ...none.
        )
endif()

# If your executables depend on one or more of your libraries (they usually
# do), list such dependencies here.

set( JAWS_options_example_DEPENDENCIES
     MyProject
   )

set( JAWS_gui_example_DEPENDENCIES
     # ...none.
   )

# A list of the Java units in the project, each being a MyProject/<junit>
# subdirectory. Each unit results in a JAR file.
# Leave this empty, or delete outright, to disable Java configurarion /
# compilation.

set( JAWS_JARS
     javaexample
     jniexample
   )

set( JAWS_JARS_NOINSTALL
     # ...none.
   )

# File Lists
############

# The list of files in which @...@ sequences should be replaced with CMake
# variables. Note that the actual input files have ".in" appended to their
# name, which is not given here.
# The JAWS module turns this into:
# configure_file( "${CMAKE_SOURCE_DIR}/${file}.in" "${CMAKE_BINARY_DIR}/${file}" @ONLY )

set( JAWS_configure_files
     "tools/check.cpp"
     "MyProject/core/src/Constants.cpp"
     "MyProject/core/test/ConstantsTu.cpp"
   )

# Lists of any LaTeX documents that should be turned into PDF. There will be
# a build target "pdf" that includes all these documents. The "pdf" target
# is also included in the "docs" target, which additionally builds other
# documentation like Doxygen. There will also be a target "auxclean" that
# cleans LaTeX auxiliary files, which might become necessary if you get
# strange errors from LaTeX.
# Generating PDFs from LaTeX requires a functional LaTeX installation;
# otherwise you will get a warning during build file generation, and the
# documents will not be built. You can download free LaTeX frameworks from:
#
# - http://miktex.org (Windows)
# - http://tug.org/texlive (Unix, Windows)
#
# Any <document> listed here will be build from the docs/<document>.tex.
# If you do not know LaTeX, do have a look at the included LaTeX docs. The
# PDF output format, the quality of output, and the fact that LaTeX is
# compiled from plaintext source (which can be handled just like any other
# source, with the version control software, diff tools, and text editor of
# the developer's preference) makes it the superior format for generating
# software documentation.

# Documentation that should be included in the shipped package.
set( JAWS_latex_documents
     "UserGuide"
   )

# Documentation that is for internal use only, not to be shipped with
# Release builds.
set( JAWS_latex_documents_NOINSTALL
     "DeveloperGuide"
     "JAWSGuide"
   )

# Any include files that should be installed (for inclusion by clients of
# your library / libraries).

set( JAWS_INCLUDES
     #...none.
   )

# Source File Lists
###################

# For each unit, a list of:
# - its sources (at MyProject/<unit>/src/), as JAWS_<unit>_SOURCES;
# - its headers (at MyProject/<unit>/), as JAWS_<unit>_HEADERS;
# - its test drivers (at MyProject/<unit>/tests/), as JAWS_<unit>_TESTS.

# Note that you only need to give the basenames here, in case of files run
# through variable replacement (see above) listed without .in suffix. JAWS
# does automatically prefix MyProject/<unit>/... for you, and in case of
# configured files, prefixes ${CMAKE_BINARY_PATH} as well. This also means
# you cannot drag in source files from a different unit's directory, which
# should be considered a feature.

set( JAWS_core_SOURCES
     Constants.cpp
   )

set( JAWS_core_HEADERS
     Constants.h
   )

set( JAWS_core_TESTS
     ConstantsTu.cpp
   )

# For each executable, a list of its sources (at MyProject/executables/).
# JAWS could deduce the source file name from the executable name, but you
# might want to split an executable over more than one source file.
# Again, you need only give basenames, JAWS does the MyProject/executables/
# prefix.

set( JAWS_options_example_SOURCES
     options_example.cpp
   )

set( JAWS_gui_example_SOURCES
     gui_example.cpp
   )

# Sources for each Java unit (residing in MyProject/<junit> without the
# .../src/ subdirectory).

set( JAWS_javaexample_SOURCES
     main.java
   )

set( JAWS_jniexample_SOURCES
     main.java
     JniInterface.java
   )

# Done
######

# Now we have set everything up, and delegate the actual work to the JAWS
# module so this file here stays clean and simple.

# Adds the ./cmake directory to the include path, so that JAWS.cmake can
# be found.
set( CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake )

# Include the JAWS module to do its magic.
include( JAWS )
