// For compilers supporting precompiled headers
#include <wx/wxprec.h>

#ifndef WX_PRECOMP
// If precompiled headers are not supported, this pulls in the most
// commonly used headers in one go.
#include <wx/wx.h>
#endif

// Deriving from wxApp and overriding OnInit() is how you / set up a
// wxWidgets application -- somewhat skin to the main() of a console
// app.
class MyApp : public wxApp
{
    public:
        virtual bool OnInit();
};

// Any wxWidgets application requires a top-level wxFrame or wxDialog.
class MyFrame : public wxFrame
{
    public:
        MyFrame( const wxString & title );

    private:
        // Event handlers, attached to event keys via the event table
        // below.
        void OnQuit( wxCommandEvent & event );
        void OnAbout( wxCommandEvent & event );
        void OnButton1( wxCommandEvent & event );
        void OnButton2( wxCommandEvent & event );

        // Declare intention to handle user events -- wxWidgets will
        // add the necessary plumbing here.
        wxDECLARE_EVENT_TABLE();
};

enum
{
    ID_Quit = wxID_EXIT,
    ID_About = wxID_ABOUT,
    ID_Button1 = 1,
    ID_Button2
};

// Attaching event handler functions to specific event IDs of a specific
// wxFrame class.
wxBEGIN_EVENT_TABLE( MyFrame, wxFrame )
    EVT_MENU( ID_Quit, MyFrame::OnQuit )
    EVT_MENU( ID_About, MyFrame::OnAbout )
    EVT_MENU( ID_Button1, MyFrame::OnButton1 )
    EVT_MENU( ID_Button2, MyFrame::OnButton2 )
wxEND_EVENT_TABLE()

// Declaring the entry point for the application.
wxIMPLEMENT_APP( MyApp );

bool MyApp::OnInit()
{
    // Base class initialization
    if ( !wxApp::OnInit() )
    {
        return false;
    }

    // Adding a top-level wxFrame to the app
    MyFrame * frame = new MyFrame( "Hello World" );
    frame->Show( true );

    return true;
}

MyFrame::MyFrame( const wxString & title )
    : wxFrame( NULL, wxID_ANY, title )
{
    // Help Menu
    wxMenu * helpMenu = new wxMenu;
    helpMenu->Append( ID_About /*, "&About...\tF1", "Show about dialog" */ );

    // File Menu
    wxMenu * fileMenu = new wxMenu;
    fileMenu->Append( ID_Quit /*, "E&xit\tAlt-X", "Quit this program" */ );

    // Menu Bar, with the two menues appended
    wxMenuBar * menuBar = new wxMenuBar;
    menuBar->Append( fileMenu, "&File" );
    menuBar->Append( helpMenu, "&Help" );

    SetMenuBar( menuBar );

    wxSizer * sizer = new wxBoxSizer( wxVERTICAL );

    sizer->Add( new wxButton( this, ID_Button1, "Button 1" ) );
    sizer->Add( new wxButton( this, ID_Button2, "Button 2" ) );
    SetSizerAndFit( sizer );

#if wxUSE_STATUSBAR
    // Status Bar
    CreateStatusBar( 2 );
    SetStatusText( "Welcome to wxWidgets!" );
#endif

    // Not shown: wxToolbar, wxIcon, wxControl (wxButton, wxCheckbox,
    //            wxChoice, wxListbox, wxRadioBox, wxSlider)
}

void MyFrame::OnQuit( wxCommandEvent & WXUNUSED( event ) )
{
    Close( true );
}

void MyFrame::OnAbout( wxCommandEvent & WXUNUSED( event ) )
{
    wxMessageBox( wxString::Format(
                      "Welcome to %s!\n"
                      "Minimal wxWidgets sample\n"
                      "running under %s.",
                      wxVERSION_STRING,
                      wxGetOsDescription().c_str()
                  ),
                  "About wxWidgets minimal sample",
                  wxOK | wxICON_INFORMATION,
                  this
                );
}

void MyFrame::OnButton1( wxCommandEvent & WXUNUSED( event ) )
{
    wxMessageBox( "Button 1 pressed.", "Button event", wxOK | wxICON_INFORMATION, this );
}

void MyFrame::OnButton2( wxCommandEvent & WXUNUSED( event ) )
{
    wxMessageBox( "Button 2 pressed.", "Button event", wxOK | wxICON_INFORMATION, this );
}
