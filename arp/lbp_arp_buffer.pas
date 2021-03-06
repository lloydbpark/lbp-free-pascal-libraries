{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

A buffer of ARP protocol data which can be written to and read from a
socket.

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

// A buffer of ARP protocol data which can be written to and read from a
// socket.
unit lbp_arp_buffer;
{$WARNING This unit is just a copy of lbp_dhcp_buffer with a find and replace of DHCP to ARP.  It needs to be converted to ARP functionality}

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings
//{$OVERFLOWCHECKS OFF}

interface

uses
   lbp_types,
   lbp_log,
   lbp_lists,
   lbp_net_fields,
   lbp_net_buffer,
   lbp_arp_fields,
   // Sockets must come before lbp_net_socket_helper.  The ntol family
   // of functions is defined in Sockets using integers and we need words.
   // So they are redefined in lbp_net_socket_helper using words.
   sockets,
   lbp_net_socket_helper,
   sysutils;  // Excption class


// ************************************************************************

const
   ARPMaxPacketSize        = 1522;
   ARPMinPacketSize        = 300;
   MaxARPDataRecords: word = 1;


// ************************************************************************

type
   ARPException = class( lbp_exception);
   tARPBuffer = class( tEthernetPacketBuffer)
      public
         ARPHeader:        tARPHeaderNetField;
      {$WARNING I created the fields below and then decided the place to put them was in lbp_net_fields.tARPHeaderNetField}
      {$WARNING I left them here for refererence.
         ARPHardwareType:  tFixedWord16;
         ARPProtocolType:  tFixedWord16;
         ARPHardwareSize:  tFixedWord8;
         ARPProtocolSize:  tFixedWord8;
         ARPOpCode:        tFixedWord16;
         ARPSenderMAC:     tVarHexString;
         ARPSenderIP:      tFixedIPAddr;
         ARPTargetMAC:     tVarHexString;
         ARPTargetIP:      tFixedIPAddr;
         // On recieve ARPPad18 is not needed.  Can we do away with it for sent packets?
         ARPPad18:         tVarHexString; // 18 bytes of 00 to make the packet large enough.
      public
         IFName:                string;

         constructor  Create();
         destructor   Destroy();          override;
         procedure    Decode();           override;
         procedure    Encode();           override;
      end; // tARPBuffer


// ************************************************************************

implementation


// ========================================================================
// = tARPBuffer
// ========================================================================

const
   ARPBufferCounter: word16 = 0;
var
   AvailUnknown:      DoubleLinkedList;
   AvailUnknownCS:    tRTLCriticalSection;

// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tARPBuffer.Create();
   begin
      inherited Create();

      UsedUnknown:= DoubleLinkedList.Create();

      // Set the Unique Identifier
      inc( ARPBufferCounter);
      ID:= ARPBufferCounter;
      IDStr:= '';
      Str( ID:3, IDStr);

      // Initialize the fixed fields
      OpCode:=                tFixedOpCode.Create();
      HardwareType:=          tFixedHWType.Create();
      HardwareAddressLength:= tFixedHWLength.Create();
      Hops:=                  tFixedWord8.Create( 'Hops', 0);
      TransactionID:=         tFixedTransID.Create();
      SecondsElapsed:=        tFixedWord16.Create( 'SecondsElapsed', 0);
      Flags:=                 tFixedWord16.Create( 'Flags', 0);
      ClientSuppliedIPAddr:=  tFixedIPAddr.Create( 'ClientSuppliedIPAddr');
      ClientIPAddr:=          tFixedIPAddr.Create( 'ClientIPAddr');
      ServerIPAddr:=          tFixedIPAddr.Create( 'ServerIPAddr');
      GatewayIPAddr:=         tFixedIPAddr.Create( 'GatewayIPAddr');
      ClientHardwareAddress:= tFixedNIC.Create( HardwareAddressLength);
      ServerName:=            tFixedStr.Create( 'ServerName', 64, '');
      BootFile:=              tFixedStr.Create( 'BootFile', 128, '');
      MajicCookie:=           tFixedmajic.Create();
      ARPOpCode:=            tARPOpCode.Create();
      SubnetMask:=            tVarIPAddr.Create( 1, 'Subnet Mask', '0.0.0.0');
      Routers:=               tVarIPAddrArray.Create( 3, 'Routers');
      NameServers:=           tVarIPAddrArray.Create( 6, 'Name Servers');
      IPDomain:=              tVarStr.Create( 15, 'IP Domain', '');
      HostName:=              tVarStr.Create( 12, 'Host Name', '');
      ClientIdentifier:=      tVarClientID.Create();
      BroadcastAddress:=      tVarIPAddr.Create( 28, 'Broadcast Address',
                                                 '0.0.0.0');
      RequestedIPAddr:=       tVarIPAddr.Create( 50, 'Requested IP',
                                                 '0.0.0.0');
      ARPLease:=             tVarLease.Create();
      VendorClass:=           tVarStr.Create( 60, 'Vendor Class', '');
      ParameterRequestList:=  tVarParamReq.Create();
      ServerID:=              tVarIPAddr.Create( 54, 'Server ID', '0.0.0.0');
      WINSServers:=           tVarIPAddrArray.Create( 44, 'WINS Servers');
      WINSScope:=             tVarStr.Create( 47, 'WINS Scope', '');
      NetBIOSNode:=           tVarNetBIOSNode.Create();
      ErrorMessage:=          tVarStr.Create( 56, 'Error message', '');
      Pad:=                   tVarPad.Create();
      DataEnd:=               tVarEnd.Create();

      // Add our fields to the AllFields list;
      AllFields.Enqueue( OpCode);
      AllFields.Enqueue( HardwareType);
      AllFields.Enqueue( HardwareAddressLength);
      AllFields.Enqueue( Hops);
      AllFields.Enqueue( TransactionID);
      AllFields.Enqueue( SecondsElapsed);
      AllFields.Enqueue( Flags);
      AllFields.Enqueue( ClientSuppliedIPAddr);
      AllFields.Enqueue( ClientIPAddr);
      AllFields.Enqueue( ServerIPAddr);
      AllFields.Enqueue( GatewayIPAddr);
      AllFields.Enqueue( ClientHardwareAddress);
      AllFields.Enqueue( ServerName);
      AllFields.Enqueue( BootFile);
      AllFields.Enqueue( MajicCookie);
      AllFields.Enqueue( ARPOpCode);
      AllFields.Enqueue( SubnetMask);
      AllFields.Enqueue( Routers);
      AllFields.Enqueue( NameServers);
      AllFields.Enqueue( IPDomain);
      AllFields.Enqueue( HostName);
      AllFields.Enqueue( ClientIdentifier);
      AllFields.Enqueue( BroadcastAddress);
      AllFields.Enqueue( RequestedIPAddr);
      AllFields.Enqueue( ARPLease);
      AllFields.Enqueue( VendorClass);
      AllFields.Enqueue( ParameterRequestList);
      AllFields.Enqueue( ServerID);
      AllFields.Enqueue( WINSServers);
      AllFields.Enqueue( WINSScope);
      AllFields.Enqueue( NetBIOSNode);
      AllFields.Enqueue( ErrorMessage);
      AllFields.Enqueue( Pad);
      AllFields.Enqueue( DataEnd);
   end; // Create()


// ************************************************************************
// * Destroy() - Destructor
// ************************************************************************

destructor tARPBuffer.Destroy();
   var
      VarUnknown: tVarUnknown;
   begin
      if( IsMultiThread) then begin
         EnterCriticalSection( AvailUnknownCS);
      end;

      while( not UsedUnknown.Empty()) do begin
         VarUnknown:= tVarUnknown( UsedUnknown.Dequeue());
         AvailUnknown.Enqueue( VarUnknown);
      end;
      UsedUnknown.Destroy();

      if( IsMultiThread) then begin
         LeaveCriticalSection( AvailUnknownCS);
      end;

      inherited Destroy();
   end; // Destroy()


// ************************************************************************
// * AddBaseFields() - Should be called before encoding or decoding a packet.
// *                   It places the minimum fields needed to perform an
// *                   Encode or Decode in Fields.  Children should override
// *                   this and call inherited Decode BEFORE performing
// *                   their own steps.
// ************************************************************************

procedure tARPBuffer.AddBaseFields();
   var
      VarUnknown: tVarUnknown;
   begin
      inherited AddBaseFields();
//
      // Clear out the VarUnknown packets and make them available for reuse
      if( IsMultiThread) then begin
         EnterCriticalSection( AvailUnknownCS);
      end;
      while( not UsedUnknown.Empty()) do begin
         VarUnknown:= tVarUnknown( UsedUnknown.Dequeue());
         AvailUnknown.Enqueue( VarUnknown);
      end;
      if( IsMultiThread) then begin
         LeaveCriticalSection( AvailUnknownCS);
      end;

      // Add our fields to the Fields list;
      Fields.Enqueue( OpCode);
      Fields.Enqueue( HardwareType);
      Fields.Enqueue( HardwareAddressLength);
      Fields.Enqueue( Hops);
      Fields.Enqueue( TransactionID);
      Fields.Enqueue( SecondsElapsed);
      Fields.Enqueue( Flags);
      Fields.Enqueue( ClientSuppliedIPAddr);
      Fields.Enqueue( ClientIPAddr);
      Fields.Enqueue( ServerIPAddr);
      Fields.Enqueue( GatewayIPAddr);
      Fields.Enqueue( ClientHardwareAddress);
      Fields.Enqueue( ServerName);
      Fields.Enqueue( BootFile);
      Fields.Enqueue( MajicCookie);
   end; // AddBaseFields()


// ************************************************************************
// * AddOptions() - Adds the options requested in our ParameterRequestList.
// ************************************************************************

procedure tARPBuffer.AddOptions();
   var
      i:    int32;
      Opt:  tNetField;
      UB:   int32;
      WINS: boolean;
   begin
      WINS:= WINSservers.Value.UpperBound >= 0;

      // for each requested option
      UB:= ParameterRequestList.Value.UpperBound;
      for i:= 0 to UB do begin
         Opt:= GetOption( ParameterRequestList.Value[ i]);

         // Is it an option we support?
         if( ( Opt <> nil) and (Opt.Code <> 0)) then begin

            // WINS server option?
            if( Opt.code = 44) then begin
               if( WINS) then begin
                  Fields.Enqueue( Opt);
               end;

            // WINS Scope option?
            end else if( Opt.Code = 47) then begin
               // Special handling for WINS scope
               if( WINS and (length( WINSScope.StrValue) > 0)) then begin
                  Fields.Enqueue( Opt);
               end;

            // All other supported options
            end else begin
               Fields.Enqueue( Opt);
            end;

         end; // if valid option
      end; // for each requested option
   end; // AddOptions();


// ************************************************************************
// * GetVarUnknown() - Returns a tVarUnknown variable from the list
// *                   AvailUnknown or creates a new one if needed.
// ************************************************************************

function tARPBuffer.GetVarUnknown( OptionNumber: word8): tVarUnknown;
   begin
      if( IsMultiThread) then begin
         EnterCriticalSection( AvailUnknownCS);
      end;

      if( AvailUnknown.Empty()) then begin
         result:= tVarUnknown.Create( OptionNumber);
      end else begin
         result:= tVarUnknown( AvailUnknown.Dequeue());
         result.Code:= OptionNumber;
         result.Clear();
      end;

      if( IsMultiThread) then begin
         LeaveCriticalSection( AvailUnknownCS);
      end;
   end; // GetVarUnknown()


// ************************************************************************
// * GetOption() - Given a bootp / ARP Option number, this function
// *               returns the proper t.
// ************************************************************************

function tARPBuffer.GetOption( OptionNumber: word8): tNetField;
   begin
      case OptionNumber of
         1:      result:= SubnetMask;
         3:      result:= Routers;
         6:      result:= NameServers;
         12:     result:= HostName;
         15:     result:= IPDomain;
         28:     result:= BroadcastAddress;
         44:     result:= WINSServers;
         46:     result:= NetBIOSNode;
         47:     result:= WINSScope;
         50:     result:= RequestedIPAddr;
         51:     result:= ARPLease;
         53:     result:= ARPOpCode;
         54:     result:= ServerID;
         55:     result:= ParameterRequestList;
         56:     result:= ErrorMessage;
         60:     result:= VendorClass;
         61:     result:= ClientIdentifier;
         0,255:  result:= DataEnd;
         else begin
            result:= nil;
         end;
      end; // case
   end;  // GetOption()


// ************************************************************************
// * DecodeOptions() - Decode the option portion of the packet
// ************************************************************************

procedure tARPBuffer.DecodeOptions();
   var
      OptNum: word8;
      Opt:    tNetField;
   begin
      repeat
         OptNum:= Buffer[ BufferPos];
         Opt:= GetOption( OptNum);
         if( Opt = nil) then begin
            Opt:= GetVarUnknown( OptNum);
            UsedUnknown.Enqueue( Opt);
         end;
         Fields.Enqueue( Opt);
         Opt.Read( Buffer, BufferPos);
      until( (OptNum = 0) or (OptNum = 255));
   end; // DecodeOptions()


// ************************************************************************
// * Decode() - Extracts the data from the buffer.
// ************************************************************************

procedure tARPBuffer.Decode();
   begin
      ParameterRequestList.Clear();
      ARPLease.Clear();
      RequestedIPAddr.Clear();
      ServerID.Clear();
      ARPOpCode.Clear();
      WINSServers.Clear();
      WINSScope.Clear();
      NetBIOSNode.Clear();

      AddBaseFields();

      // Read the base 'fixed' fields
      inherited Decode();

      if( MajicCookie.Value = ValidMajicCookie) then begin
         DecodeOptions();
      end;
   end; // Decode()


// ************************************************************************
// * Encode() - Places field data into the buffer.
// ************************************************************************

procedure tARPBuffer.Encode();
   var
      TargetPos: word32;
   begin
      inherited Encode();

      // DataPos is the first byte past the headers.
      TargetPos:= DataPos + 299;
      // Pad to 300 bytes/
      while( BuffEndPos < TargetPos) do begin
         inc( BuffEndPos);
         Buffer[ BuffEndPos]:= 0;
      end;
      SetLengthsAndChecksums();
   end; // Encode()


// ************************************************************************
// * IsARPPacket() - Returns true if the packet appears to be a UDP ARP
// *                  packet.  This should be called before Deocde()
// ************************************************************************

function tARPBuffer.IsARPPacket( RequiredPort: word32): boolean;
   var
      IPLen:       byte;
      IPProtocol:  byte;
      UDPDestPort: word32;
   begin
      // We only need  to test if we are in RawMode
      if( not RawMode) then begin
         result:= true;
         exit;
      end;

      // Assume this is an ethernet packet
      IPLen:= (Buffer[ 14] and $f) * 4;
      if( IPLen <> 20) then begin
         result:= false;
         exit;
      end;

      // Make sure it is a UDP packet
      IPProtocol:= Buffer[ 23];
      if( IPProtocol <> 17) then begin
         result:= false;
         exit;
      end;

      // Make sure it is one of the
      UDPDestPort:= (Buffer[ 36] shl 8) + Buffer[ 37];
      result:= (UDPDestPort = RequiredPort);
   end;  // IsARPPacket()


// ************************************************************************
// * GetRemoteIP() - Returns the IP of the remote workstation which sent or
// *                 will recieve the data.
// ************************************************************************

function tARPBuffer.GetRemoteIP(): word32;
   begin
      result:= ntohl( RemoteAddr.sin_addr.s_addr);
   end; // GetRemoteIP()


// ************************************************************************
// * GetRemotePort() - Returns the Port number of the remote host which
// *                   sent or will recieve the data.
// ************************************************************************

function tARPBuffer.GetRemotePort(): word;
   begin
      GetRemotePort:= ntohs( RemoteAddr.sin_port);
   end; // GetRemoteIP()


// ************************************************************************
// * GetLocalIP() - Returns the IP of the local interface which recieved,
// *                or will send the packet.
// ************************************************************************

function tARPBuffer.GetLocalIP(): word32;
   var
      ControlMsg:  cmsghdrPtr;
      PacketInfo:  in_pktinfoPtr;
   begin
      ControlMsg:= @SocketInfo;
      PacketInfo:= @ControlMsg^.cmsg_data;
      GetLocalIP:= ntohl( PacketInfo^.ipi_spec_dest.s_addr);
   end; // GetLocalIP()



// ========================================================================
// = Initialization and Finalization
// ========================================================================

var
   TempNetField: tNetField;

// *************************************************************************
// * Initialization
// *************************************************************************

initialization
   begin
      {$ifdef DEBUG_UNIT_INITIALIZATION}
         writeln( 'Initialization of lbp_arp_buffer started.');
      {$endif}
      InitCriticalSection( AvailUnknownCS);

      AvailUnknown:= DoubleLinkedList.Create();
      {$ifdef DEBUG_UNIT_INITIALIZATION}
         writeln( 'Initialization of lbp_arp_buffer ended.');
      {$endif}
   end; // Initialization


// *************************************************************************
// * Finalization
// ************************************************************************

finalization
   begin
      {$ifdef DEBUG_UNIT_INITIALIZATION}
         writeln( 'Finalization of lbp_arp_buffer started.');
      {$endif}
      DoneCriticalSection( AvailUnknownCS);

      while( not AvailUnknown.Empty()) do begin
         TempNetField:= tNetField( AvailUnknown.Dequeue());
         TempNetField.Destroy();
      end;
      AvailUnknown.Destroy();

      {$ifdef DEBUG_UNIT_INITIALIZATION}
         writeln( 'Finalization of lbp_arp_buffer ended.');
      {$endif}
   end; // finalization


// ************************************************************************



end. // lbp_arp_buffer
