{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

an IPv4 DHCP test client

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

Program lbp_dhcp_test_client;

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

{$define FPC_LINK_STATIC}

uses
   cthreads,            // Thread driver:  Must be first in the uses clause!
   lbp_argv,
   lbp_dhcp_client_ini,
   lbp_dhcp_client_cron,
   sysutils,
   lbp_dhcp_buffer,
   lbp_dhcp_fields,
   lbp_dhcp_socket,
   lbp_net_info,
   lbp_current_time,
   lbp_ini_files,
   lbp_cron,
   lbp_types,
   lbp_ip_utils,
   lbp_lists,
   lbp_binary_trees,
   lbp_log,
   dateutils,
   classes,             // tThread
   BaseUnix;            // Signal names

// ************************************************************************

var
   DHCPBuffer: tDHCPBuffer;


// *************************************************************************
// * ProcessPacket() - Handle incomming data on our socket
// *************************************************************************

procedure ProcessPacket();
   var
      ServerInfo:   tServerInfo;
      TempServerIP: string;
      TempIPStr:    string;  // Used to swap src and dst IP address
   begin
      DHCPBuffer.DHCPLease.Clear();
      DHCPBuffer.ParameterRequestList.Clear();

      if( (not DHCPSocket.ReadPacket( DHCPBuffer)) or
         (not DHCPBuffer.IsDHCPPacket( LocalPort))) then begin
//         writeln( 'lbp_dhcp_test_client.ProcessPacket():  Debug - Invalid or no packet?');
         exit;
      end;
//      writeln( 'lbp_dhcp_test_client.ProcessPacket():  Debug - We got a valid packet.');
      
      inc( DHCPBuffer.PacketID);
      DHCPBuffer.Decode();
      DHCPBuffer.LogFullPacket();
      Log( LOG_DEBUG, '------');

      // Don't record anything for packets directed at another host
      if( DHCPSocket.MyMAC <>
              DHCPBuffer.ClientHardwareAddress.StrValue) then begin
         exit;
      end;

      TempServerIP:= DHCPBuffer.ServerID.StrValue;
      if( TempServerIP = '0.0.0.0') then begin
         TempServerIP:= DHCPBuffer.ServerIPAddr.StrValue;
         if( TempServerIP = '0.0.0.0') then begin
            TempServerIP:= DHCPBuffer.IPHdr.SrcIP.StrValue;
         end;
      end;

         // Make sure we are tracking the server which sent this packet.
      ServerInfo:= ServerTree.Find( DHCPSocket.MyInterfaceName, TempServerIP);
      if( ServerInfo = nil) then begin
         ServerInfo:= tServerInfo.Create( DHCPSocket.MyInterfaceName, TempServerIP);
         ServerTree.Add( ServerInfo);
      end;

      case DHCPBuffer.DHCPOpCode.Value of
         dhcpOffer: begin
                        with DHCPBuffer do begin
                           if( RawMode) then begin
                              ServerInfo.NIC:= MACStringToWord64(EthHdr.SrcMAC.StrValue);
                              EthHdr.DstMAC.StrValue:= EthHdr.SrcMAC.StrValue;
                              EthHdr.SrcMAC.StrValue:= DHCPSocket.MyMAC;
//                               EthHdr.DstMAC.StrValue:= 'ffff.ffff.ffff';
                              TempIPStr:= IPHdr.SrcIP.StrValue;
                              IPHdr.SrcIP.StrValue:= IPHdr.DstIP.StrValue;
                              IPHdr.DstIP.StrValue:= TempIPStr;
                              IPHdr.IPLength.Value:= 32;
                              UDPHdr.SrcPort.Value:= DHCPClientPortNumber;
                              UDPHdr.DstPort.Value:= DHCPServerPortNumber;
                           end;

                           ServerInfo.Gateway:= Routers.GetStrValue;
                           ServerInfo.HostIP:= ClientIPAddr.GetStrValue;

                           AddBaseFields;

                           OpCode.Value:= BootRequestOp;
                           DHCPOpCode.Value:= dhcpRequest;
                           ClientIdentifier.StrValue:= DHCPSocket.MyMAC;
                           RequestedIPAddr.SetStrValue(
                                                ClientIPAddr.GetStrValue);
// Removed in an attempt to fix an isc dhcp relay issue.
//                           ServerID.SetStrValue(
//                                                ServerIPAddr.GetStrValue);
                           HostName.SetStrValue( 'lbp_dhcp_test');
                           VendorClass.SetStrValue( 'lbp_dhcp_test');
                           ParameterRequestList.Value[ 0]:= 1;
                           ParameterRequestList.Value[ 1]:= 15;
                           ParameterRequestList.Value[ 2]:= 3;
                           ParameterRequestList.Value[ 3]:= 6;
                           ParameterRequestList.Value[ 4]:= 44;
                           ParameterRequestList.Value[ 5]:= 46;
                           ParameterRequestList.Value[ 6]:= 47;
                           ParameterRequestList.Value[ 7]:= 32;
                           ParameterRequestList.Value[ 8]:= 33;
                           DataEnd.Clear;

                           Fields.Enqueue( DHCPOpCode);
                           Fields.Enqueue( ClientIdentifier);
                           Fields.Enqueue( RequestedIPAddr);
                           Fields.Enqueue( ServerID);
                           Fields.Enqueue( HostName);
                           Fields.Enqueue( VendorClass);
                           Fields.Enqueue( ParameterRequestList);
                           Fields.Enqueue( DataEnd);
                           Fields.Enqueue( DataEnd);

                           Hops.Clear;
//                           ClientSuppliedIPAddr.Clear;
//                           ClientIPAddr.Clear;
//                           ServerIPAddr.Clear;

                           Encode;
                        end;
                        if( (not ServerInfo.Complete) and
                           (not ServerInfo.SentReq)) then begin
                           ServerInfo.SentReq:= true;
                           DHCPSocket.WritePacket( DHCPBuffer);
                           DHCPBuffer.LogFullPacket();
                           Log( LOG_DEBUG, '------');
                        end;
                     end;
         dhcpAck:   begin
                        ServerInfo.Complete:= true;
                     end;
         dhcpNack:  begin
                        ServerInfo.NAck:= true;
                      end;
      end; // case
   end; // ProcessPacket()


// *************************************************************************
// * Report() - Output our report
// *************************************************************************

procedure Report();
   var
      ServerInfo: tServerInfo;
      Status:     string;
   begin
      ServerInfo:= tServerInfo( ServerTree.GetFirst);
      while( ServerInfo <> nil) do begin
         Log( LOG_NOTICE, 'Interface=' + ServerInfo.NetIF);
         Log( LOG_NOTICE, 'Server=' + ServerInfo.ServerIPStr);
         Log( LOG_NOTICE, 'ServerMAC=' + MacWord64ToString( ServerInfo.NIC));
         if ServerInfo.Complete then begin
            Status:= 'complete';
         end else if ServerInfo.NAck then begin
            Status:= 'nack';
         end else begin
            Status:= 'partial';
         end;
         Log( LOG_NOTICE, 'Status=' + Status);
         if( ServerInfo.HostIP <> '') then begin
            Log( LOG_NOTICE, 'HostIP=' + ServerInfo.HostIP);
         end;
         if( ServerInfo.Gateway <> '') then begin
            Log( LOG_NOTICE, 'Gateway=' + ServerInfo.Gateway);
         end;
         ServerInfo:= tServerInfo( ServerTree.GetNext);
      end;
   end; // Report()


// ************************************************************************
// * main()
// ************************************************************************

var
   ErrorCount:    integer = 0;
   MaxErrorCount: integer = 10;

begin
   // Set some default values
   QueryCount:= 2;
   LogLevel:= LOG_INFO;
   ParseParams(); // override them with command line options or INI file settings
   
   Log(LOG_INFO, 'lbp_dhcp_test_client starting...');
   DHCPBuffer:= tDHCPBuffer.Create();
   DHCPBuffer.RawMode:= true;

   // CronThread sends the DHCP Discover packets and triggers the end of the test
   CronThread:= tCronThread.Create( DHCPSocket);
   while not CronThread.Done do begin
      try
         ProcessPacket();
      except
         on E: Exception do begin
            inc( ErrorCount);
            if( ErrorCount >= MaxErrorCount) then raise E;
         end; // on Exception
      end; // try/except
   end;
   CronThread.WaitFor;
   Report;
   CronThread.Destroy;

   DHCPBuffer.Destroy();
end. // lbp_dhcp_test_client
