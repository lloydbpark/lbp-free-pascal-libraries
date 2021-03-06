{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

change the host name, root directory, and/or the user of a CVS directory tree.

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

program cvs_move_root;

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_types,
   lbp_file_directory;


var
   CVSType: string = '';
   CVSUser: string = '';
   CVSHost: string = '';
   CVSDir:  string = '';


// =========================================================================
// = Global functions
// =========================================================================
// *************************************************************************
// * BackCopyTill() - Called by SplitCVSRoot()  
// *                - Copies from i downwards until the first character is
// *                - reached or LookFor is found
// *************************************************************************

function BackCopyTill( const Source:  string; 
                       var   i:       integer; 
                       const LookFor: char): string;
   var
      Temp: string;
   begin
      Temp:= '';
      while( (i > 0) and (Source[ i] <> LookFor)) do begin
         Temp:= Source[ i] + Temp;
         dec( i);
      end;
      result:= temp;
   end; // BackCopyTill()


// *************************************************************************
// * SplitCVSRoot - Split CVS Root into it's components
// *************************************************************************

procedure SplitCVSRoot( const RootStr: string;
                        var   CVSType: string;
                        var   CVSUser: string;
                        var   CVSHost: string;
                        var   CVSDir:  string);
   var
      i: integer;
   begin
      i:= Length( RootStr);
      CVSDir:= BackCopyTill( RootStr, i, ':');
      if( i > 0) then dec( i);
      CVSHost:= BackCopyTill( RootStr, i, '@');
      if( i > 0) then dec( i);
      CVSUser:= BackCopyTill( RootStr, i, ':');
      if( i > 0) then dec( i);
      CVSType:= BackCopyTill( RootStr, i, ':');
   end; // SplitCVSRoot()


// *************************************************************************
// * FixCVSRoot() - update the data in .../CVS/Root
// *************************************************************************

procedure FixCVSRoot( const Directory: string);
   var
      R: Text;
      S: string;
      cType: string;
      cUser: string;
      cHost: string;
      cDir:  string;
   begin
      writeln( '   Processing ', Directory, '/Root');
      assign( R, Directory + '/Root');
      reset( R);
      Readln( R, S);
      close( R);

      writeln( '      Original CVS Root = ', S);

      SplitCVSRoot( S, cType, cUser, cHost, cDir);

      if( length( CVSType) > 0) then begin
         cType:= CVSType;
      end;
      if( length( CVSUser) > 0) then begin
         cUser:= CVSUser;
      end;
      if( length( CVSHost) > 0) then begin
         cHost:= CVSHost;
      end;
      if( length( CVSDir) > 0) then begin
         cDir:= CVSDir;
      end;


      if( Length( cType) > 0) then begin
         S:= ':' + cType + ':';
         if( Length( cUser) > 0) then begin
            S:= S + cUser + '@';
         end;
         S:= S + cHost + ':';
      end;
      S:= S + cDir;

      rewrite( R);
      writeln( R, S);
      close( R);

      writeln( '      New CVS Root      = ', S);
   end; // FixCVSRoot()


// *************************************************************************
// * ProcessDirectory() - Process a single directory
// *************************************************************************

procedure ProcessDirectory( const StartDirectory: string);
   var
      D:   tFileInfoClass;
   begin
      D:= tFileInfoClass.Create( StartDirectory);
      while( D.Next) do begin
         if( D.IsDirectory and (D.Name <> '.') and (D.Name <> '..')) then begin
            if( D.Name = 'CVS') then begin      
               FixCVSRoot( D.FullName);
            end else begin
               ProcessDirectory( D.FullName);
            end;
         end; // if directory
      end; // while (for each file in the directory)
      D.Destroy();
   end; // ProcessDirectory()


// *************************************************************************
// * Usage() - Print a usage message and exit
// *************************************************************************

procedure Usage();
   begin
      writeln; writeln;
      writeln( 'usage:  cvs_move_root [-h host] [-u user] [-d directory]');
      writeln;
      writeln( '        You must enter at least one of -h, -u, -d.');
      writeln( '        -h  Host name of the CVS server');
      writeln( '        -u  User account on the CVS server');
      writeln( '        -d  Root CVS directory on the CVS server');
      writeln; writeln;
      halt;
   end; // Usage();


// *************************************************************************
// * GetParameters();
// *************************************************************************

procedure GetParameters();
   var
      i:        integer;
      Value:    string;
      Name:     string;
   begin
      i:= 1;
      if( ((ParamCount mod 2) <> 0) or (ParamCount = 0)) then begin
         Usage();
      end;

      while( i <= ParamCount) do begin
         Name:= ParamStr( i);
         inc( i);
         Value:= ParamStr( i);
         inc( i);
         if( Name = '-h') then begin
            CVSHost:= Value;
         end else if( Name = '-u') then begin
            CVSUser:= Value;
         end else if( Name = '-d') then begin
            CVSDir:= Value;
         end else begin
            usage;
         end;
      end;

      if( length( CVSHost) > 0) then begin
         CVSType:= 'ext';
      end;
   end; // GetParameters;


// *************************************************************************
// * main()
// *************************************************************************

var
   StartDirectory:  string;

begin
   GetParameters;

   GetDir( 0, StartDirectory);
   ProcessDirectory( StartDirectory);
end.  // cvs_move_root program
