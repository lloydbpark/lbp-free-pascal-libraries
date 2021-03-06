{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Accepts an SSH or telnet URL on the command line and creates a command line from it.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or 
    (at your option) any later version.


    This program is distributed in the hope that it will be useful,but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU Lesser General Public 
    License along with this program.  If not, see 
    <http://www.gnu.org/licenses/>.

*************************************************************************** *}

// This program will take a URL and output a telnet or SSH command line

program ssh_url_handler;

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}
{$R-}

uses
   lbp_argv,
   lbp_url,
   lbp_run_once,
   lbp_types,
   sysutils,
   unix;

var
   ForceXTerm:  boolean = false;

   // detach from the console before starting the terminal application
   Detach:      boolean = true;  

   RGBFileName: string = '/etc/rgb.txt';
   RGBFile:     Text;

   URL:         tURL;
   Bg:          string  = 'black'; // background color - black
   Fg:          string  = 'white'; // foreground color - white
   Title:       string  = '';
   Geometry:    string  = '';

   SSH:         string  = '/usr/bin/ssh';
   Telnet:      string  = '/usr/bin/telnet';

{$IFDEF UNIX}
   XTermApp:    string  = '/usr/bin/xterm';
   TermApp:     string  = '/usr/bin/xterm';                // 0 - default
   ETermApp:    string  = '/usr/bin/Eterm';                // 1
   KDEApp:      string  = '/usr/bin/konsole';              // 2
   GnomeApp:    string  = '/usr/bin/gnome-terminal';       // 4
   MGnomeApp:   string  = '/usr/bin/multi-gnome-terminal'; // 3
   AppNum:      integer = 0;
   
   XTermFont:   string;
   
   
// ************************************************************************
// * SetUNIXVars() - Sets the UNIX variables for later user
// ************************************************************************

procedure SetUNIXVars();
   begin
      if( FileExists( ETermApp)) then begin
         AppNum:= 1;
         TermApp:= ETermApp;
      end else if( FileExists( KDEApp)) then begin
         AppNum:= 2;
         TermApp:= KDEApp;
//      end else if( FileExists( mGnomeApp)) then begin
//         AppNum:= 3;
//         TermApp:= mGnomeApp;
      end else if( FileExists( GnomeApp)) then begin
         AppNum:= 4;
         TermApp:= GnomeApp;
      end else begin
         AppNum:= 0;
      end;
      
      {$IFDEF DARWIN}
         AppNum:= -1;
         Detach:= false;
//         show_debug:= true;
      {$ENDIF}

      Geometry:= GetEnvironmentVariable( 'TGeometry');
      if( length( Geometry) = 0) then Geometry:= '80x24';
      XTermFont:= GetEnvironmentVariable( 'XTermFont');
      if( length( XTermFont) = 0) then XTermFont:= '9x15';
      
      if( show_debug) then begin
         writeln( 'AppNum   = ', AppNum);
         writeln( 'Geometry = ', Geometry);
         writeln( 'XTermFont = ', XTermFont);
      end;
   end; // SetUNIXVars() 

{$ENDIF}


// ************************************************************************
// * Usage() - Print the usage message and exit the program.
// ************************************************************************

procedure Usage();
   begin
      writeln;
      writeln;
      writeln( 'This program is meant to be called by a URL handler and ');
      writeln( 'not directly.');
      writeln;
      writeln( 'Usage:   ssh_url_handler <URL>');
      writeln;
      writeln( '          where URL = ssh://<User>@<Host>:<Port>');
      writeln( '             or URL = telnet://<User>@<Host>:<Port>');
      writeln( '  Note:   ?fg=<color>&bg=<color>&title=<window title>');
      writeln( '          may be appended to URL to change settings.');
      writeln( '          <color> can be a UNIX name or a six digit');
      writeln( '          hex color value preceded by a ''-''.');
      writeln;
      halt( 255);
   end; // Usage()


// ************************************************************************
// * UpdateTermParameters
// ************************************************************************

