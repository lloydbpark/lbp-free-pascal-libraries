{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

reads an INI file for DHCP client settings and starts a test client

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

unit lbp_dhcp_client_ini;

// Contains the cron jobs which send the initial DHCP requests every few
// seconds and schedules the end of the test.

// The cron thread create function will be passed an already created
// DHCP socket.

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

{$WARNING We may want to change this.}
{$define FPC_LINK_STATIC}

uses
   lbp_argv,
   lbp_log,
   lbp_delayed_exceptions,
   lbp_net_socket_helper,  // tInterfaceInfo
   lbp_dhcp_socket,
   lbp_net_info,
   lbp_current_time,
   lbp_ini_files,
   lbp_types,
   lbp_utils,
   lbp_ip_utils,
   lbp_binary_trees,
   sysutils;


// *************************************************************************
// * tServerInfo - Holds the status of a single DHCP servers responses
// *************************************************************************

type
   tServerInfo = class
      public
         NetIF:        string;
         ServerIPStr:  string;
         ServerIP:     word32;
         HostIP:       string;
         Gateway:      string;
         NIC:          word64;
         Complete:     boolean;  // True if we have finished leasing
         NAck:         boolean;  // True if we have recieved a NAck from this server
         SentReq:      boolean;  // True if we have sent a request
         constructor Create( iNetIF:     string;
                             iServerIP:  string);
      end; // tServerInfo class


// *************************************************************************
// * tServerTree - Holds the DHCP status/progress of each server which responds
// *************************************************************************

type
   tServerTree = class( tBalancedBinaryTree)
      public
         constructor   Create();
         function      Find( iNetIF: string; iIP: string): tServerInfo; overload;
      end; // tServerTree


// *************************************************************************

var
   DHCPSocket:     tDHCPSocket;
   InterfaceInfo:  tInterfaceInfo = nil;
   NetworkDevice:  string;  // Interface name - passed to the program as a parameter.
   ServerTree:     tServerTree;

   // Built from .INI file
   Timeout:           Int32 = 0;
   QueryPeriod:       Int32 = 1;
   QueryCount:        Int32 = 1;
   LocalPort:         Int32 = DHCPClientPortNumber;


// *************************************************************************

implementation

// *************************************************************************

var
   // Used by the initialization section
   ServerInfo:     tServerInfo;


// -------------------------------------------------------------------------
// - Global functions
// -------------------------------------------------------------------------
// *************************************************************************
// * ReadINI();
// *************************************************************************

procedure ReadINI();
   var
      SectName:   string;
   begin
      if( INI <> nil) then begin
         SectName:= 'DHCPTestClient';

         Timeout:=      INI.ReadVariable( SectName, 'Timeout', Timeout);
         QueryPeriod:=  INI.ReadVariable( SectName, 'QueryPeriod', QueryPeriod);
         QueryCount:=   INI.ReadVariable( SectName, 'QueryCount', QueryCount);
         LocalPort:=    INI.ReadVariable( SectName, 'LocalPort',  LocalPort);
      end;
   end; // ReadINI();


// =========================================================================
// = tServerTree
// =========================================================================
// *************************************************************************
// * CompareServer() - global function used only by tServerTree
// *************************************************************************

function CompareServer(  S1: tServerInfo; S2: tServerInfo): int8;
   begin
      if( S1.NetIF > S2.NetIF) then begin
         result:= 1;
      end else if( S1.NetIF < S2.NetIF) then begin
         result:= -1;
      end else if( S1.ServerIP > S2.ServerIP) then begin
         result:= 1;
      end else if( S1.ServerIP < S2.ServerIP) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareServer()


// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tServerTree.Create();
   begin
      inherited Create( tCompareProcedure( @CompareServer), false);
   end; // Create()


// *************************************************************************
// * Find() - Find the server information by Network interface and IP
// *************************************************************************

function tServerTree.Find( iNetIF: string; iIP: string): tServerInfo;
   var
      SearchServer: tServerInfo;
   begin
      SearchServer:= tServerInfo.Create( iNetIF, iIP);
      Result:= tServerInfo( inherited Find( SearchServer));
      SearchServer.Destroy();
   end; // Find()


// =========================================================================
// = tServerInfo class
// =========================================================================
// *************************************************************************
// * Create()
// *************************************************************************

constructor tServerInfo.Create( iNetIF:     string;
                                iServerIP:  string);
   begin
      NetIF:=        iNetIF;
      ServerIPStr:=  iServerIP;
      ServerIP:=     IPStringToWord32( iServerIP);
      HostIP:=       '';
      Gateway:=      '';
      NIC:=          0;
      Complete:=     false;
      NAck:=         false;
      SentReq:=      false;
   end; // Create()


// =========================================================================
// = Initialization and finalization
// =========================================================================
// *************************************************************************
// * ParseArgV() - Read and initialize INI variables.  Then parse the
// *               command line parameters which will override INI settings.
// *************************************************************************

procedure ParseArgv();
   var
      MinimumTimeout: integer;
   begin
      if( INI = nil) then begin
         Log( LOG_DEBUG, 'INI file not found.');
      end else begin
         Log( LOG_DEBUG, 'INI File Name is %s', [INI.FileName]);
      end;
      ParseHelper( 'timeout',      Timeout);
      ParseHelper( 'query-period', QueryPeriod);
      ParseHelper( 'query-count',  QueryCount);
      ParseHelper( 'local-port',   LocalPort);
      
      MinimumTimeout:= (QueryPeriod * QueryCount) + 1;
      if( Timeout < MinimumTimeout) then Timeout:= MinimumTimeout;

      // Get information about our network interface
      if( Length( UnnamedParams) = 1) then begin
         NetworkDevice:= UnnamedParams[ 0];
      end else begin
         NetworkDevice:= 'eth0';
      end;

      try // Capture internal errors
         InterfaceInfo:= GetInterfaceInfo( NetworkDevice);
         if( InterfaceInfo = nil) then begin
            raise DHCPSocketException.Create(
                  'Invalid ethernet interface (' + NetworkDevice + ') specified!');
         end;

         try
            DHCPSocket:= tDHCPSocket.Create( InterfaceInfo, word16( LocalPort));
            DHCPSocket.SetSocketTimeout( 500); // Half a second
            DHCPSocket.IsOpen:= true;
         except
            on Exception do begin
               raise DHCPSocketException.Create( 'You lack the rights to use ' +
                      'the DHCP Client port!  Try running this program as root ' +
                      'and make sure no other program is using the port.');
            end;
         end; // try/except
      except
         on E: Exception do begin
            DelayException( E);
         end;
      end; // try / except

      ServerTree:= tServerTree.Create();
   end; // ParseArgV


// *************************************************************************
// * initialization
// *************************************************************************

initialization
   begin
      // Add Usage messages
      InsertUsage( '   ========== DHCP Client Parameters ==========');
      InsertUsage( '      These parameters will override the INI file settings');
      InsertParam( ['timeout'], true, '', 'The number of seconds the program should run');
      InsertParam( ['query-period'], true , '', 'The number of seconds between DHCP Discoveries');
      InsertParam( ['query-count'], true, '', 'The number of DHCP Discover requests to send.');
      InsertParam( ['local-port'], true, '', 'The local UDP port to use for DHCP communication.');
      InsertUsage( '');
      AddPostParseProcedure( @ParseArgv);
   end; // initialization


// *************************************************************************
// * finalization
// *************************************************************************

finalization
   begin
      // If the user asked for help there is nothing to be cleaned up here
      if( ParamSet( 'h')) then exit;

      if( InterfaceInfo <> nil) then InterfaceInfo.Destroy;

      DHCPSocket.IsOpen:= false;
      DHCPSocket.Destroy();

      // Get rid of our list of servers
      ServerInfo:= tServerInfo( ServerTree.GetFirst);
      while( ServerInfo <> nil) do begin
         ServerInfo.Destroy();
         ServerInfo:= tServerInfo( ServerTree.GetNext);
      end;
      ServerTree.Destroy();
   end; // finalization


// ************************************************************************

end. // lbp_dhcp_client_ini unit
