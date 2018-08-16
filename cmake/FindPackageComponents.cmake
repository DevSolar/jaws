# This is the FindPackageComponents module, part of the JAWS C++ project
# framework from http://jaws.rootdirectory.de.
#
# Provided under Creative Commons CC0 (Public Domain Dedication)
# https://creativecommons.org/publicdomain/zero/1.0/deed.en
#
# This module defines a couple of helper functions that make writing
# custom Find<xyz>.cmake modules that much easier.
#
# The general idea here is that every Find<package>.cmake has its own
# <package>_ROOT parameter, which can be set by the user to indicate
# non-standard installation locations. The individual functions then
# do all the plumbing work to set the right variables.
#
# If there is a component that you *always* want to look for (like
# the core library of the package), append its name to the list
# <package>_FIND_COMPONENTS before calling the corresponding
# find_*component() function below.
#
# -----------------------------------------------------------------------
#
# Example usage for a 'FindFoo.cmake' that finds:
# * a foo.h include;
# * a library 'libfoo';
# * an expansion library either named 'libextra' or 'libexp';
# * a foo executable;
# * a 'resource' directory containing a file foo.conf.
#
#     # Library 'foo' is _always_ "requested", the rest is optional
#     list( APPEND Foo_FIND_COMPONENTS foo )
#     include( FindPackageComponents )
#     find_includedir( foo.h )
#     find_libcomponent( "Foo library" foo )
#     find_libcomponent( "Foo expansion library" fooextra fooexp )
#     find_execomponent( "Foo executable" foo )
#     find_resourcedir( FOO_RESOURCES foo.conf resource "Foo resources" )
#     find_package_handle_params( "http://www.foo-software.com" )
#
# -----------------------------------------------------------------------
#
# Description of individual functions provided:
#
# - find_includedir( indicator )
#   For finding the include path for the package, using a (hopefully)
#   unambiguously named include file as "indicator". If <package>_ROOT
#   is set, <package>_ROOT/include will be used as path hint. The result
#   is stored in the standard variable <package>_INCLUDE_DIR, which is
#   given a generic docstring and marked as advanced.
#   This lookup is always done, regardless of which (if any) components
#   have been specified by find_package().
#
# - find_resourcedir( RESULT_VAR indicator path_suffix docstring )
#   The more generic version of find_includedir() above. If <package>_ROOT
#   is set, it will be used (without hardcoded suffixes) as path hint.
#   Suffixes must be specified in the path_suffix parameter. The specified
#   docstring is used, the result stored in RESULT_VAR.
#   This lookup is always done, regardless of which (if any) components
#   have been specified by find_package(). To have the result of this
#   lookup influence <package>_FOUND, add RESULT_VAR as additional parameter
#   to find_package_handle_params (see below).
#
# - find_libcomponent( docstring component [alt_name [alt_name ...] ] )
#   For finding library components if specified by find_package(). If
#   <package>_ROOT is set, <package>_ROOT/lib is used as path hint. The
#   result is stored in the standard variable <package>_<component>_LIBRARY,
#   which is given the specified docstring and marked as advanced.
#   Alternative names for the component can be given as additional parameters.
#   If the library component is found, it is also automatically appended
#   to <package>_LIBRARIES, and <package>_<component>_FOUND is set.
#   The name of a library component must be identical to the name of the
#   library, i.e. lib<foo>.so must be named <foo> for this function to work.
#   Also creates a new IMPORTED target <package>::<component> if you prefer
#   this new style.
#   If the given component was not requested by find_package(), this
#   function does nothing.
#
# - find_execomponent( docstring component [alt_name [alt_name ...] ] )
#   For finding executable components if specified by find_package(). If
#   <package>_ROOT is set, <package>_ROOT/bin is used as path hint. The
#   result is stored in the standard variable <package>_<component>_EXECUTABLE,
#   which is given the specified docstring and marked as advanced.
#   Alternative names for the component can be given as additional parameters.
#   If the executable component is found, <package>_<component>_FOUND is set.
#   The name of an executable component must be identical to the name of
#   the executable, i.e. <foo>.exe must be named <foo> for this function
#   to work. Also creates a new IMPORTED target <package>::<component> if
#   you prefer this new style.
#   If the given component was not requested by find_package(), this
#   function does nothing.
#
# - find_package_handle_params( url [required_var [required_var ...] ] )
#   Convenience wrapper for the standard parameter handling provided
#   by CMake, including required version and the parameters EXACT, QUIET
#   and REQUIRED.
#   The URL is used for a meaningful error message (i.e. giving a hint
#   where to obtain the package if it was not found). Sets <package>_FOUND
#   as appropriate, forwards all <package>_<component>_FOUND variables
#   to parent scope, and sets <package>_INCLUDE_DIRS as well as
#   <package>_LIBRARIES in the parent scope as appropriate.
#

