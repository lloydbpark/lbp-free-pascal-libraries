{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Reads DHCP packets and displays them.

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

Program test_socket;

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

{$define FPC_LINK_STATIC}

uses
   cthreads,            // Thread driver:  Must be first in the uses clause!
//   lbp_dhcp_test_client_rcv_thrd,
   lbp_dhcp_client_ini,
   lbp_dhcp_client_cron,
   sysutils,
   lbp_dhcp_buffer,
   lbp_dhcp_fields,
   lbp_dhcp_socket,
   lbp_sql_fields,     // dbNICAddressField.Word64ToString()
   lbp_net_info,
//   lbp_net_socket_helper,
   lbp_current_time,
   lbp_ini_files,
   lbp_cron,
//   lbp_unix_cron, // Needed to properly handle select() for IO
//   lbp_signal_handlers,
//   lbp_run_once,
   lbp_types,
   lbp_utils,
   lbp_lists,
   lbp_binary_trees,
   lbp_log,
   dateutils,
   classes,             // tThread
   BaseUnix;            // Signal names

// ************************************************************************

var
   DHCPBuffer: tDHCPBuffer;


// ************************************************************************
// * main()
// ************************************************************************

begin
   LogLevel:=LOG_DEBUG;
   DHCPBuffer:= tDHCPBuffer.Create();
   DHCPBuffer.RawMode:= true;

   while true do begin
      if( DHCPSocket.ReadPacket( DHCPBuffer)) then begin
         writeln( DHCPBuffer.BuffEndPos + 1, ' bytes read.');
         DHCPBuffer.LogFullPacket
      end;
   end;

   DHCPBuffer.Destroy();
end. // test_socket program
