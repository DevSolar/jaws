if ( EXISTS .svn )
    message( FATAL_ERROR "This is a SVN work directory.\nYou should use 'svn export' to obtain a clean copy of JAWS." )
endif()

if ( NOT ${CMAKE_ARGC} EQUAL 4 )
    message( FATAL_ERROR "Call as: 'cmake -P JAWSInit.cmake <projectname>'" )
endif()

string( TOUPPER "${CMAKE_ARGV3}" prj_upper )
string( TOLOWER "${CMAKE_ARGV3}" prj_lower )

file( GLOB_RECURSE files *.cmake *.tex *.in *.cpp *.hpp *.h *.java CMakeLists.txt )

list( REMOVE_ITEM files JAWSInit.cmake )

foreach( file IN LISTS files )
    file( READ ${file} contents )
    string( REPLACE "MyProject" "${prj_lower}" tmp "${contents}" )
    string( REPLACE "MYPROJECT" "${prj_upper}" contents "${tmp}" )
    file( WRITE "${file}" "${contents}" )
endforeach()

#file( RENAME "MyProject/MyProject.h" "${prj_lower}/${prj_lower}.h" )
file( RENAME "MyProject"             "${prj_lower}" )

file( RENAME "README.txt" "README_JAWS.txt" )
