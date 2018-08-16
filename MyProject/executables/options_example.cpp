#include "MyProject/core/Constants.h"

#include <boost/program_options.hpp>

#include <sstream>
#include <vector>
#include <string>
#include <iostream>

namespace po = boost::program_options;

/**
 * This is a quick example on how Boost.Program_options can be used to parse
 * a command line. Basically the tutorial code from the Boost docs put into
 * a ready-to-compile source file. Check out the Boost documentation for
 * further options and explanations.
 */
int main( int argc, char * argv[] )
{
    int opt;
    po::variables_map vm;

    try
    {
        // Positional parameter
        po::positional_options_description p_desc;
        p_desc.add( "input-file", -1 );
        po::options_description desc( dynamic_cast< std::ostringstream & >( std::ostringstream()
                                      << std::dec
                                      << "JAWS example for Boost.Program_options " << MYPROJECT_VERSION_MAJOR
                                      << "." << MYPROJECT_VERSION_MINOR
                                      << "\nAllowed options" ).str() );
        desc.add_options()
        // Flag option (either it is given or not)
        ( "help,h", "Print this help message and exit" )
        // Numerical option
        ( "number,n", po::value<int>(), "Numerical value" )
        // Numerical option, written to variable, with default value
        ( "optimization,O", po::value<int>( &opt )->default_value( 0 ), "Optimization level" )
        // String option, can be given multiple times
        ( "include-path,I", po::value< std::vector< std::string > >(), "Include path(s)" )
        // String option, can be given mutliple times, with or without the option name
        // (because it is a positional option, see p_desc above)
        ( "input-file", po::value< std::vector< std::string > >(), "Input file(s)" )
        ;
        po::store( po::command_line_parser( argc, argv ).options( desc ).positional( p_desc ).run(), vm );
        po::notify( vm );

        if ( vm.count( "help" ) )
        {
            std::cout << desc << "\n";
            return 0;
        }
    }
    catch ( std::exception & e )
    {
        std::cerr << e.what();
        return 1;
    }

    if ( vm.count( "number" ) )
    {
        std::cout << "Numerical value given as " << vm["number"].as<int>() << "\n";
    }
    else
    {
        std::cout << "Numerical value not given." << "\n";
    }

    if ( vm.count( "optimization" ) )
    {
        std::cout << "Optimization level is " << opt << "." << "\n";
    }
    else
    {
        std::cout << "Optimization level defaults to " << opt << "\n";
    }

    if ( vm.count( "include-path" ) )
    {
        std::vector< std::string > include_path = vm["include-path"].as< std::vector< std::string > >();

        for ( size_t n = 0; n < include_path.size(); ++n )
        {
            std::cout << "Include path " << n << ": " << include_path[n] << "\n";
        }
    }
    else
    {
        std::cout << "No include path given." << "\n";
    }

    if ( vm.count( "input-file" ) )
    {
        std::vector< std::string > input_file = vm["input-file"].as< std::vector< std::string > >();

        for ( size_t n = 0; n < input_file.size(); ++n )
        {
            std::cout << "Input file " << n << ": " << input_file[n] << "\n";
        }
    }
    else
    {
        std::cout << "No input file given." << "\n";
    }

    return 0;
}
