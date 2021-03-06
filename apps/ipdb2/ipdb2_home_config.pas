{* ***************************************************************************

Copyright (c) 2020 by Lloyd B. Park

ipdb2_home_config stores and retrieves IPdb2 settings  It stores the settings
in the ipdb2_tables unit.

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

unit ipdb2_home_config;

interface

{$include lbp_standard_modes.inc}
//{$V-}    //Added by LP because it says so below
//{$R-}    //Range checking off
//{$S-}    //Stack checking off
//{$I-}    //I/O checking off
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   lbp_argv,
   lbp_types,     // lbp_exception
   lbp_testbed,
   lbp_xdg_basedir,
   lbp_ini_files,
   lbp_sql_db,   // SQLCriticalException
   ipdb2_tables, // 
   sysutils;     // Exceptions, DirectoryExists, mkdir, etc
   

// ************************************************************************
// * Global variables
// ************************************************************************

// var
//    ipdb2_home_database:  string;
//    ipdb2_home_host:      string;
//    ipdb2_home_port:      string;
//    ipdb2_home_user:      string;
//    ipdb2_home_password:  string;



// *************************************************************************

implementation

// -------------------------------------------------------------------------
// - Global functions
// -------------------------------------------------------------------------

var
   ini_file_name: string;
   ini_file:      IniFileObj;
   ini_section:   string;

// *************************************************************************
// * ReadIni() - Set the ini_file_name, read the file and set the global
// *             variables.
// *************************************************************************

procedure ReadIni();
   var
      ini_folder:  string;
      F:           text;
      S:           string; // Port string to number conversion
      Code:        word;
   begin
      // Set the ini_file_name and create the containing folders as needed.
      ini_folder:= lbp_xdg_basedir.ConfigFolder + DirectorySeparator + 'lbp';
      CheckFolder( ini_folder);
      ini_folder:= ini_folder + DirectorySeparator + 'ipdb2-home';
      CheckFolder( ini_folder);
      ini_file_name:= ini_folder + DirectorySeparator + 'ipdb2-home.ini';
      
      // Create a new ini file with empty values if needed.
      if( not FileExists( ini_file_name)) then begin
         if( lbp_types.show_init) then begin
            writeln( '   ReadIni(): No configuration file found.  Creating a new one.');
         end;
         assign( F, ini_file_name);
         rewrite( F);
         writeln( F, '[main]');
         writeln( F, 'ipdb2_home_database=');
         writeln( F, 'ipdb2_home_host=');
         writeln( F, 'ipdb2_home_port=');
         writeln( F, 'ipdb2_home_user=');
         writeln( F, 'ipdb2_home_password=');
         writeln( F, '[testbed]');
         writeln( F, 'ipdb2_home_database=');
         writeln( F, 'ipdb2_home_host=');
         writeln( F, 'ipdb2_home_port=');
         writeln( F, 'ipdb2_home_user=');
         writeln( F, 'ipdb2_home_password=');
         close( F);
      end;

      // Now we can finally read the ini file
      if( lbp_testbed.Testbed) then ini_section:= 'testbed' else ini_section:= 'main';
      ini_file:= IniFileObj.Open( ini_file_name, true);
      DefaultDatabase:= ini_file.ReadVariable( ini_section, 'ipdb2_home_database');
      DefaultHost:=     ini_file.ReadVariable( ini_section, 'ipdb2_home_host');
      S:=               ini_file.ReadVariable( ini_section, 'ipdb2_home_port');
      Val( S, DefaultPort, Code);
      DefaultUser:=     ini_file.ReadVariable( ini_section, 'ipdb2_home_user');
      DefaultPassword:= ini_file.ReadVariable( ini_section, 'ipdb2_home_password');
      Val( S, DefaultPort, Code);
   end; // ReadIni()


// *************************************************************************
// * ParseArgV() - Parse the command line parameters
// *************************************************************************

procedure ParseArgv();
   var
      Port: longint = 0;
      Temp: string;
   begin
      if( lbp_types.show_init) then writeln( 'ipdb2_home_config.ParseArgv(): begin');
      
      ReadIni();

      ParseHelper( 'ipdb2-home-database', DefaultDatabase);
      ParseHelper( 'ipdb2-home-host',     DefaultHost);
      Port:= DefaultPort;
      ParseHelper( 'ipdb2-home-port',     Port);
      DefaultPort:= word( Port);
      ParseHelper( 'ipdb2-home-user',     DefaultUser);
      ParseHelper( 'ipdb2-home-password', DefaultPassword);

      // Test for missing variables
      if( (Length( DefaultDatabase) = 0) or
          (Length( DefaultHost) = 0) or
          (DefaultPort = 0) or
          (Length( DefaultUser) = 0) or
          (Length( DefaultPassword) = 0)) then begin
         raise SQLdbCriticalException.Create( 'Some ipdb2-home SQL settings are empty!  Please try again with all parameters set.');

      end;

      if( ParamSet( 'ipdb2-home-save')) then begin
         ini_file.SetVariable( ini_section, 'ipdb2_home_database', DefaultDatabase);
         ini_file.SetVariable( ini_section, 'ipdb2_home_host',     DefaultHost);
         Str( DefaultPort, Temp);
         ini_file.SetVariable( ini_section, 'ipdb2_home_port',     Temp);
         ini_file.SetVariable( ini_section, 'ipdb2_home_user',     DefaultUser);
         ini_file.SetVariable( ini_section, 'ipdb2_home_password', DefaultPassword);
         ini_file.write();
      end; 
      ini_file.close();

      if( lbp_types.show_init) then writeln( 'ipdb2_home_config.ParseArgv(): end');
   end; // ParseArgV


// *************************************************************************
// * Initialization - Set default connection info
// *************************************************************************

initialization
   begin
      if( lbp_types.show_init) then writeln( 'ipdb_home_config.initialization:  begin');
      // Add Usage messages
      AddUsage( '   ========== IP Database Parameters ==========');
      AddParam( ['ipdb2-home-host'], true, '', 'The SQL server');
      AddParam( ['ipdb2-home-port'], true, '', 'The TCP port');
      AddParam( ['ipdb2-home-user'], true, '', 'The database user name');
      AddParam( ['ipdb2-home-password'], true, '', 'The password');
      AddParam( ['ipdb2-home-database'], true, '', 'The database name');
      AddParam( ['ipdb2-home-save'], False, '', 'Save youor changes to the ipdb2-home settings');
      AddUsage( '   --testbed                   Set/retrieve the testbed rather than the');
      AddUsage( '                                 production IPdb MySQL connection settings.');
      AddUsage( '');
      AddPostParseProcedure( @ParseArgv);
      if( lbp_types.show_init) then writeln( 'ipdb_home_config.initialization:  end');
   end; // initialization


// *************************************************************************

end. // ipdb2_home_config unit