procedure UpdateTermParameters();
   var
      Temp: string;
   begin
      Temp:= URL.QueryFind[ 'fg'];
      if( Length( Temp) > 0) then begin
         Fg:= Temp;
         if( Fg[ 1] = '-') then Fg[ 1]:= '#';
      end;

      Temp:= URL.QueryFind[ 'bg'];
      if( Length( Temp) > 0) then begin
         Bg:= Temp;
         if( Bg[ 1] = '-') then Bg[ 1]:= '#';
      end;

      Temp:= URL.QueryFind[ 'title'];
      if( Length( Temp) > 0) then Title:= Temp;
   end; // UpdateTermParameters()


// ************************************************************************
// * HexStrToWord32() - Converts the passed hexidecimal string to a number
// ************************************************************************

function HexStrToWord32( H: string): word32;
   var
      Digit: char;
      i:     integer;
   begin
      result:= 0;
      for i:= 1 to length( H) do begin
         result:= result * 16;
         Digit:= H[ i];
         
         if( (Digit >= '0') and (Digit <= '9')) then begin
            result:= result + word32(ord( Digit) - ord( '0'));
         end else if( (Digit >= 'a') and (Digit <= 'f')) then begin
            result:= result + word32(ord( Digit) - ord( 'a') + 10);
         end else if( (Digit >= 'A') and (Digit <= 'F')) then begin
            result:= result + word32(ord( Digit) - ord( 'A') + 10);
         end else begin
            raise lbp_exception.Create( 
                'Error!  Invalid character in the Unix hex color representation');
         end; 
      end; // for
   end; // HexStrToWord32
   
   
// ************************************************************************
// * ParseHexColor() - Sets Red, Green, Blue from the passed X Windows
// *                   color definition.
// ************************************************************************

procedure ParseHexColor( XWinHex:   string;
                         var Red:   word32;
                         var Green: word32;
                         var Blue:  word32);
   begin
      if( Length( XWinHex) <> 7) then begin
         raise lbp_exception.Create(
            'Error!  Unix hex color representation must be 6 characters long!');
      end;

      Red:=   HexStrToWord32( copy( XWinHex, 2, 2));
      Green:= HexStrToWord32( copy( XWinHex, 4, 2));
      Blue:=  HexStrToWord32( copy( XWinHex, 6, 2));
   end; // ParseHexColor


// ************************************************************************
// * SkipLeadingSpaces() - increments 'i' to point to the first non white
// *                       space character in S.
// ************************************************************************

procedure SkipLeadingSpaces( S: string; var i: integer);
   var
      C:       char;
      Found:   boolean;
   begin
      // Make sure 'i' is a valid index.
      if( (i <= 0) or (i > Length( S))) then begin
         exit;
      end;

      // Find the beginning of the word
      Found:= false;
      while( (not Found) and (i <= length( S))) do begin
         c:= S[ i];
         if( (C = ' ') or (C = chr( 9))) then begin
            inc( i);
         end else begin
            Found:= true;
         end; // if
      end; // for
   end; // SkipLeadingSpaces


// ************************************************************************
// * GetWord() - Given a string and the current index into it, returns a
// *             word.
// ************************************************************************

function GetWord( S: string; var i: integer): string;
   var
      iStart:  integer;
      C:       char;
      Found:   boolean;
   begin
      // Make sure 'i' is a valid index.
      if( (i <= 0) or (i > Length( S))) then begin
         result:= '';
         exit;
      end;

      SkipLeadingSpaces( S, i);
      iStart:= i;
      
      // Find the end of the word
      Found:= false;
      while( (not found) and (i <= length( S))) do begin
         c:= S[ i];
         if( (C = ' ') or (C = chr( 9))) then begin
            Found:= true;
         end else begin
            inc( i);
         end; // if
      end; // for
      
      result:= copy( S, iStart, i - iStart);
   end; // GetWord()
   

// ************************************************************************
// * LookupInRGBtxt() - Looks up the named color in rgb.txt
// ************************************************************************

