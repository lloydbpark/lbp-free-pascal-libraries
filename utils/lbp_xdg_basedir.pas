{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

lbp_xdg_basedir is a simple library which sets the XDG BaseDir folder names. It
creates the folders if they don't exist.  This allows other programs to easily
determine the full path to an XDG BaseDir folder

The XDG BaseDir documentation can be found here: 
https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html

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

unit lbp_xdg_basedir;

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

interface

uses
   lbp_types,  // lbp_exception class
   sysutils;   // DirectoryExists(), mkdir()


// *************************************************************************

var
   CacheFolder:   string;
   DataFolder:    string;
   ConfigFolder:  string;
   RuntimeFolder: string;


// *************************************************************************
// * CheckFolder() - Checks to see if the passed folder name exists and
// *                 attempts to create it if it doesn't
// *************************************************************************

procedure CheckFolder( F: string);


// *************************************************************************


implementation



// =========================================================================
// = Global functions
// =========================================================================
// *************************************************************************
// * SetFromEnvironment() - Sets the passed variable from the named 
// *                        environment variable
// *************************************************************************

procedure SetFromEnvironment( EnvVarName: string; var Value: string);
   var
      V: string = '';
   begin
      V:= GetEnvironmentVariable( EnvVarName);
      if( Length( V) > 0) then Value:= V;
   end; // SetFromEnvironment()


// *************************************************************************
// * CheckFolder() - Checks to see if the passed folder exists and attempts
// *                 to create it if it doesn't
// *************************************************************************

procedure CheckFolder( F: string);
   begin
      if( not DirectoryExists( F)) then begin
         try
            mkdir( F);
         except
            On E: EInOutError do begin
               raise lbp_exception.Create( 'Error creating XDG basedir folder ''%s!''', [F]);
            end;
         end; // try/except
      end;
   end; // CheckFolder()


// *************************************************************************
// * SetXdgBaseDirFolderNames()
// *************************************************************************

procedure SetXdgBaseDirFolderNames();
   var
      RootFolder: string;
   begin
{$ifdef UNIX} 
      RootFolder:=    GetEnvironmentVariable( 'HOME');
      CacheFolder:=   RootFolder + '/.cache';
      DataFolder:=    RootFolder + '/.local';
      CheckFolder( DataFolder);
      DataFolder:=    DataFolder + '/share';
      ConfigFolder:=  RootFolder + '/.config';
      RuntimeFolder:= RootFolder + '/.cache/runtime';
{$endif}
{$ifdef WINDOWS}
      RootFolder:=    GetEnvironmentVariable( 'APPDATA');
      CacheFolder:=   RootFolder + '\cache';
      DataFolder:=    RootFolder + '\local';
      CheckFolder( DataFolder);
      DataFolder:=    DataFolder + '\share';
      ConfigFolder:=  RootFolder + '\config';
      RuntimeFolder:= RootFolder + '\cache\runtime';
{$endif}
      
      SetFromEnvironment( 'XDG_CACHE_HOME', RuntimeFolder);
      SetFromEnvironment( 'XDG_DATA_HOME', RuntimeFolder);
      SetFromEnvironment( 'XDG_CONFIG_HOME', RuntimeFolder);
      SetFromEnvironment( 'XDG_RUNTIME_DIR', RuntimeFolder);

      CheckFolder( CacheFolder);
      CheckFolder( DataFolder);
      CheckFolder( ConfigFolder);
      CheckFolder( RuntimeFolder);
   end; // SetXdgBaseDirFolderNames()


// =========================================================================
// = Initialization and finalization
// =========================================================================
// *************************************************************************
// * initialization
// *************************************************************************

initialization
   begin
      SetXdgBaseDirFolderNames;
   end; // initialization

   
// *************************************************************************

end. // lbp_xdg_basedir unit
