{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Parse URLs.

This file is part of Lloyd's Free Pascal Libraries (LFPL).

    LFPL is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation, either version 2.1 of the 
    License, or (at your option) any later version with the following 
    modification:

    As a special exception, the copyright holders of this library 
    give you permission to link this library with independent modules
    to produce an executable, regardless of the license terms of these
    independent modules, and to copy and distribute the resulting 
    executable under terms of your choice, provided that you also meet,
    for each linked independent module, the terms and conditions of 
    the license of that module. An independent module is a module which
    is not derived from or based on this library. If you modify this
    library, you may extend this exception to your version of the 
    library, but you are not obligated to do so. If you do not wish to
    do so, delete this exception statement from your version.

    LFPL is distributed in the hope that it will be useful,but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General 
    Public License for more details.

    You should have received a copy of the GNU Lesser General Public 
    License along with LFPL.  If not, see <http://www.gnu.org/licenses/>.

*************************************************************************** *}

{$WARNING This unit can be replaced by Free Pascal's built in libraries}
{$WARNING Specifically, use URIParser ParseURI() and EncodeURI}
{$WARNING https://www.freepascal.org/docs-html/current/fcl/uriparser/turi.html
// ========================================================================
// = The unit defines a URL class which parses a URL to it's component 
// = parts and assembles the components into a URL
// ========================================================================

unit lbp_url;


interface

{$include lbp_standard_modes.inc}

uses
   lbp_types,
   lbp_utils,  // lbp_exceptions
   lbp_name_value_pair_trees, 
   sysutils;    // Exceptions

type
   URLException = class( lbp_exception);


// ************************************************************************
// * tURL Class
// ************************************************************************
type 
   tURL = class
      private
         Delimiters:     set of char;
         MyResourceType: string;
         MyUserName:     string;
         MyPassword:     string;
         MyHost:         string;
         MyPort:         word32;
         MyPath:         string;
         MyQueryString:  string;
         MyAnchor:       string;
         QueryTree:      tNameValuePairTree;
      public
         constructor  Create( URLstring: string);
         destructor   Destroy(); override;
         procedure    Clear();  // Clears all components
         procedure    Dump();   // Write all components values to stdout
      private
         function     GetField( URL: string; var Indx: integer; 
                                var Delimiter: char ): string; 
         procedure    ParseString( URLstring: string);
         procedure    ParseQuery(); 
         function     ToString(): string;
         function     GetQueryValue(): string;
         function     GetQueryFind( VarName: string): string;
         // Get QueryString variable names
         function     GetFirstQuery():    string;
         function     GetLastQuery():     string;
         function     GetNextQuery():     string;
         function     GetPreviousQuery(): string;
      public
         property  ResourceType: string read MyResourceType write MyResourceType;
         property  UserName:     string read MyUserName     write MyUserName;
         property  Password:     string read MyPassword     write MyPassword;
         property  Host:         string read MyHost         write MyHost;
         property  Port:         word32 read MyPort         write MyPort;
         property  Path:         string read MyPath         write MyPath;
         property  QueryString:  string read MyQueryString  write MyQueryString;
         property  QueryFind[ VarName: string]: string read GetQueryFind;
         property  QueryValue:   string read GetQueryValue;
         property  Anchor:       string read MyAnchor       write MyAnchor;
         property  AsString:     string read ToString       write ParseString;
      end; // URL class


// ************************************************************************

implementation

var
   AllDelimiters:   set of char = [ ':', '@', '?', '#', '/'];
   MostDelimiters:  set of char = [ ':', '@', '?', '#'];

Const
   NullChr = chr(0);
   SingleSlash = chr( 1);
   DoubleSlash = chr( 2);


// ========================================================================
// = tURL Class
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tURL.Create( URLstring: string);
   begin
      Clear();
      ParseString( URLstring);
   end; // Create()


// ************************************************************************
// * Destroy() - Destructor
// ************************************************************************

destructor  tURL.Destroy();
   begin
      if( QueryTree <> nil) then begin
         QueryTree.RemoveAll( True);
         QueryTree.Destroy();
      end;
   end; // Destroy()


// ************************************************************************
// * Clear() - Clears all componets
// ************************************************************************

procedure tURL.Clear();
   begin
      ResourceType:= '';
      UserName:=     '';
      Password:=     '';
      Host:=         '';
      Port:=         0;
      Path:=         '';
      QueryString:=  '';
      QueryTree:=    nil;
      Anchor:=       '';
     Delimiters:=    AllDelimiters;
   end; // Clear()


// ************************************************************************
// * GetField() - Reads the next field from the URL. Returns the field,
// *              the Delimiter that ended the field, and updates Indx.
// ************************************************************************

function tURL.GetField( URL: string; var Indx: integer; 
                        var Delimiter: char ): string; 
   var
      iStart: integer;
   begin
      iStart:= Indx;
      while( (Indx <= Length(URL)) and not (URL[ Indx] in Delimiters)) do begin
         inc( Indx);
      end;

      result:= copy( URL, iStart, Indx - iStart);

      if( Indx <= Length( URL)) then begin 
         Delimiter:= URL[ Indx];
      end else begin
         Delimiter:= chr( 0);
      end; 

      // Step past the delimiter
      inc( Indx);

      // Check for slash or double slash
      if( Delimiter = '/') then begin
         // Double slash?
         if( (Indx <= Length(URL)) and (URL[ Indx] = '/')) then begin
            inc( Indx);
            Delimiter:= DoubleSlash;
         end else begin
            // single slash
            Delimiters:= MostDelimiters;
            dec( Indx);
            Delimiter:= SingleSlash;
         end;
      end;
   end; // GetField()


// ************************************************************************
// * ParseString() - Parses URLstring to its components.  It overlays the
// *                 existing values of components.  So a relative URL will
// *                 will keep the previous URL's hostname, etc.
// ************************************************************************

procedure tURL.ParseString( URLstring: string);
   var
      Delimiter:         char;
      PreviousDelimiter: char;
      Temp1:             string;
      Temp2:             string;
      Indx:              integer;
      Code:              integer;
      DoubleSlashSeen:   boolean;
      UserNameSeen:      boolean;
      HostSeen:          boolean;
      QueryStringSeen:   boolean;
      AnchorSeen:        boolean;
   begin
      if( show_debug) then writeln( 'lbp_url.tURL.ParseString(): begin');
      Indx:=               1;
      DoubleSlashSeen:=    false;
      UserNameSeen:=       false;
      HostSeen:=           false;
      QueryStringSeen:=    false;
      AnchorSeen:=         false;
      PreviousDelimiter:=  NullChr;

      Delimiters:=         AllDelimiters;
      repeat
         Temp1:= GetField( URLString, Indx, Delimiter);
         if( Delimiter = ':') then begin
            Temp2:= GetField( URLString, Indx, Delimiter);
         end else begin
            Temp2:= '';
         end;

         // Components which are identified by the starting delimiter
         case PreviousDelimiter of
            SingleSlash: Path:= Temp1;
            '?': begin
                  if( QueryStringSeen) then begin
                     raise URLException.Create( 
                          'More than one Query String was specified!');
                  end;
                  QueryString:= Temp1;
                  QueryStringSeen:= true;
                  ParseQuery();
               end; // '?'
            '#': begin
                  if( AnchorSeen) then begin
                     raise URLException.Create( 
                          'More than one Anchor was specified!');
                  end;
                  Anchor:= Temp1;
                  AnchorSeen:= true;
               end; // '?'
         end; // case

         // Components which are identified by the ending delimiter
         case Delimiter of
            DoubleSlash: begin
                  if( DoubleSlashSeen) then begin
                     raise URLException.Create( 
                          'More than one Resouce Type was specified!');
                  end;
                  ResourceType:= Temp1;
                  DoubleSlashSeen:= true;
               end; // DoubleSlash
            '@': begin
                  if( UserNameSeen) then begin
                     raise URLException.Create( 
                          'More than one User Name / Password was specified!');
                  end;
                  UserName:= Temp1;
                  Password:= Temp2;
                  UserNameSeen:= true;
               end; // '@'
            NullChr, SingleSlash, '?', '#': if( not HostSeen) then begin
                  HostSeen:= true;
                  Host:= Temp1;
                  if( Temp2 <> '') then begin
                     Val( Temp2, MyPort, Code); 
                     if( Code > 0) then begin
                        raise URLException.Create( 
                             'Invalid Port number!  ' + URLString);
                     end;
                  end; // If their was a port number
               end; // SingleSlash, '?', '#'
         end; // case
         PreviousDelimiter:= Delimiter;
      until( Delimiter = NullChr);
      if( show_debug) then writeln( 'lbp_url.tURL.ParseString(): end');
   end; // ParseString()


// ************************************************************************
// * ToString() - Convert the component parts to a URL
// ************************************************************************

function tURL.ToString(): string;
   var
      Temp:      string;
      PortStr:   string;
   begin
      Temp:= '';
      PortStr:= '';
      if( Length( ResourceType) <> 0) then begin
         Temp:= Temp + ResourceType + '://';
      end; 
      if( Length( UserName    ) <> 0) then begin
         Temp:= Temp + UserName;
         if( Length( Password) <> 0) then begin
            Temp:= Temp + ':' + Password;
         end;
         Temp:= Temp + '@';
      end; 
      if( Length( Host) <> 0) then begin
         Temp:= Temp + Host;
      end;
      if( Port <> 0) then begin
         Str( Port, PortStr);
         Temp:= Temp + ':' + PortStr;
      end;
      if( Length( Path) <> 0) then begin
         Temp:= Temp + Path;
      end;
      if( Length( QueryString) <> 0) then begin
         Temp:= Temp + '?' + QueryString;
      end;
      if( Length( Anchor) <> 0) then begin
         Temp:= Temp + '#' + Anchor;
      end;

      result:= Temp;
   end; // ToString()


// ************************************************************************
// * Dump() - Debug procedure - Writes the URL string and then the 
// *          component parts one per line to stdout.
// ************************************************************************

procedure tURL.Dump();
   var
      TempName: string;
   begin
      writeln( AsString);
      writeln( '     Resource Type = ', ResourceType);
      writeln( '     UserName      = ', UserName);
      writeln( '     Password      = ', Password);
      writeln( '     Host          = ', Host);
      writeln( '     Port          = ', Port);
      writeln( '     Path          = ', Path);
      writeln( '     Query String  = ', QueryString);
      if( QueryTree <> nil) then begin
         TempName:= QueryTree.GetFirst();
         while( Length( TempName) > 0) do begin
            writeln( '          ', TempName, ' = ', QueryTree.Value);
            TempName:= QueryTree.GetNext();
         end;
      end;
      writeln( '     Anchor        = ', Anchor);
   end; // Dump()


// ************************************************************************
// * ParseQuery()
// ************************************************************************

procedure tURL.ParseQuery();
   var
      TempName:  string;
      TempValue: string;
      i:         integer;
      iStart:    integer;
      L:         integer; // Length of the QueryString
   begin
      TempName:= '';
      TempValue:= '';
      L:= Length( QueryString);
      i:= 1;
      while( i <= L) do begin

         // Get the variable's name
         iStart:= i;
         while( (i <= L) and (QueryString[ i] <> '=')) do inc( i);
         TempName:= copy( QueryString, iStart, i - iStart);
         inc( i); // Get past the '='

         // Get the variable's value
         iStart:= i;
         while( (i <= L) and (QueryString[ i] <> '&')) do inc( i);
         TempValue:= copy( QueryString, iStart, i - iStart);
         inc( i); // Get past the '&'

         // If we have a valid name and value, then add it to our tree.
         if( (Length( TempValue) > 0) and (Length( TempName) > 0)) then begin
            if( QueryTree = nil) then begin
               QueryTree:= tNameValuePairTree.Create( false);
            end;
            QueryTree.Add( TempName, TempValue);
         end;
      end; // While
   end; // ParseQuery();


// ************************************************************************
// * GetQueryValue() - Returns the value of the current query variable.
// ************************************************************************

function tURL.GetQueryValue(): string;
   begin
      if( QueryTree = nil) then begin
         result:= '';
      end else begin
         result:= QueryTree.Value;
      end;
   end; // GetQueryValue()


// ************************************************************************
// * GetQueryFind() - Returns the value of the named query variable.
// *                   Returns the empty string if the variable doesn't 
// *                   exist.
// ************************************************************************

function tURL.GetQueryFind( VarName: string): string;
   begin
      if( QueryTree = nil) then begin
         result:= '';
      end else begin
         result:= QueryTree.Find( VarName);
      end;
   end; // GetQueryFind()


// ************************************************************************
// * GetFirstQuery() - Returns the first URL Query String variable name.
// ************************************************************************

function tURL.GetFirstQuery():    string;
   begin
      if( QueryTree = nil) then begin
         result:= '';
      end else begin
         result:= QueryTree.GetFirst();
      end;
   end; // GetFirstQuery();


// ************************************************************************
// * GetFirstQuery() - Returns the next URL Query String variable name.
// ************************************************************************

function tURL.GetLastQuery():     string;
   begin
      if( QueryTree = nil) then begin
         result:= '';
      end else begin
         result:= QueryTree.GetLast();
      end;
   end; // GetLastQuery();


// ************************************************************************
// * GetNextQuery() - Returns the next URL Query String variable name.
// ************************************************************************

function tURL.GetNextQuery():     string;
   begin
      if( QueryTree = nil) then begin
         result:= '';
      end else begin
         result:= QueryTree.GetNext();
      end;
   end; // GetNextQuery();


// ************************************************************************
// * GetPreviousQuery() - Returns the previous URL Query String variable 
// *                      name.
// ************************************************************************

function tURL.GetPreviousQuery(): string;
   begin
      if( QueryTree = nil) then begin
         result:= '';
      end else begin
         result:= QueryTree.GetPrevious();
      end;
   end; // GetPreviousQuery();


// ************************************************************************

end. // lbp_url unit
