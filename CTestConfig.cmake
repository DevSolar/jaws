# This is, among others, used as the name for the installation directory
set( CTEST_PROJECT_NAME "MyProject" )

# A "nightly" build sets the repository to the state of a specific time,
# so all build clients will work on identical versions.
set( CTEST_NIGHTLY_START_TIME "01:00:00 UTC" )

# Where and how to send the result data
set( CTEST_DROP_METHOD "http" )
set( CTEST_DROP_SITE "127.0.0.1" )
set( CTEST_DROP_LOCATION "/cdash/submit.php?project=MyProject" )
set( CTEST_DROP_SITE_CDASH TRUE )

# If you want CDash to ignore certain compiler warnings when determining
# build success / failure, add their text here. (Regexes allowed.)
#list( APPEND CTEST_CUSTOM_WARNING_EXCEPTION "text of warning to be ignored" )
