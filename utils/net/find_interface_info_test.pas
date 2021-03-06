{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

test the lbp_net_info and lbp_ip_network units

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

program find_interface_info_test;

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   lbp_types,
   lbp_net_info,
   lbp_ip_network,
   lbp_lists,
   lbp_utils, // IP Conversion
   baseunix,
   unix;


// *************************************************************************
// * Main()
// *************************************************************************

var
   NetInfo:       tNetworkInfo;
   InterfaceInfo: tNetInterfaceInfo;
begin
   // Display our interface information
   InterfaceInfo:= tNetInterfaceInfo( NetInterfaceList.GetFirst());
   while( InterfaceInfo <> nil) do begin

      // Display a single interface
      with( InterfaceInfo) do begin
         Writeln( Name, ':');
         if( IsEthernet) then begin
            writeln( '     MAC           = ', MACstr);
            writeln( '     MAC Broadcast = ', BroadcastStr);
            NetInfo:= tNetworkInfo( IPList.GetFirst());
            while( NetInfo <> nil) do begin
               writeln( '     IP Address    = ', NetInfo.IPAddrStr);
               writeln( '     IP Netmask    = ', NetInfo.NetMaskStr);
               writeln( '     IP Network    = ', NetInfo.NetNumStr);
               writeln( '     IP Broadcast  = ', NetInfo.BroadcastStr);
               writeln( '     Net/Prefix    = ', NetInfo.CIDR);
               NetInfo:= tNetworkInfo( IPList.GetNext());
            end; // while NetInfo <> nil
         end; // if IsEthernet
      end; // with InterfaceInfo

      InterfaceInfo:= tNetInterfaceInfo( NetInterfaceList.GetNext());
   end; // while InterfaceInfo <> nil


   writeln; writeln; writeln;
   InterfaceInfo:= GetNetInterfaceInfo( 'lo');
   with( InterfaceInfo) do begin
      Writeln( Name, ':');
      if( not IsEthernet) then begin
         writeln( '     MAC           = ', MACstr);
         writeln( '     MAC Broadcast = ', BroadcastStr);
         NetInfo:= tNetworkInfo( IPList.GetFirst());
         while( NetInfo <> nil) do begin
            writeln( '     IP Address    = ', NetInfo.IPAddrStr);
            writeln( '     IP Netmask    = ', NetInfo.NetMaskStr);
            writeln( '     IP Network    = ', NetInfo.NetNumStr);
            writeln( '     IP Broadcast  = ', NetInfo.BroadcastStr);
            writeln( '     Net/prefix    = ', NetInfo.CIDR);
            NetInfo:= tNetworkInfo( IPList.GetNext());
         end; // while NetInfo <> nil
      end; // if IsEthernet
   end; // with InterfaceInfo



//   NetInfo:= tNetworkInfo.Create();

//   with NetInfo do begin
//       NetNumStr:= '131.123.252.200'; // test
//       NetNum:= 2205940936;
//       NetMaskStr:= '255.255.254.0';
//       writeln( 'NetMask = ', NetMaskStr, '   PrefixStr  = ', PrefixStr);
//       NetMaskStr:= '255.255.255.255';
//       writeln( 'NetMask = ', NetMaskStr, '   PrefixStr  = ', PrefixStr);
//       NetMaskStr:= '0.0.0.0';
//       writeln( 'NetMask = ', NetMaskStr, '   PrefixStr  = ', PrefixStr);
//       NetMaskStr:= '128.0.0.0';
//       writeln( 'NetMask = ', NetMaskStr, '   PrefixStr  = ', PrefixStr);
//       NetMask:= 4294967294;
//       writeln( 'NetMask = ', NetMaskStr, '   PrefixStr  = ', PrefixStr);

{      Prefix:= 23;
      Value:= '131.123.252.200/23';
      writeln( 'NetNum    = ', NetNum,    '   NetNumStr     = ', NetNumStr);
      writeln( 'NetMask   = ', NetMask,   '   NetMaskStr    = ', NetMaskStr);
      writeln( 'Prefix    = ', Prefix,    '   PrefixStr     = ', PrefixStr);
      writeln( 'Broadcast = ', Broadcast, '   BroadcastStr  = ', BroadcastStr);
      writeln( 'Value     = ', Value);
      writeln();

      Prefix:= 0;
      writeln( 'NetNum    = ', NetNum,    '   NetNumStr     = ', NetNumStr);
      writeln( 'NetMask   = ', NetMask,   '   NetMaskStr    = ', NetMaskStr);
      writeln( 'Prefix    = ', Prefix,    '   PrefixStr     = ', PrefixStr);
      writeln( 'Broadcast = ', Broadcast, '   BroadcastStr  = ', BroadcastStr);
      writeln( 'Value     = ', Value);
      writeln();

      Prefix:= 32;
      writeln( 'NetNum    = ', NetNum,    '   NetNumStr     = ', NetNumStr);
      writeln( 'NetMask   = ', NetMask,   '   NetMaskStr    = ', NetMaskStr);
      writeln( 'Prefix    = ', Prefix,    '   PrefixStr     = ', PrefixStr);
      writeln( 'Broadcast = ', Broadcast, '   BroadcastStr  = ', BroadcastStr);
      writeln( 'Value     = ', Value);
      writeln();}
//   end;

//   NetInfo.Destroy();

end.  // find_interface_info_test
