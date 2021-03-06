{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

<brief description of the file.  for exampl: Definition of common types>

Reads the settings for a DHCP server from an INI file.

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

unit lbp_dhcp_ini;

// Reads and stores INI file variables for the DHCP programs

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}  // Non-sized Strings are ANSI strings

uses
   lbp_types,
   lbp_ini_files,
   lbp_log,
   lbp_dhcp_fields;  // so we can set the default lease


var
   DebugServerOutput:   boolean;
   DebugServerInput:    boolean;
   DebugServerIgnore:   boolean;
   LogServerOutput:     boolean;
   LogServerInput:      boolean;
   LogServerErrors:     boolean;
   LogServerInvalid:    boolean;
   LogLookupProgress:   boolean;
   LogLookupErrors:     boolean;
   LogINIReads:         boolean;
   LogSocket:           boolean;   // Socket Read and write
   LogTimeStamp:        boolean;

   LeaseFile:           string;
   StdLease:            integer;
   StdLeaseHrs:         integer;
   StdLeaseMins:        integer;
   StdLeaseSecs:        integer;
   DynLease:            integer;
   DynLeaseHrs:         integer;
   DynLeaseMins:        integer;
   DynLeaseSecs:        integer;

   GrantLongLeases:     boolean;
   StaticOnly:          boolean;
   IgnoreOutputDHCP:    boolean;
   RereadSubnetsPeriod: integer;  // time in seconds
   INICheckPeriod:      integer;
   LookupThreads:       integer;
   WINSNetBIOSNodeType: integer;
   MaxQueueLength:      integer;
   Interfaces:          string;


// ************************************************************************

procedure ReadINI();


// ************************************************************************


implementation


// ========================================================================
// = Global procedures
// ========================================================================
// ************************************************************************
// * LogBooleanINIVar()
// ************************************************************************

procedure LogBooleanINIVar( const Name: string; Value: boolean);
   var
      ValueStr: string;
   begin
      if( Value) then begin
         ValueStr:= 'true';
      end else begin
         ValueStr:= 'true';
      end;

      Log( LOG_DEBUG, Name + ' = ' + ValueStr);
   end; // LogBooleanINIVar()


// ************************************************************************
// * LogINIVars()
// ************************************************************************

procedure LogINIVars();
   begin
      LogBooleanINIVar( 'DebugServerOutput  ', DebugServerOutput);
      LogBooleanINIVar( 'DebugServerInput   ', DebugServerInput);
      LogBooleanINIVar( 'DebugServerIgnore  ', DebugServerIgnore);
      LogBooleanINIVar( 'LogServerOutput    ', LogServerOutput);
      LogBooleanINIVar( 'LogServerInput     ', LogServerInput);
      LogBooleanINIVar( 'LogServerErrors    ', LogServerErrors);
      LogBooleanINIVar( 'LogServerInvalid   ', LogServerInvalid);
      LogBooleanINIVar( 'LogLookupProgress  ', LogLookupProgress);
      LogBooleanINIVar( 'LogLookupErrors    ', LogLookupErrors);
      LogBooleanINIVar( 'LogINIReads        ', LogINIReads);
      LogBooleanINIVar( 'LogSocket          ', LogSocket);
      LogBooleanINIVar( 'LogTimeStamp       ', LogTimeStamp);
      Log( LOG_DEBUG,   'LeaseFile           = %s', [LeaseFile]);
      Log( LOG_DEBUG,   'StdLeaseHrs         = %d', [StdLeaseHrs]);
      Log( LOG_DEBUG,   'StdLeaseMins        = %d', [StdLeaseMins]);
      Log( LOG_DEBUG,   'DynLeaseHrs         = %d', [DynLeaseHrs]);
      Log( LOG_DEBUG,   'DynLeaseMins        = %d', [DynLeaseMins]);
      Log( LOG_DEBUG,   'DynLeaseSecs        = %d', [DynLeaseSecs]);
      LogBooleanINIVar( 'GrantLongLeases    ', GrantLongLeases);
      LogBooleanINIVar( 'StaticOnly         ', StaticOnly);
      LogBooleanINIVar( 'IgnoreOutputDHCP   ', IgnoreOutputDHCP);
      Log( LOG_DEBUG,   'RereadSubnetsPeriod = %d', [RereadSubnetsPeriod]);
      Log( LOG_DEBUG,   'INICheckPeriod      = %d', [INICheckPeriod]);
      Log( LOG_DEBUG,   'LookupThreads       = %d', [LookupThreads]);
      Log( LOG_DEBUG,   'WINSNetBIOSNodeType = %d', [WINSNetBIOSNodeType]);
      Log( LOG_DEBUG,   'MaxQueueLength      = %d', [MaxQueueLength]);
      Log( LOG_DEBUG,   'Interfaces          = %s', [Interfaces]);
   end; // LogINIVars();