function( find_resourcedir RESULT_VAR indicator path_suffix docstring )
    if ( ${CMAKE_FIND_PACKAGE_NAME}_ROOT )
        # <package>_ROOT needs to be suffixed by /include to be useful
        set( INCHINTS HINTS ${${CMAKE_FIND_PACKAGE_NAME}_ROOT} )
    endif()

    find_path( ${RESULT_VAR} NAMES ${indicator} ${INCHINTS} PATH_SUFFIXES ${path_suffix} DOC "${docstring}" )
    mark_as_advanced( ${RESULT_VAR} )
endfunction()


function( find_includedir indicator )
    string( TOLOWER ${CMAKE_FIND_PACKAGE_NAME} CMAKE_FIND_PACKAGE_NAME_LOWER )
    if ( ${CMAKE_FIND_PACKAGE_NAME}_ROOT )
        # <package>_ROOT needs to be suffixed by /include to be useful
        set( INCHINTS HINTS ${${CMAKE_FIND_PACKAGE_NAME}_ROOT}/include ${${CMAKE_FIND_PACKAGE_NAME}_ROOT}/include/${CMAKE_FIND_PACKAGE_NAME_LOWER} )
    else()
        set( INCHINTS HINTS ${CMAKE_FIND_PACKAGE_NAME_LOWER} )
    endif()

    find_path( ${CMAKE_FIND_PACKAGE_NAME}_INCLUDE_DIR NAMES ${indicator} ${INCHINTS} DOC "${CMAKE_FIND_PACKAGE_NAME} include directory" )
    mark_as_advanced( ${CMAKE_FIND_PACKAGE_NAME}_INCLUDE_DIR )
endfunction()


function( find_libcomponent docstring component )

    # Only try to locate the component if it is actually listed by the caller
    list( FIND ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS ${component} required )
    if ( ${required} GREATER -1 )

        if ( ${CMAKE_FIND_PACKAGE_NAME}_ROOT )
            # <package>_ROOT needs to be suffixed by /lib to be useful
            set( LIBHINTS HINTS ${${CMAKE_FIND_PACKAGE_NAME}_ROOT}/lib )
        endif()

        # We need <package>_INCLUDE_DIR to be set so we can add it to the
        # imported target.
        if ( NOT ${CMAKE_FIND_PACKAGE_NAME}_INCLUDE_DIR )
            message( FATAL_ERROR "Function find_libcomponent() requires valid ${CMAKE_FIND_PACKAGE_NAME}_INCLUDE_DIR (set to '${${CMAKE_FIND_PACKAGE_NAME}_INCLUDE_DIR}')." )
        endif()

        find_library( ${CMAKE_FIND_PACKAGE_NAME}_${component}_LIBRARY NAMES ${component} ${ARGN} ${LIBHINTS} DOC ${docstring} )
        mark_as_advanced( ${CMAKE_FIND_PACKAGE_NAME}_${component}_LIBRARY )

        if ( ${CMAKE_FIND_PACKAGE_NAME}_${component}_LIBRARY )
            set( ${CMAKE_FIND_PACKAGE_NAME}_${component}_FOUND true PARENT_SCOPE )
            set( ${CMAKE_FIND_PACKAGE_NAME}_LIBRARIES ${${CMAKE_FIND_PACKAGE_NAME}_LIBRARIES} ${${CMAKE_FIND_PACKAGE_NAME}_${component}_LIBRARY} PARENT_SCOPE )
            add_library( ${CMAKE_FIND_PACKAGE_NAME}::${component} UNKNOWN IMPORTED )
            set_target_properties( ${CMAKE_FIND_PACKAGE_NAME}::${component} PROPERTIES
                IMPORTED_LOCATION "${${CMAKE_FIND_PACKAGE_NAME}_${component}_LIBRARY}"
                INTERFACE_INCLUDE_DIRECTORIES "${${CMAKE_FIND_PACKAGE_NAME}_INCLUDE_DIR}"
            )
        endif()

    endif()

