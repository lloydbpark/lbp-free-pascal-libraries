{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

reads settings for a DHCP server from an INI file

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

unit lbp_dhcp_server_ini;

// This unit simply adds automatic reading of the lbp_dhcp_ini file when
//    it changes.

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}  // Non-sized Strings are ANSI strings

uses
   lbp_dhcp_ini,
   lbp_types,
   lbp_ini_files,
//   lbp_lists,
   lbp_cron,
   lbp_log;


// ************************************************************************

implementation


// ========================================================================
// = tINICron
// ========================================================================

type
   tINICron = class( tCronJob)
      public
         procedure DoEvent(); override;
      end; // tINICron


// ************************************************************************
// * DoEvent()
// ************************************************************************

procedure tINICron.DoEvent();
   begin
      if( INI.ReadIfChanged()) then begin
         Log( LOG_NOTICE, 'INI file change detected.  Reread INI.');
      end;
   end; // DoEvent()



// ========================================================================
// * Unit initialization and finalization.
// ========================================================================

var
   INICron: tINICron;

// *************************************************************************
// * Initialization
// *************************************************************************

initialization
   begin
      if( Debug_Unit_Initialization) then begin
         writeln( 'Initialization of lbp_dhcp_server_ini started.');
      end;
       if( INI <> nil) then begin
         INI.ProcStack.Enqueue( @ReadINI);
         INICron:= tINICron.Create( 0, INICheckPeriod);
      end;
      if( Debug_Unit_Initialization) then begin
         writeln( 'Initialization of lbp_dhcp_server_ini ended.');
      end;
   end; // initialization


// *************************************************************************
// * Finalization
// *************************************************************************

finalization
   begin
      if( Debug_Unit_Initialization) then begin
         writeln( 'Finalization of lbp_dhcp_server_ini started.');
      end;

      if( INI <> nil) then begin
         INICron.Destroy();
      end;

      Log( LOG_INFO, 'finishing');
      if( Debug_Unit_Initialization) then begin
         writeln( 'Finalization of lbp_dhcp_server_ini ended.');
      end;
   end; // finalization

// ************************************************************************

end. // kent_dhcp_server_ini unit
