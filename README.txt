===========================================================================

This is the JAWS C++ project framework, as retrieved from:

           http://jaws.rootdirectory.de

It is meant as a strong starting point and foundation for any C++ project
you might be thinking about.

Feedback to Martin Baute, solar@rootdirectory.de.

===========================================================================

                                    CONTENTS

*  What was the motivation for JAWS?
*  What JAWS does for you, exactly
*  Getting Started
*  CTest
*  CDash

===========================================================================

                       WHAT WAS THE MOTIVATION FOR JAWS?

When you are working with C/C++, compiling your source into binaries is
only a small (albeit important) part of what you need your computer to do.
There are many tools offering help here, the trick is to know them, and
how to use them.

You need to create documentation on the internals of your source. Doxygen
is the tool of choice for this, but you might not be familiar with it, how
to set it up, how to use it, how to integrate it into your build system.

You need to create documentation for the client. LaTeX has many advantages
over standard word processors, but again lack of familiarity might keep
you from enjoying its benefits.

Being able to run unit tests and checking your sources for style guide
compliance automatically might be a nice thing, but if this involves
additional work to set up many might not bother, despite knowing of the
benefits such a setup would bring. And while most developers can agree to\
work on an existing code base in an existing code style without problems,
when faced with a clean slate things can deteriorate into heated arguments
about the One True Brace Style really quickly.

Having a facility to print logging and informational messages from your
application, nicely formatted and with a timestamp, is a nice thing. But
again many developers will "make do" because they want to start working
on the "real" issue of their project.

Having the means to run a fresh build automatically whenever you commit
new changes to the repository, or each morning before the developers come
in for the day, with the results being displayed by an easily accessible
website? Yes, but only if it does not cost too much to set up.

And when all is compiled and done, packaging for release can be tricky,
and you will want to have this done automatically so you do not miss a
step.

CMake is a very powerful build system that can be configured to do all the
above things for you. However, the sheer amount of features and somewhat
haphazard documentation of CMake can pose quite a challenge to newcomers.

So here is "just a working setup", intended to provide a ready-to-use
starting point with all those things mentioned above included. Unpack,
reconfigure to suit your project, and you are ready to do the first full
build. Including Doxygen run, LaTeX-generated PDF docs, code reformatting
with useful defaults, unit tests, and a logger unit already set up for you.

===========================================================================

                        WHAT JAWS DOES FOR YOU, EXACTLY

JAWS is a "base project". It represents the raw infrastructure; by forking
it, you start with a complete framework instead of starting from scratch.