procedure LookupInRGBtxt( ColorName:  string;
                          var Red:    word32;
                          var Green:  word32;
                          var Blue:   word32);
   var
      Found: boolean;
      Line:  string;
      i:     integer;
      R:     string;
      G:     string;
      B:     string;
      N:     string;
      code:  integer;
   begin
      // try to open the RGB file if it exists
      if( FileExists( RGBFileName)) then begin
         assign( RGBFile, RGBFileName);
         reset( RGBFile);
         Found:= false;
	
         while( (not found) and (not eof( RGBFile))) do begin
            readln( RGBFile, Line);
            i:= 1;
            R:= GetWord( Line, i);
            G:= GetWord( Line, i);
            B:= GetWord( Line, i);
            SkipLeadingSpaces( Line, i);
            N:= copy( Line, i, Length( Line) - i + 1);
            Found:= (ColorName = N);
         end;
	
         if( Found) then begin
            Val( R, Red, Code);
            Val( G, Green, Code);
            Val( B, Blue, Code);
         end else begin
            raise lbp_exception.Create( 'Error!  Invalid Unix color name.');
         end;
         close( RGBFile);
      end; // If RGB file exists
   end; // LookupInRGBtxt();
   

// ************************************************************************
// * UnixToOSXColor() - Converts a UNIX color to an OSX one
// ************************************************************************

function UnixToOSXColor( UColor: string; Default: string): string;
   var
      Red, Green, Blue: word32;
      RedStr, GreenStr, BlueStr: string;
   begin
      // Set the default RGB values to black or white.
      if( Default = 'black') then begin
         Red:= 0; Green:= 0; Blue:= 0;
      end else begin
         Red:= 255; Green:= 255; Blue:= 255;
      end;

      // Try to convert UColor to RGB values
      if( UColor[ 1] = '#') then begin
         ParseHexColor( UColor, Red, Green, Blue);
      end else begin
         LookupInRGBtxt( UColor, Red, Green, Blue);
      end;

      Str( (Red   + Red   * 256), RedStr);
      Str( (Green + Green * 256), GreenStr);
      Str( (Blue  + Blue  * 256), BlueStr);
      result:= '{' + RedStr + ', ' + GreenStr + ', ' + BlueStr + '}';
   end; // UnixToOSXColor()


// ************************************************************************
// * AddParam() - Add the parameter to Param
// ************************************************************************

var
   Index:    integer;
   Param:    array of string;
   Command:  string;

procedure AddParam( Value: string);
   begin
      SetLength( Param, Index + 1);
      Param[ Index]:= Value;
      inc( Index)
   end; // AddParam()


// ************************************************************************
// * ExecAddSSHCommandParams()
// ************************************************************************

procedure ExecAddSSHCommandParams();
   var
      Temp:  string;
   begin
      if( URL.ResourceType = 'ssh') then begin
         if( Length( Command) = 0) then Command:= SSH else AddParam( SSH);
         if( URL.Port > 0) then begin
            AddParam( '-p');
            str( URL.Port, Temp);
            AddParam( Temp);
         end;
         if( Length( URL.UserName) > 0) then begin
            Temp:= URL.UserName + '@';
          end else begin
            Temp:= '';
         end;
         Temp:= Temp + URL.Host;
         AddParam( Temp);
      end else if( URL.ResourceType = 'telnet') then begin
         if( Length( Command) = 0) then Command:= Telnet else AddParam( Telnet);
         if( Length( URL.UserName) > 0) then begin
            AddParam( '-l');
            AddParam( URL.UserName);
         end;
         AddParam( URL.Host);
         if( URL.Port > 0) then begin
            str( URL.Port, Temp);
            AddParam( Temp);
         end;
      end;
   end;  // ExecAddSSHCommandParams()


// ************************************************************************
// * ExecAddXterm() - Add xterm parameters
// ************************************************************************

