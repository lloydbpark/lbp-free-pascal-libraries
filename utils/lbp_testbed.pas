{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Command line option to turn on testing features of a program

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

unit lbp_testbed;

// Simply uses lbp_argv to provide a --testbed flag to the command line options
// Other units such as ipdb_tables can use the testbed boolean exported by
// this unit to change their behavior.

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_argv;


// *************************************************************************

var
   testbed:        boolean = false;


// *************************************************************************

implementation   
   
// *************************************************************************
// * ParseArgV() - Parse the command line parameters
// *************************************************************************

procedure ParseArgv();
   begin
      testbed:=        ParamSet( 'testbed');

      // Locking testbed ON temporarily so we don't accidentally change production
//       testbed:= true;
//       writeln;
//       writeln( '*********************************************************');
//       writeln( '* --testbed is locked on so we don''t mess up production *');
//       writeln( '* during development of ibx_go_live!                    *');
//       writeln( '*********************************************************');
//       writeln;
   end; // ParseArgV
   

// *************************************************************************
// * Initialization - Set default connection info
// *************************************************************************

initialization
   begin
      AddUsage( '   ========== Testbed Parameters ==========');
      AddUsage( '      At least one module in this program uses one or more of the following:');
      AddParam( ['testbed'], false, '', 'Use testbed default values or change other');
      AddUsage( '                                 behavior when this parameter is present.');      AddUsage( '');
      AddPostParseProcedure( @ParseArgv);
   end; // initialization


// *************************************************************************

end. // lbp_testbed
