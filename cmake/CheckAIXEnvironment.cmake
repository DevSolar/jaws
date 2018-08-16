macro( CheckAIXEnvironment )
    message( STATUS "Checking AIX environment variables" )

    if ( "$ENV{OBJECT_MODE}" STREQUAL "32" OR
         "$ENV{OBJECT_MODE}" STREQUAL "64" OR
         "$ENV{OBJECT_MODE}" STREQUAL "32_64"
       )
        message( "-- OBJECT_MODE is set to $ENV{OBJECT_MODE}." )
    else()
        message( SEND_ERROR "OBJECT_MODE is not set to either '32', '64', or '32_64'. "
                            "The default is to build 32bit libraries. "
                            "Current settings:   OBJECT_MODE=$ENV{OBJECT_MODE}" )
    endif()

    string( REGEX MATCH "_r[47]?$" THREADED_CXX "$ENV{CXX}" )
    string( REGEX MATCH "_r[47]?$" THREADED_CC "$ENV{CC}" )

    if ( NOT ( THREADED_CXX AND THREADED_CC ) )
        message( SEND_ERROR "You need to set CC and CXX to name a compiler generating "
                            "thread-safe code. xlc_r and xlC_r do, the default cc and "
                            "xlC do not (which WILL make code relying on Boost.Thread "
                            "fail to compile). "
                            "Current settings:   CC=$ENV{CC}   CXX=$ENV{CXX}" )
    endif()
endmacro()