procedure ExecAddXterm();
   begin
      Command:= TermApp;
      AddParam( '+sb');
      AddParam( '-b');
      AddParam( '5');
      if( Length( Title) > 0) then begin
         AddParam( '-T');
         AddParam( Title);
      end;
      AddParam( '-fg');
      AddParam( Fg);
      AddParam( '-bg');
      AddParam( Bg);
      AddParam( '-fn');
      AddParam( XTermFont);
      AddParam( '-ms');
      AddParam( 'red');
      AddParam( '-geometry');
      AddParam( Geometry);
      AddParam( '-e');
   end; // ExecAddXterm()()


// ************************************************************************
// * ExecAddETerm() - Add Eterm parameters
// ************************************************************************

procedure ExecAddETerm();
   begin
      Command:= TermApp;
      if( Length( Title) > 0) then begin
         AddParam( '-T');
         AddParam( Title);
      end;
      AddParam( '-f');
      AddParam( Fg);
      AddParam( '-b');
      AddParam( Bg);
      AddParam( '-F');
      AddParam( XTermFont);
      AddParam( '--geometry');
      AddParam( Geometry);
      AddParam( '-e');
   end; // ExecAddETerm()


// ************************************************************************
// * ExecAddKonsole() - Add Konsole parameters
// ************************************************************************

procedure ExecAddKonsole();
   begin
      Command:= TermApp;
      if( Length( Title) > 0) then begin
         AddParam( '-T');
         AddParam( Title);
      end;
      AddParam( '--font');
      AddParam( XTermFont);
      AddParam( '--vt_sz');
      AddParam( Geometry);
      AddParam( '-e');
   end; // ExecAddKonsole()


// ************************************************************************
// * ExecAddMultiGnomeTerminal() - Add multi-gnome-terminal parameters
// ************************************************************************

procedure ExecAddMultiGnomeTerminal();
   begin
      Command:= TermApp;
//      if( Length( Title) > 0) then begin
//         AddParam( '--title');
//         AddParam( Title);
//      end;
      AddParam( '--foreground=');
      AddParam( Fg);
      AddParam( '--background');
      AddParam( Bg);
      AddParam( '--font');
      AddParam( XTermFont);
      AddParam( '--geometry');
      AddParam( Geometry);
      AddParam( '--command');
   end; // ExecAddMultiGnomeTerminal()


// ************************************************************************
// * ExecAddGnomeTerminal() - Add GnomeTerminal parameters
// ************************************************************************

procedure ExecAddGnomeTerminal();
   begin
      Command:= TermApp;
      if( Length( Title) > 0) then begin
         AddParam( '--title');
         AddParam( Title);
      end;
      AddParam( '--geometry');
      AddParam( Geometry);
      AddParam( '--command');
   end; // ExecAddGnomeTerminal()


// ************************************************************************
// * FixGnomeTerminalCommandLine()
// ************************************************************************

procedure FixGnomeTerminalCommandLine();
   var
      Temp:   string;
      Found:  boolean;
   begin
      Found:= false;
      Temp:= '';
      while( not Found) do begin
         dec( Index);
         if( Length( Temp) = 0) then begin
            Temp:= Param[ Index];
         end else begin
            Temp:= Param[ Index] + ' ' + Temp;
         end;
         Found:= ((Param[ Index] = SSH) or (Param[ Index] = Telnet));
      end;
      AddParam( Temp);
   end; // FixGnomeTerminalCommandLine()


// ************************************************************************
// * GetSSHString() - Returns the SSH command as a single string
// ************************************************************************

function GetSSHString(): string;
   var
      Temp:  string;
   begin
      if( URL.ResourceType = 'ssh') then begin
         result:= 'ssh ';
         if( URL.Port > 0) then begin
            str( URL.Port, Temp);
            result:= result + '-p ' + Temp + ' ';
         end;
         if( Length( URL.UserName) > 0) then begin
            result:= result + URL.UserName + '@';
         end;
         result:= result + URL.Host;
      end else if( URL.ResourceType = 'telnet') then begin
         result:= 'telnet ';
         if( Length( URL.UserName) > 0) then begin
            result:= result + '-l ' + URL.UserName + ' ';
         end;
         result:= result + URL.Host;
         if( URL.Port > 0) then begin
            str( URL.Port, Temp);
            result:= result + ' ' + temp; 
         end;
      end;
   end;  // GetSSHString()