It all revolves around a CMake setup (http://www.cmake.org). The offerings
of JAWS in detail:

- Configuration segregated to the point where ./CMakeLists.txt mostly
  consists of simple set() commands: Which units there are, which source
  files and test drivers to compile for each unit, which files to send to
  the LaTeX compiler et cetera. This is what you need to touch every now
  and then, so it is nice to not have it buried in lots of "CMake magic"
  (which is hidden away in ./cmake/JAWS.cmake).

- CMake provides a preprocessing step, allowing to replace CMake symbols
  in certain source files with the values of CMake variables. This allows
  to keep certain configurations (like version numbers) in the central
  configuration file, making for easier maintenance. JAWS simplifies the
  process.

- The file lists set up in ./CMakeLists.txt do not require you to state
  file paths. JAWS handles this automatically. This means you cannot add
  a source file from subdirectory X to unit Y, but that can be considered
  more of a feature than a limitation.

- LaTeX is a powerful tool (not only) for generating project documentation.
  Compiled from plain text, it allows to use your favourite editor, text
  processing tools (e.g. grep, diff) and version control software, instead
  of referring to word processors. JAWS includes the module UseLATEX.cmake
  by Kenneth Moreland, allowing to process LaTeX documents under CMake
  control. Also included is a preconfigured LaTeX document to get newcomers
  started. Simply add any LaTeX documents to the ./docs/ directory and list
  them in ./CMakeLists.txt as JAWS_latex_documents -- CMake will add the
  build target "pdf" and takes care of the rest.

- International Components for Unicode (ICU, http://www.icu-project.org)
  provide comprehensive support for character encodings, Unicode, and
  localisation. If your application handles text, chances are you will want
  to use ICU. But while CMake comes with FindXXX.cmake modules for many
  common libraries, ICU is not among them. While there are various examples
  of FindICU.cmake to be found on the internet, it is nice to have one
  right here. (If not installed in a system directory, you need to specify
  the path to the ICU installation as -DCMAKE_PREFIX_PATH when configuring
  the build.)

- The Boost library collection (http://www.boost.org) is a staple of C++
  software development. The code frame of JAWS uses Boost itself. If you
  have additional requirements you can easily extend the list of Boost
  COMPONENTS in ./cmake/JAWS.cmake.

- Doxygen (http://www.doxygen.org) generates documentation directly from
  C/C++ source code and its comments (similar to Javadoc does for Java).
  JAWS provides a preconfigured Doxygen.cfg file (taking e.g. project name,
  paths, and version numbers from ./CMakeLists.txt), and adds a build
  target "doxygen" to run Doxygen under CMake control.

- Building the LaTeX and Doxygen documentation is combined under the "docs"
  build target.

- "check" test tool scans source file names and contents for problematic /
  non-portable characters. If AStyle (http://astyle.sourceforge.net) is
  installed, also runs code reformatting on sources. To avoid changes made
  by AStyle getting checked in without manual review, changed files are
  saved as "<file>.reformatted" and the "check" test fails.

- Several CMake features demonstrated by example, e.g. RPATH handling,
  configuration options (WARNINGS), grouping unit sources in IDE project
  files.

- While CMake already supports multiple build targets, like Release or
  Debug builds, JAWS adds the targets DebugTrace and Trace, for tracing
  compilations with or without debug informations, respectively.

- Compiler-specific settings for GCC, Microsoft Visual C++ and IBM Visual
  Age / AIX toolchains already provided, easily extendable.

- CTest configuration file allows for script-driven Nightly, Continuous,
  and Experimental builds, including checks for memory leaks and test
  coverage. It also allows to get a Release, Debug, Trace, or DebugTrace
  build done without having to bother with a manually-written CMake line.
  (For details, see "CTEST" below.)

- CDash configuration file allows for sending the CTest results to a CDash
  webserver for easy reference. (For details, see "CDASH" below.)

- Regardless of which platform you are working on, once you are done with
  building and testing, all you need to do is call "cpack" and see your
  build be packaged for release, including an NSIS GUI installer for
  Windows.

- An include file is generated at MyProject/MyProject_export.h faciliating
  the DLL Export declarations required on Windows.

===========================================================================

                                GETTING STARTED

- If you got the JAWS framework directly from Subversion, make sure you
  used "svn export", not "svn checkout". You will be wanting to create a
  project repository of your own, and JAWS' .svn metadata would just get
  in the way.

- Find a good name for your project. It should be all lowercase, short, and
  not contain any spaces. It will be used as directory and file name, C++
  namespace, and package name, so choose with care.

- Call 'cmake -P JAWSInit.cmake <projectname>' from the source directory
  of JAWS (this replaces all uses of the placeholder "MyProject" with your
  chosen project name, cleans out the "$Header:" tags, renames this file
  to README_JAWS.txt, and then deletes itself).

- Create a new README.txt with a short description of YOUR project. (If a
  mention of JAWS remains in there, I would be happy.)

- Replace the contents of LICENSE.txt with a description of YOUR licensing
  conditions. You should keep the mention of UseLATEX.cmake intact.

- In the files ./docs/UserGuide.tex and ./docs/DeveloperGuide.tex, replace
  my name (Martin Baute) with yours. In the "CPack" configuration section
  in ./cmake/JAWS.cmake, replace my information (name, mail address, and
  package description) with the settings for YOUR project.

- Make sure you have the following software installed, in addition to your
  compiler toolchain of choice:

  CMake                      http://www.cmake.org
  Doxygen                    http://www.doxygen.org
  Graphviz                   http://www.graphviz.org
  LaTeX                      http://www.texlive.org (for Linux et al.)
                             http://www.miktex.org (for Windows)
  ImageMagick                http://www.imagemagick.org
  AStyle                     http://astyle.sourceforge.net
  ICU libraries & headers    http://www.icu-project.org
  Boost libraries & headers  http://www.boost.org
  NSIS                       http://nsis.sourceforge.net (for Windows)

  CMake is absolutely required to make JAWS work.

  Doxygen and Graphviz are used for the "doxygen" build target, LaTeX for
  the "pdf" build target. Not having the software installed will not break
  the build, but the respective documentation will obviously not be build.

  ImageMagick is not strictly required, but makes inclusion of graphics in
  LaTeX documents much easier (LaTeX is a bit touchy about image formats).

  AStyle is used by the "check" test tool to enforce coding style. Again,
  not having it installed will not break things, but you will have to do
  without its benefits.

  ICU and Boost are staples of C++ development.

  The Nullsoft Scriptable Install System (NSIS) will provide your Windows
  package as executable, GUI-driven setup (as users have come to expect).

- Read through CMakeLists.txt and cmake/JAWS.cmake to get an idea of what
  is going on, and where to put in any modifications required for YOUR
  project.

- Read the CTEST section below, and do the modifications to the CTest
  script mentioned there. When you are done, run a Debug build as described
  in that section.

  Then change to the directory where your binaries have been built (that
  should be "../build/<Projectname>-Debug"), and run "options_example" /
  "options_example --help" to see Boost parameter parsing and the JAWS
  logger module at work.

  You might also give "java -jar javaexample.jar" a try. Java support is
  rudimentary, though.

- Run "make" (Unix) or "nmake" (Windows) to update your binaries if the
  sources changed. All binaries are built in the top directory; this might
  be changed to proper "./bin" and "./libs" handling in the future. Your
  documentation is built in the "./docs" subdirectory.

- Try "make help" (or "nmake help") for a list of targets, and experiment
  a bit.

- Enjoy.

===========================================================================

                                     CTEST

CTest is part of the CMake distribution, and can be used in three different
contexts:

1) In the build directory, as an interface to the test drivers. Call

      ctest -N

   for a list of available tests, and

      ctest -I <from>,<to>

   to run a range of tests.

      ctest --help

   shows a wide range of additional options.

2) Run a script-driven configure / build / test cycle. For this, go to the
   source directory of your project, and type:

      ctest -S CTestScript.cmake,Experimental

   Under the control of the file ./CTestScript.cmake, this will run an
   "Experimental" build in ../build/<Project>-Experimental. The directory
   gets deleted first, ensuring a "clean" build.

   "Experimental" means a build using the current sources. The other two
   alternatives are:

   a) "Continuous" -- Run an update on the working directory, and make a
      clean build if (and only if) there were any changes.

      This is best run at regular intervals (e.g. as a Cron job), so that
      any "breaking" commits are detected early.

   b) "Nightly" -- Runs an update on the working directory, setting it to
      a defined time stamp (usually in the middle of the night, when no
      commits are made.

      This is ideally run at a fixed time, after the time stamp defined but
      well before developers arrive in the morning so the results of the
      nightly build are available by then.

   Note that you need different working directories for each of the three
   builds, as their different update approaches would collide if run from a
   single directory.

   These builds are done in the "Release" configuration.

3) If you want to do a build under script control, similar to 2) above, but
   with a different configuration ("Debug", "Trace", "DebugTrace", ...),
   you can state the build type as option to CTestScript.cmake, instead of
   Experimental / Continuous / Nightly:

      ctest -S CTestScript.cmake,Debug

   This will run a build in ../build/<Project>-Debug, using the "Debug"
   configuration.

   No tests will be run, no results be submitted. This is a conveniance
   feature, so you can get a "binary" working directory where you can run
   debugger sessions, manual testing etc. without having to figure out the
   correct CMake command line. (Actually, with this feature it is unlikely
   that you will have to use the "cmake" command at all.)



