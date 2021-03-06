{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

A test of the dhcp raw socket code

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

program test_raw_socket;

uses
   cthreads,
   lbp_dhcp_socket,
   lbp_dhcp_buffer,
   lbp_dhcp_fields;

var
  S: tDHCPRawSocket;
  DHCPData: tDHCPData;
begin
  DHCPData:= tDHCPData.Create();

  S:= tDHCPRawSocket.Create( 'eth1', DHCPClientPortNumber);
  S.IsOpen:= true;

  S.ReadPacket( DHCPData);
  writeln( 'Read ', DHCPData.BufferUsed, ' bytes.');
//  writeln( SizeOf( sockaddr_ll));
  S.Destroy();
  DHCPData.Destroy();
end.  // test_raw_socket