// ************************************************************************
// * ExecAddiTerm() - Add iTerm parameters for OS X
// ************************************************************************

procedure ExecAddiTerm();
   begin
//      writeln( 'URL.UserName = ', URL.UserName);
//      writeln( 'URL.Host     = ', URL.Host);
      Command:= '/usr/bin/osascript';

// new
      AddParam( '-e');
      AddParam( 'tell application "iTerm2"');
      AddParam( '-e');
      AddParam( 'tell current window');
      AddParam( '-e');
      if( (URL.UserName  <> '') or (
             (URL.Host <> 'localhost') and (URL.Host <> '127.0.0.1'))) then begin
         AddParam( 'set myterm to (create tab with default profile command "' + GetSSHString + '")');
      end else begin
         AddParam( 'set myterm to (create tab with default profile command "/bin/bash --login")');
      end;
      AddParam( '-e');
      AddParam( 'tell myterm');
      AddParam( '-e');
      AddParam( 'set mysession to (current session)');
      AddParam( '-e');
      AddParam( 'tell mysession');
      AddParam( '-e');
      AddParam( 'set background color to ' + UnixToOSXColor( Bg, 'black'));
      AddParam( '-e');
      AddParam( 'set foreground color to ' + UnixToOSXColor( Fg, 'green'));
      if( Length( Title) > 0) then begin
         AddParam( '-e');
         AddParam( 'set name to "' + Title + '"');
      end;
      AddParam( '-e');
      AddParam( 'end tell');
      AddParam( '-e');
      AddParam( 'end tell');
      AddParam( '-e');
      AddParam( 'end tell');
      AddParam( '-e');
      AddParam( 'activate');
      AddParam( '-e');
      AddParam( 'end tell');
   end; // ExecAddiTerm()


// ************************************************************************
// * Exec() - Execute the command
// ************************************************************************

procedure Exec();
   var
      Temp:  string; // used by debug code
      F:     text;
   begin
      Index:= 0;

      if( ForceXTerm) then begin
         AppNum:= 0;
         TermApp:= XtermApp;
      end;

      case AppNum of
         0: ExecAddXterm();
         1: ExecAddETerm();
         2: ExecAddKonsole();
         3: ExecAddMultiGnomeTerminal();
         4: ExecAddGnomeTerminal();
      end;
      
     if( AppNum >= 0) then begin
        // Linux / UNIX 
        ExecAddSSHCommandParams();
     end else begin
        // OS X
        ExecAddiTerm();
     end;

      if( AppNum = 4) then FixGnomeTerminalCommandLine();

      if( show_debug) then begin
         assign( F, 'url_handler.sh');
         rewrite( F);
         
//         writeln( 'Command = ', Command);
         Temp:= Command;
         for Index:= 0 to Length( Param) - 1 do begin
//            writeln( 'Param[ ', Index, '] = ', Param[ Index]);
            Temp:= Temp + ' ''' + Param[ Index] + '''';
         end;
         writeln( F, Temp);
         flush( F);
         close( F);
      end else begin
         try
            if( Detach) then begin
               Daemonize();
            end;
         except
            On E: DaemonizeOKException do begin
               // Parent process
               Halt;
            end;
         end; // try/except

         fpExecL( Command, Param);
      end;
   end; // Exec()


// ************************************************************************
// * main()
// ************************************************************************

begin
   ParseParams;

   {$IFDEF UNIX}
      SetUNIXVars();
   {$ENDIF}

   if( Length( UnnamedParams) = 1) then begin
      try
         URL:= tURL.Create( UnnamedParams[ 0]);
      except
         on E: URLException do begin
            writeln( E.Message);
            Usage();
         end
      end // Try/except
   end else begin
      Usage();
   end;

   UpdateTermParameters();
   Exec();

   URL.Destroy();
end. // ssh_url_handler
