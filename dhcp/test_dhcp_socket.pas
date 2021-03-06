Program test_dhcp_socket;

{$include kent_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   cthreads,
   kent_types,
   kent_utils,
   kent_log,
   kent_net_info,   // info about our interfaces
   kent_net_buffer,
   kent_net_fields,
   kent_dhcp_buffer,
   kent_dhcp_socket;


// *************************************************************************
// * BasicBufferTest() - Tests basic encode and decocde of a DHCP packet
// *************************************************************************

procedure BasicBufferTest();

   var
      NetInfo:       tNetworkInfo;
      InterfaceInfo: tNetInterfaceInfo;
      Netdevice:     string;
      Buffer:        tDHCPBuffer;

   begin
      // Look for an ethernet interface as the first parameter
      if( ParamCount > 0) then begin
         NetDevice:= ParamStr( 1);
      end else begin
         NetDevice:= 'eth0';
      end;
      InterfaceInfo:= GetNetInterfaceInfo( NetDevice);
      NetInfo:= tNetworkInfo( InterfaceInfo.IPList.GetFirst());
      if( NetInfo = nil) then begin
         raise KentException.Create( NetDevice + ' has no assigned IP!');
      end;

      Buffer:= tDHCPBuffer.Create();

      Buffer.EthHdr.SrcMAC.DefaultStrValue:= InterfaceInfo.MACstr;
      Buffer.EthHdr.SrcMAC.Clear();
      Buffer.EthHdr.DstMAC.DefaultStrValue:= InterfaceInfo.BroadcastStr;
      Buffer.EthHdr.DstMAC.Clear();

      Buffer.EthHdr.EthType.StrValue:= '0800';
      Buffer.IPHdr.SrcIP.DefaultValue:= NetInfo.IPAddr;
      Buffer.IPHdr.SrcIP.Clear();
      Buffer.IPHdr.DstIP.DefaultStrValue:= '255.255.255.255';
      Buffer.IPHdr.DstIP.Clear();
      Buffer.IPHdr.IPLength.Value:= 328;
      Buffer.UDPHdr.SrcPort.DefaultValue:= 68;
      Buffer.UDPHdr.SrcPort.Clear();
      Buffer.UDPHdr.DstPort.DefaultValue:= 67;
      Buffer.UDPHdr.DstPort.Clear();

      Buffer.ClientIPAddr.StrValue:= '10.123.24.130';
      Buffer.ClientHardwareAddress.StrValue:= '1122.3344.5566';
      Buffer.ServerName.StrValue:= 'course.net.kent.edu';
      Buffer.BootFile.StrValue:= '/tftp/test/junk.txt';

      Buffer.DHCPOpCode.Value:= 4;
      Buffer.SubnetMask.StrValue:= '255.255.248.0';
      Buffer.Routers.Value[ 0]:= 1;
      Buffer.NameServers.Value[ 0]:= 2;
      Buffer.NameServers.Value[ 1]:= 3;
      Buffer.HostName.StrValue:= 'bitt';
      Buffer.IPDomain.StrValue:= 'net.kent.edu';
      Buffer.ClientIdentifier.StrValue:= '1122:3344:5566';
      Buffer.NetBIOSNode.Value:= 4;
      Buffer.BroadcastAddress.StrValue:= '10.123.31.255';
      Buffer.RequestedIPAddr.StrValue:= '10.123.24.130';
      Buffer.DHCPLease.Value:= 15 * 60;
      Buffer.VendorClass.StrValue:= 'My Vendor Class';
      Buffer.ServerID.StrValue:= '131.123.252.2';
      Buffer.WINSServers.Value[ 0]:= IPStringToWord32( '131.123.24.242');
      Buffer.WINSServers.Value[ 1]:= IPStringToWord32( '131.123.24.216');
      Buffer.WINSScope.StrValue:= 'kent';
      Buffer.ErrorMessage.StrValue:= 'No Errors';

      with Buffer do begin
         RawMode:= false;
         RawMode:= true;
         AddBaseFields();
         Fields.Enqueue( DHCPOpCode);
         Fields.Enqueue( SubnetMask);
         Fields.Enqueue( Routers);
         Fields.Enqueue( NameServers);
         Fields.Enqueue( IPDomain);
         Fields.Enqueue( HostName);
         Fields.Enqueue( ClientIdentifier);
         Fields.Enqueue( BroadcastAddress);
         Fields.Enqueue( RequestedIPAddr);
         Fields.Enqueue( DHCPLease);
         Fields.Enqueue( VendorClass);
         Fields.Enqueue( ParameterRequestList);
         Fields.Enqueue( ServerID);
         Fields.Enqueue( WINSServers);
         Fields.Enqueue( WINSScope);
         Fields.Enqueue( NetBIOSNode);
         Fields.Enqueue( ErrorMessage);
   //      Fields.Enqueue( Pad);
         Fields.Enqueue( DataEnd);
      end;


      Writeln( '---------------------- v Encode v -----------------------');
      Buffer.Encode();
      Buffer.LogFullPacket();
      Writeln( '---------------------- ^ Encode ^ -----------------------');
   //   writeln( 'main() - Buffer.Routers.Value.UpperBound = ', Buffer.Routers.Value.UpperBound);

      Writeln( '---------------------- v Hex dump v -----------------------');
      Buffer.HexDump();
      Writeln( '---------------------- ^ Hex dump ^ -----------------------');



   //   F:= tNetField( Buffer.HeaderFields.GetFirst());
   //   while( F <> nil) do begin
   //      F.Clear();
   //      F:= tNetField( Buffer.HeaderFields.GetNext());
   //   end;

   //   Buffer.LogFullPacket();

      writeln();
      Writeln( '---------------------- v Decode v -----------------------');
      Buffer.Decode();
      Buffer.LogFullPacket();
      Writeln( '---------------------- ^ Decode ^ -----------------------');

      writeln;
      Buffer.Destroy();
      InterfaceInfo:= nil;
      NetInfo:= nil;
   end; // BasicBufferTest()


// *************************************************************************
// * PacketSendTest() - Tests to ability to send a standard DHCP packet.
// *************************************************************************

procedure PakcetSendTest();

   var
      NetInfo:       tNetworkInfo;
      InterfaceInfo: tNetInterfaceInfo;
      Netdevice:     string;
      Buffer:        tDHCPBuffer;

   begin
      // Look for an ethernet interface as the first parameter
      if( ParamCount > 0) then begin
         NetDevice:= ParamStr( 1);
      end else begin
         NetDevice:= 'eth0';
      end;
      InterfaceInfo:= GetNetInterfaceInfo( NetDevice);
      NetInfo:= tNetworkInfo( InterfaceInfo.IPList.GetFirst());
      if( NetInfo = nil) then begin
         raise KentException.Create( NetDevice + ' has no assigned IP!');
      end;

      Buffer:= tDHCPBuffer.Create();

      Buffer.EthHdr.SrcMAC.DefaultStrValue:= InterfaceInfo.MACstr;
      Buffer.EthHdr.SrcMAC.Clear();
      Buffer.EthHdr.DstMAC.DefaultStrValue:= InterfaceInfo.BroadcastStr;
      Buffer.EthHdr.DstMAC.Clear();

      Buffer.EthHdr.EthType.StrValue:= '0800';
      Buffer.IPHdr.SrcIP.DefaultValue:= NetInfo.IPAddr;
      Buffer.IPHdr.SrcIP.Clear();
      Buffer.IPHdr.DstIP.DefaultStrValue:= '255.255.255.255';
      Buffer.IPHdr.DstIP.Clear();
      Buffer.IPHdr.IPLength.Value:= 328;
      Buffer.UDPHdr.SrcPort.DefaultValue:= 68;
      Buffer.UDPHdr.SrcPort.Clear();
      Buffer.UDPHdr.DstPort.DefaultValue:= 67;
      Buffer.UDPHdr.DstPort.Clear();

      Buffer.ClientIPAddr.StrValue:= '10.123.24.216';
      Buffer.ClientHardwareAddress.StrValue:= '1122.3344.5566';
      Buffer.ServerName.StrValue:= 'course.net.kent.edu';
      Buffer.BootFile.StrValue:= '/tftp/test/junk.txt';

      Buffer.DHCPOpCode.Value:= 4;
      Buffer.SubnetMask.StrValue:= '255.255.248.0';
      Buffer.Routers.Value[ 0]:= 1;
      Buffer.NameServers.Value[ 0]:= 2;
      Buffer.NameServers.Value[ 1]:= 3;
      Buffer.HostName.StrValue:= 'bitt';
      Buffer.IPDomain.StrValue:= 'net.kent.edu';
      Buffer.ClientIdentifier.StrValue:= '1122:3344:5566';
      Buffer.NetBIOSNode.Value:= 4;
      Buffer.BroadcastAddress.StrValue:= '10.123.31.255';
      Buffer.RequestedIPAddr.StrValue:= '10.123.24.216';
      Buffer.DHCPLease.Value:= 15 * 60;
      Buffer.VendorClass.StrValue:= 'My Vendor Class';
      Buffer.ServerID.StrValue:= '131.123.252.2';
      Buffer.WINSServers.Value[ 0]:= IPStringToWord32( '131.123.24.242');
      Buffer.WINSServers.Value[ 1]:= IPStringToWord32( '131.123.24.216');
      Buffer.WINSScope.StrValue:= 'kent';
      Buffer.ErrorMessage.StrValue:= 'No Errors';

      with Buffer do begin
         RawMode:= false;
         RawMode:= true;
         AddBaseFields();
         Fields.Enqueue( DHCPOpCode);
         Fields.Enqueue( SubnetMask);
         Fields.Enqueue( Routers);
         Fields.Enqueue( NameServers);
         Fields.Enqueue( IPDomain);
         Fields.Enqueue( HostName);
         Fields.Enqueue( ClientIdentifier);
         Fields.Enqueue( BroadcastAddress);
         Fields.Enqueue( RequestedIPAddr);
         Fields.Enqueue( DHCPLease);
         Fields.Enqueue( VendorClass);
         Fields.Enqueue( ParameterRequestList);
         Fields.Enqueue( ServerID);
         Fields.Enqueue( WINSServers);
         Fields.Enqueue( WINSScope);
         Fields.Enqueue( NetBIOSNode);
         Fields.Enqueue( ErrorMessage);
   //      Fields.Enqueue( Pad);
         Fields.Enqueue( DataEnd);
      end;


      Writeln( '---------------------- v Encode v -----------------------');
      Buffer.Encode();
      Buffer.LogFullPacket();
      Writeln( '---------------------- ^ Encode ^ -----------------------');
   //   writeln( 'main() - Buffer.Routers.Value.UpperBound = ', Buffer.Routers.Value.UpperBound);

      writeln;


      Writeln( '---------------------- v Hex dump v -----------------------');
      Buffer.HexDump();
      Writeln( '---------------------- ^ Hex dump ^ -----------------------');

   //   F:= tNetField( Buffer.HeaderFields.GetFirst());
   //   while( F <> nil) do begin
   //      F.Clear();
   //      F:= tNetField( Buffer.HeaderFields.GetNext());
   //   end;

   //   Buffer.LogFullPacket();

      writeln();
      Writeln( '---------------------- v Decode v -----------------------');
      Buffer.Decode();
      Buffer.LogFullPacket();
      Writeln( '---------------------- ^ Decode ^ -----------------------');

      writeln;
      Buffer.Destroy();
      InterfaceInfo:= nil;
      NetInfo:= nil;
   end; // BasicBufferTest()


// *************************************************************************
// * PacketReceiveTest() - Test receiviving packets
// *************************************************************************

procedure PacketReceiveTest();
   var
      DHCPSocket:    tDHCPSocket;
      Buffer:        tDHCPBuffer;
      i:             integer;
   begin
      i:= 300;
      Log( LOG_DEBUG, 'PacketReiveTest():  Waiting to read %D packets...', [i]);

      DHCPSocket:= tDHCPSocket.Create( 'eth0', DHCPServerPortNumber);
      DHCPSocket.IsOpen:= true;
      Buffer:= tDHCPBuffer.Create();

      for i:= i downto 1 do begin
         DHCPSocket.ReadPacket( Buffer);

         writeln();
//         Writeln( '--------------------- v Hexdump v -----------------------');
//         Buffer.HexDump();
//         Writeln( '--------------------- ^ Hexdump ^ -----------------------');
         Writeln( '---------------------- v Decode v -----------------------');
         Buffer.Decode();
         Buffer.LogFullPacket();
         Writeln( '---------------------- ^ Decode ^ -----------------------');
     end;

      Buffer.Destroy();
      DHCPSocket.IsOpen:= false;
      DHCPSocket.Destroy();

   end; // PacketReceiveTest()


// *************************************************************************
// * Main()
// *************************************************************************


begin
   LogLevel:= LOG_DEBUG;
   Log( LOG_DEBUG, 'Program starting');

//   BasicBufferTest();
   PacketReceiveTest();

   Log( LOG_DEBUG, 'Program ending.');
end. // test_dhcp_socket