The only adjustments you need to do in ./CTestScript.cmake are:

- Set CTEST_PROJECT_NAME "MyProject" to your project name.

- Set REPOSITORY_URL "http://127.0.0.1/MyProject/trunk" to the appropriate
  URL for your repository.

  Currently the only Version Control System supported by JAWS is SVN, as
  this is the only VCS the JAWS author needs personally, and documentation
  on this CTest feature is somewhat lacking. Support for other VCS might be
  added in the future.

- Check that the platform-specific settings done by the script and the
  CTEST_CONFIGURE_COMMAND line result in a working configuration.
  The current setup assumes that Unix builds go to /opt, and Windows builds
  to C:\Program Files (where the "icu" and "boost" installations are
  expected to reside as well).

===========================================================================

                                     CDASH

CDash is a webserver that can display the results of CTest runs (Nightly,
Continuous, and Experimental builds). CTest packs the results into XML
files, and sends them to the configured address of a CDash instance. This
configuration is done in the file ./CTestConfig.cmake:

- Adjust CTEST_PROJECT_NAME "MyProject" to your project name.

- Adjust CTEST_NIGHTLY_START_TIME "01:00:00 UTC" to match the setting in
  ./CTestScript.cmake.

- Adjust CTEST_DROP_SITE "127.0.0.1" to the domain / IP of the CDash
  instance.

- Adjust CTEST_DROP_LOCATION "/cdash/submit.php?project=MyProject" to the
  URL for your project.