// ************************************************************************
// * ReadINI()
// ************************************************************************

procedure ReadINI();
   var
      SectName:         string;
   begin
      SectName:= 'DHCP Server Logging';
      DebugServerOutput:= INI.ReadVariable( SectName, 'DebugServerOutput', false);
      DebugServerInput:= INI.ReadVariable( SectName, 'DebugServerInput', false);
      DebugServerIgnore:= INI.ReadVariable( SectName, 'DebugServerIgnore', false);
      LogServerOutput:= INI.ReadVariable( SectName, 'LogServerOutput', false);
      LogServerInput:= INI.ReadVariable( SectName, 'LogServerInput', false);
      LogServerErrors:= INI.ReadVariable( SectName, 'LogServerErrors', false);
      LogServerInvalid:= INI.ReadVariable( SectName, 'LogServerInvalid', false);
      LogLookupProgress:= INI.ReadVariable( SectName, 'LogLookupProgress', false);
      LogLookupErrors:= INI.ReadVariable( SectName, 'LogLookupErrors', false);
      LogINIReads:= INI.ReadVariable( SectName, 'LogINIReads', false);
      LogSocket:= INI.ReadVariable( SectName, 'LogSocket', false);
      LogTimeStamp:= INI.ReadVariable( SectName, 'LogTimeStamp', false);

      SectName:= 'DHCP Server Lease';
      LeaseFile:= INI.ReadVariable( SectName, 'LeaseFile', '');
      StdLeaseHrs:= INI.ReadVariable( SectName, 'StdLeaseHrs', 0);
      StdLeaseMins:= INI.ReadVariable( SectName, 'StdLeaseMins', 5);
      StdLeaseSecs:= INI.ReadVariable( SectName, 'StdLeaseSecs', 0);
      StdLease:=     StdLeaseHrs * 3600 + StdLeaseMins * 60 + StdLeaseSecs;
      DefaultLease:= StdLease;
      DynLeaseHrs:= INI.ReadVariable( SectName, 'DynLeaseHrs', 0);
      DynLeaseMins:= INI.ReadVariable( SectName, 'DynLeaseMins', 5);
      DynLeaseSecs:= INI.ReadVariable( SectName, 'DynLeaseSecs', 0);
      DynLease:=     DynLeaseHrs * 3600 + DynLeaseMins * 60 + DynLeaseSecs;

      SectName:= 'DHCP Server Misc';
      GrantLongLeases:= INI.ReadVariable( SectName, 'GrantLongLeases', false);
      StaticOnly:= INI.ReadVariable( SectName, 'StaticOnly', false);
      IgnoreOutputDHCP:= INI.ReadVariable( SectName, 'IgnoreOutputDHCP', false);
      RereadSubnetsPeriod:= INI.ReadVariable( SectName, 'RereadSubnetsPeriod', 10);
      INICheckPeriod:= INI.ReadVariable( SectName, 'INICheckPeriod', 10);
      LookupThreads:= INI.ReadVariable( SectName, 'LookupThreads', 1);
      WINSNetBIOSNodeType:= INI.ReadVariable( SectName, 'WINSNetBIOSNodeType', 8);
      MaxQueueLength:= INI.ReadVariable( SectName, 'MaxQueueLength', 5);
      Interfaces:= INI.ReadVariable( SectName, 'Interfaces', 'eth0');
      if( LogINIReads) then begin
         LogINIVars();
      end;
   end; // ReadINI();


// *************************************************************************
// * Initialization
// *************************************************************************

initialization
   begin
      if( lbp_types.show_init) then begin
         writeln( 'Initialization of lbp_dhcp_ini started.');
      end;
      if( INI <> nil) then begin
         ReadINI();
      end;
      if( lbp_types.show_init) then begin
         writeln( 'Initialization of lbp_dhcp_ini ended.');
      end;
   end; // initialization


// *************************************************************************

end. // lbp_dhcp_ini unit
