{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Read and write ARP packets

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

// Recieve and transmit ARP packets

unit lbp_arp_socket;
{$WARNING This unit is just a copy of lbp_dhcp_socket with a find and replace of DHCP to ARP.  It needs to be converted to ARP functionality}


{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}      // Non-sized Strings are ANSI strings
//{$RANGECHECKS OFF}     // The HostToNet function works with int32
                       // instead of word32 and so generates rangechecks
                       // with my word32 IP Addresses.  Ignoring the
                       // errors works fine.

interface
uses
   lbp_types,        // word32, etc
   lbp_arp_buffer,
   lbp_net_socket_helper,
   lbp_net_fields,
   lbp_log,
//   lbp_utils,
   lbp_ip_utils,
//   NetDB,
   sysutils,
   errors,
   baseunix,
   unixtype,
   sockets;


// *************************************************************************

const
   ARPServerPortNumber = 67;
   ARPClientPortNumber = 68;


// *************************************************************************

type
   ARPSocketException = class( lbp_exception);

var
   ArpBpf: array [1..4] of fpsock_filter = (
      ( code:$28; jt:0;   jf:0;   k:$0000000C ),
      ( code:$15; jt:0;   jf:1;   k:$00000806 ),
      ( code:$06; jt:0;   jf:0;   k:$0000FFFF ),
      ( code:$06; jt:0;   jf:0;   k:$00000000 )
   ); // ArpBpf


// *************************************************************************
// * tARPSocket class
// *    It is assumed only one thread will read packets from this socket.
// *    But it is possible multiple threads will want to write to the socket.
// *    Therefore, WritePacket is protected.
// *************************************************************************

type
   tARPSocket = class
      private
         MyFilter:        fpsock_fprog; // Used to filter raw sockets.
         MyIFReq:         ifreq;        // Used to bind device to socket.
         WritePacketCS:   TRTLCriticalSection;  // Makes WritePacket thread safe.
      public
         Opened:          boolean;
         MySocket:        int32;    // UNIX file handle
         MyLocalPort:     int32;
         MyMAC:           string; // String representation of our MAC address
         MyInterfaceName: string;
{$WARNING I would like to remove InterfaceInfo and replace it with more usable individual variables.  That way all the conversion can be done on creation and not on sending each packet.}
         InterfaceInfo:   tInterfaceInfo;
         EthAddr:         sockaddr_ll;
         MyIP:            word32;
         InterfaceIndex:  word32;
         myTimeoutSec:    int32;
         MyTimeoutMicro:  int32;
      public
         constructor Create( IFInfo: tInterfaceInfo; LocalPort: word16);
         destructor  Destroy();                   override;
         function    ReadPacket( ARPBuffer: tARPBuffer): boolean; virtual;
         procedure   WritePacket( ARPBuffer:    tARPBuffer); virtual;
         procedure   SetSocketTimeout( MilliSeconds: int32); virtual;
      protected
         procedure   Open();                      virtual;
         procedure   Close();                     virtual;
         procedure   SetInetSocketOption( Level: longint; Opt: longint;
                                          State: boolean);
         function    GetOpened(): boolean;        virtual;
         procedure   SetOpened( B: boolean);      virtual;
         procedure   SetRawFilter( F: array of fpsock_filter); virtual;
      public
         property    IsOpen: boolean read GetOpened write SetOpened;
      end; // tARPSocket class


// *************************************************************************

implementation

// -------------------------------------------------------------------------
// - tARPSocket
// -------------------------------------------------------------------------
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tARPSocket.Create( IFInfo: tInterfaceInfo; LocalPort: word16);
   begin
      inherited Create();
      MyLocalPort:= LocalPort;
      InterfaceInfo:= IFInfo;
      MyMAC:= MACWord64ToString( IFInfo.MAC, ':', 16); // No separators
      MyInterfaceName:= IFInfo.Name;
      Opened:= false;
      MySocket:= 0;
      myTimeoutSec:= 0;
      MyTimeoutMicro:= 0;
      InitCriticalSection( WritePacketCS);
   end; // Create()


// *************************************************************************
// * Destroy() - Destructor
// *************************************************************************

destructor tARPSocket.Destroy();
   begin
      IsOpen:= false;
      DoneCriticalSection( WritePacketCS);
      inherited Destroy()
   end; // Destroy()


// *************************************************************************
// * ReadPacket() - Read a RAW packet and into ARPBuffer
// *                 - Does not decode the packet!
// *************************************************************************

function tARPSocket.ReadPacket( ARPBuffer: tARPBuffer): boolean;
   var
      timeval:    unixtype.timeval;
      tvresult:   cint;
      Count:      int32;
   begin
      // Set the timeout before each read
      if( (MyTimeoutSec <> 0) or (MyTimeoutMicro <> 0)) then begin
         timeval.tv_sec:= MyTimeoutSec;
         timeval.tv_usec:= MyTimeoutMicro;
         tvresult:= fpsetsockopt( MySocket, SOL_SOCKET, SO_RCVTIMEO, @timeval, sizeof( timeval));
         if( tvresult <> 0) then begin
            raise ARPSocketException.Create( 
               'Error setting the read timeout on the ARP socket:  ' +
               StrError( SocketError));
         end;
      end;

      // Read the packet and the extra interface info
      Count:=fprecv( MySocket, @ARPBuffer.Buffer[ 0], ARPMaxPacketSize, 0);
      if( Count < 0) then begin
         result:= false;
         if( SocketError = ESysEAGAIN) then begin
            exit;
         end else begin
            raise ARPSocketException.Create(
               'Error reading from ARP socket:  ' +
               StrError( SocketError));
         end;
      end;

      ARPBuffer.BuffEndPos:= Count - 1;

      // We can't log packets because if we are using a remote shell and
      // logging to the terminal, each log produces at least one packet
      // which is read by this routine and logged again.  Infinite loop.
      // Log( LOG_INFO, '%d byte ARP(?) Packet was read.', [Count]);

      result:= true;
   end; // ReadPacket()


// *************************************************************************
// * WritePacket() - Send the Buffer of ARPBuffer using a raw socket.
// *************************************************************************

procedure tARPSocket.WritePacket( ARPBuffer:    tARPBuffer);
   var
      SendToResult:    int32;
      i:               integer;
   begin
      // It seems brain dead to me, but even though we have bound the socket
      // to an interface and we are sending a raw socket which includes the 
      // ethernet header, we are still forced to fill out a sockaddr_ll
      // record in order to send the packet.
      with EthAddr do begin
         sll_family:=   0;
         sll_protocol:= 0;
         sll_ifindex:= InterfaceInfo.Index;
         sll_hatype:=   0;
         sll_pkttype:=  0;
         sll_halen:=    6;
         for i:= 0 to 5 do begin
            sll_addr[ i]:= ARPBuffer.EthHdr.DstMAC.Value[ i]; 
         end;   
      end;
      
      EnterCriticalSection( WritePacketCS);
      SendToResult:= fpsendto( MySocket, @ARPBuffer.Buffer[ 0],
                              ARPBuffer.BuffEndPos + 1, 0,
                              @EthAddr, sizeof( EthAddr));
      LeaveCriticalSection( WritePacketCS);
      if( SendToResult < 0) then begin
         raise ARPSocketException.Create(
            'Error sending on ARP socket (%d): ' +
            StrError( fpGetErrno), [FPGetErrno]);
      end;

      Log( LOG_INFO, '%d byte ARP Packet was sent to %s.',
         [SendToResult, ARPBuffer.IPHdr.DstIP.StrValue]);
   end; // WritePacket()


// *************************************************************************
// * SetInetSocketOption() - Set a single inet socket option.
// *************************************************************************

procedure tARPSocket.SetInetSocketOption( Level: longint;
                                           Opt:   longint;
                                           State: boolean);
   var
      OptValue: longint;
   begin
      if( State) then begin
         OptValue:= 1;
      end else begin
         OptValue:= 0;
      end;

      fpSetSockOpt( MySocket, Level,
                    Opt, @OptValue, sizeof( OptValue));

      if( SocketError <> 0) then begin
         raise ARPSocketException.Create(
            'Error setting inet socket option: %d  %s',
            [Opt, StrError( SocketError)]);
      end;
   end; // SetInetSocketOption();



// *************************************************************************
// * SetSocketTimeout() - Sets the timeout for our socket.
// *************************************************************************

procedure tARPSocket.SetSocketTimeout( MilliSeconds: int32);
   begin
      MyTimeoutSec:=   Milliseconds div 1000;
      MyTimeoutMicro:= (Milliseconds mod 1000) * 1000;
   end; // SetSocketTimeout


// *************************************************************************
// * SetRawFilter() - Only used for raw sockets and it must be called before
// *                  the socket is opened.
// *************************************************************************

procedure tARPSocket.SetRawFilter( F: array of fpsock_filter);
   var
      i: integer;
      L: integer;
   begin
      L:= length( F);
      MyFilter.len:= L;
      SetLength( MyFilter.filter, L);
      Dec( L);
      for i:= 0 to L do begin
         MyFilter.filter[i]:= F[ i];
      end;
   end; // SetRawFilter()


// *************************************************************************
// * Open() - Open the socket for sending packets
// *************************************************************************

procedure tARPSocket.Open();
   begin
      try
         MySocket:= fpSocket( PF_PACKET, SOCK_RAW, htons(ETH_P_IP));
         if( MySocket < 0) then begin
            raise ARPSocketException.Create( 'Error opening the ARP socket!  ' +
                                             StrError( SocketError));
         end;
         Opened:= true;

         // Attach the filter to the socket
         if( MyLocalPort = ARPClientPortNumber) then begin
            ClientBPF[ 24].k:= Lo( InterfaceInfo.MAC);
            ClientBPF[ 26].k:= Hi( InterfaceInfo.MAC);
            SetRawFilter( ClientBPF);
         end else begin
            raise ARPSocketException.Create( 'tARPSocket.Open() - Server socket initialization not yet supported!'); 
         end;
         if( fpsetsockopt( MySocket, SOL_SOCKET, SO_ATTACH_FILTER, @MyFilter, sizeof( MyFilter))) < 0 then begin
            raise ARPSocketException.Create( 'Error attaching the filter to the ARP socket!  ' +
                                             StrError( SocketError));
         end;
   
         // Bind the socket to a particular device
         FillDWord( MyIFReq, 8, 0); // ethreq should be 32 bytes and a DWord is 4
         StrPCopy( MyIFReq.ifrn_name, InterfaceInfo.Name);
         if( fpsetsockopt( MySocket, SOL_SOCKET, SO_BINDTODEVICE, @MyIFReq, sizeof( MyIFReq)) < 0) then begin
            raise ARPSocketException.Create( 'Error binding the ARP socket to the ethernet device!  ' +
                                             StrError( SocketError));
         end;

      Except
         On E: Exception do begin
            if( IsOpen) then IsOpen:= false;
            raise E;
         end;
      end; // try/Except
   end; // Open();


// *************************************************************************
// * Close()
// *************************************************************************

procedure tARPSocket.Close();
   begin
      if( Opened) then begin
         Opened:= false;
         if( CloseSocket( MySocket) <> 0) then begin
            raise ARPSocketException.Create( 'Error closing ARP socket!');
         end;
      end;
      MySocket:= 0;
   end; // Close()


// *************************************************************************
// * GetOpened()
// *************************************************************************

function tARPSocket.GetOpened(): boolean;
   begin
      result:= Opened;
   end; // GetOpened()


// *************************************************************************
// * SetOpened()
// *************************************************************************

procedure tARPSocket.SetOpened( B: boolean);
   begin
      if( Opened and (not B)) then begin
         Close();
      end else if( (not Opened) and B) then begin
         Open();
      end;
   end; // SetOpened()


// -------------------------------------------------------------------------
// - Unit initialization and finalization
// -------------------------------------------------------------------------
// *************************************************************************
// *************************************************************************
// *************************************************************************
// *************************************************************************

end. // lbp_arp_socket unit