endfunction()


function( find_execomponent docstring component )

    # Only try to locate the component if it is actually listed by the caller
    list( FIND ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS ${component} required )
    if ( ${required} GREATER -1 )

        if ( ${CMAKE_FIND_PACKAGE_NAME}_ROOT )
            # <package>_ROOT needs to be suffixed by /bin to be useful
            set( EXEHINTS HINTS ${${CMAKE_FIND_PACKAGE_NAME}_ROOT}/bin )
        endif()

        find_program( ${CMAKE_FIND_PACKAGE_NAME}_${component}_EXECUTABLE NAMES ${component} ${ARGN} ${EXEHINTS} DOC ${docstring} )
        mark_as_advanced( ${CMAKE_FIND_PACKAGE_NAME}_${component}_EXECUTABLE )

        if ( ${CMAKE_FIND_PACKAGE_NAME}_${component}_EXECUTABLE )
            set( ${CMAKE_FIND_PACKAGE_NAME}_${component}_FOUND true PARENT_SCOPE )
            add_executable( ${CMAKE_FIND_PACKAGE_NAME}::${component} IMPORTED )
            set_target_properties( ${CMAKE_FIND_PACKAGE_NAME}::${component} PROPERTIES
                IMPORTED_LOCATION "${${CMAKE_FIND_PACKAGE_NAME}_${component}_EXECUTABLE}"
            )
        endif()

    endif()

endfunction()


include( FindPackageHandleStandardArgs )
function( find_package_handle_params url )
    set( REQVARS ${CMAKE_FIND_PACKAGE_NAME}_INCLUDE_DIR )
    if ( ${CMAKE_FIND_PACKAGE_NAME}_LIBRARIES )
        set( REQVARS ${CMAKE_FIND_PACKAGE_NAME}_LIBRARIES ${REQVARS} )
    endif()
    if ( ARGN )
        set( REQVARS ${REQVARS} ${ARGN} )
    endif()
    find_package_handle_standard_args(
        ${CMAKE_FIND_PACKAGE_NAME}
        FOUND_VAR ${CMAKE_FIND_PACKAGE_NAME}_FOUND
        REQUIRED_VARS ${REQVARS}
        VERSION_VAR ${CMAKE_FIND_PACKAGE_NAME}_VERSION
        HANDLE_COMPONENTS
        FAIL_MESSAGE "${CMAKE_FIND_PACKAGE_NAME} not found (${url}). If you HAVE ${CMAKE_FIND_PACKAGE_NAME} installed, add its path to CMAKE_PREFIX_PATH."
        )

    # Promoting all _FOUND variables to parent scope
    foreach( component ${${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS} )
        set( ${CMAKE_FIND_PACKAGE_NAME}_${component}_FOUND ${${CMAKE_FIND_PACKAGE_NAME}_${component}_FOUND} PARENT_SCOPE )
    endforeach()
    set( ${CMAKE_FIND_PACKAGE_NAME}_FOUND ${CMAKE_FIND_PACKAGE_NAME}_FOUND PARENT_SCOPE )

    if ( ${CMAKE_FIND_PACKAGE_NAME}_FOUND )
        set( ${CMAKE_FIND_PACKAGE_NAME}_INCLUDE_DIRS ${${CMAKE_FIND_PACKAGE_NAME}_INCLUDE_DIR} PARENT_SCOPE )
    else()
        unset( ${CMAKE_FIND_PACKAGE_NAME}_LIBRARIES PARENT_SCOPE )
    endif()
endfunction()
