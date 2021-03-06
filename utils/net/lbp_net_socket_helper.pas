{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

<brief description of the file.  for exampl: Definition of common types>

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

// The Socket and INet units for Linux are incomplete and some routines are
//    broken.  This attempts to fill the gap until the production
//    FreePascal code is fixed.

{$WARNING  Socket helper may not be needed now!  Check the newest code!}

unit lbp_net_socket_helper;

// Some utility routines that don't fit elsewhere.

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

{$define KentUseLibC}
{$ifdef KentUseLibC}
   {$LINKLIB libc}
{$endif}

interface

uses
   lbp_types,  // ordinal types Int32, Int64, Word32, etc.
   lbp_lists,  // DoubleLinkedList type needed by GetInterfaceList()
   ctypes,
   strings,
   baseunix,
//   syscall,
   sysutils,
   errors,
   Sockets;


// ************************************************************************

type
   Word32Word8Array = record
      case byte of
         0: (Word32Value: Word32);
         1: (Word8Value:  array[ 0..3] of Word8);
   end;
   Word32Word8ArrayPtr = ^Word32Word8Array;

   Word64Word8Array = record
      case byte of
         0: (Word64Value: Word64);
         1: (Word8Value:  array[ 0..7] of Word8);
   end;
   Word64Word8ArrayPtr = ^Word64Word8Array;


// *************************************************************************

type
   // See man 7 ip
   in_addr = record          // Internet address (example: 131.123.20.1)
         s_addr:  cardinal;
      end;

   // See man 7 ip
   in_pktinfoPtr = ^in_pktinfo;
   in_pktinfo = record
         ipi_ifindex:    cardinal; // Interface index
         ipi_spec_dest:  in_addr;  // Local address
         ipi_addr:       in_addr;  // Header destination address
      end;

   // See man 2 readv
   iovecPtr = ^iovec;
   iovec = record
         iov_base: pointer;
         iov_len:  cardinal;
      end;

   // See man 2 recvmsg.  Look in /usr/include/bits/socket.h
   msghdr = record
         msg_name:       pointer;   // optional address
         msg_nameLen:    cardinal;  // size of the address
         msg_iov:        iovecPtr;  // scatter/gather array
         msg_iovlen:     cardinal;  // # elements in msg_iov
         msg_control:    pointer;   // ancillary data
         msg_controllen: cardinal;  // ancillary data buffer length
         msg_flags:      longint;   // flags on received message
      end;

   // See man 2 recvmsg.  Look in /usr/include/bits/socket.h
   cmsghdrPtr = ^cmsghdr;
   cmsghdr = record
         cmsg_len:    cardinal; // data byte count, including hdr
         cmsg_level:  longint;  // originating protocol
         cmsg_type:   longint;  // protocol-specific type
         cmsg_data:   byte;     // this is realy the first byte of an array
      end;                      // cmsg_len will tell us the size of the array




// *************************************************************************
// * Used for setting a filter on raw sockets.  From /usr/include/linux/filter.h
// *************************************************************************

type
   fpsock_filter = record
      code:    cuint16;
      jt:      cuint8;
      jf:      cuint8;
      k:       cuint32;
   end;

   BPFArray = array of fpsock_filter;  // Used for filtering raw sockets - BPF = Berkely Packet Filter

   fpsock_fprog = record
      len:     word;
      filter:  BPFArray;
   end;


// *************************************************************************
// * This section of types is used to get the MAC address of an ethernet
// * interface.
// *************************************************************************

const
   IFHWADDRLEN    = 6;
   IFNAMSIZ       = 16;
   SIOCGIFADDR    =  $8915;
   SIOCGIFNETMASK = $891b;
   AF_INET        = 2;
   SIOCGIFHWADDR  = $8927;
   SIOCGIFINDEX   = $8933;
   ARPHRD_ETHER   = 1;  // sa_family is Ethernet.

type
//   sockaddr = packed record
//         sa_family: word16;
//         sa_data:   array[ 0..13] of word8;
//      end; // sockaddr record

   ifreq = packed record
         ifrn_name: array[ 0..(IFNAMSIZ - 1)] of char;
         case Word8 of
            1:  (ifru_addr:      sockaddr);
            2:  (ifru_dstaddr:   sockaddr);
            3:  (ifru_broadaddr: sockaddr);
            4:  (ifru_netmask:   sockaddr);
            5:  (ifru_hwaddr:    sockaddr);
            6:  (ifru_flags:     word16);
            7:  (ifru_ifindex:   word32);
            8:  (ifru_ifmetric:  word32);
            9:  (ifru_mtu:       word32);
//           10: (ifru_map:       ifmap);
            11: (ifru_slave:     array[ 0.. (IFNAMSIZ - 1)] of char);
            12: (ifru_newname:   array[ 0..(IFNAMSIZ - 1)] of char);
            13: (ifru_data:      pchar);
      end; // ifreq record

type
   tInterfaceInfo = class
      public
         Name:          string;
         Index:         word32;
         MAC:           word64;
         IP:            word32;
         NetMask:       word32;
         constructor    Create( iName: string);
      end; // tInterfaceInfo class


function GetInterfaceInfo( InterfaceName: string): tInterfaceInfo;
function GetInterfaceList(): DoubleLinkedList;


// *************************************************************************

const
  // These values are used by functions which call SockCall()
  Socket_Sys_RECVFROM    = 12;
  Socket_Sys_SENDMSG     = 16;
  Socket_Sys_RECVMSG     = 17;
  ControlMsgSize        = SizeOf( cmsghdr) + SizeOf( in_pktinfo) - 1;


// *************************************************************************

const
   // Used for Packet socket types.  See 'man 7 packet'.
   AF_PACKET       = 17;

   ETH_P_LOOP      = $0060;  // Ethernet Loopback packet
   ETH_P_PUP       = $0200;  // Xerox PUP packet
   ETH_P_PUPAT     = $0201;  // Xerox PUP Addr Trans packet
   ETH_P_IP        = $0800;  // Internet Protocol packet
   ETH_P_X25       = $0805;  // CCITT X.25
   ETH_P_ARP       = $0806;  // Address Resolution packet
   ETH_P_BPQ       = $08FF;  // G8BPQ AX.25 Ethernet Packet
                             //       [ NOT AN OFFICIALLY REGISTERED ID ]
   ETH_P_IEEEPUP   = $0a00;  // Xerox IEEE802.3 PUP packet
   ETH_P_IEEEPUPAT = $0a01;  // Xerox IEEE802.3 PUP Addr Trans packet
   ETH_P_DEC       = $6000;  // DEC Assigned proto
   ETH_P_DNA_DL    = $6001;  // DEC DNA Dump/Load
   ETH_P_DNA_RC    = $6002;  // DEC DNA Remote Console
   ETH_P_DNA_RT    = $6003;  // DEC DNA Routing
   ETH_P_LAT       = $6004;  // DEC LAT
   ETH_P_DIAG      = $6005;  // DEC Diagnostics
   ETH_P_CUST      = $6006;  // DEC Customer use
   ETH_P_SCA       = $6007;  // DEC Systems Comms Arch
   ETH_P_RARP      = $8035;  // Reverse Addr Res packet
   ETH_P_ATALK     = $809B;  // Appletalk DDP
   ETH_P_AARP      = $80F3;  // Appletalk AARP
   ETH_P_8021Q     = $8100;  // 802.1Q VLAN Extended Header
   ETH_P_IPX       = $8137;  // IPX over DIX
   ETH_P_IPV6      = $86DD;  // IPv6 over bluebook
   ETH_P_PPP_DISC  = $8863;  // PPPoE discovery messages
   ETH_P_PPP_SES   = $8864;  // PPPoE session messages
   ETH_P_MPLS_UC   = $8847;  // MPLS Unicast traffic
   ETH_P_MPLS_MC   = $8848;  // MPLS Multicast traffic
   ETH_P_ATMMPOA   = $884c;  // MultiProtocol Over ATM
   ETH_P_ATMFATE   = $8884;  // Frame-based ATM Transport over ethernet
                             //    over Ethernet
   ETH_P_EDP2      = $88A2;  // Coraid EDP2

   // Used for RAW socket calls (man 7 packet)
type
   sockaddr_ll = record
         sll_family:   word16;
         sll_protocol: word16;
         sll_ifindex:  int32;
         sll_hatype:   word16;
         sll_pkttype:  word8;
         sll_halen:    word8;
         sll_addr:     array[ 0..7] of word8;
      end; // sockaddr_ll record


// *************************************************************************

const
   // Constants used by setsocketoptions
   SOL_IP           = 0;
   SOL_SOCKET       = 1;

   SO_DEBUG         = 1;
   SO_REUSEADDR     = 2;
   SO_TYPE          = 3;
   SO_ERROR         = 4;
   SO_DONTROUTE     = 5;
   SO_BROADCAST     = 6;
   SO_SNDBUF        = 7;
   SO_RCVBUF        = 8;
   SO_KEEPALIVE     = 9;
   SO_OOBINLINE     = 10;
   SO_NO_CHECK      = 11;
   SO_PRIORITY      = 12;
   SO_LINGER        = 13;
   SO_BSDCOMPAT     = 14;
   SO_REUSEPORT     = 15;
   SO_PASSCRED      = 16;
   SO_PEERCRED      = 17;
   SO_RCVLOWAT      = 18;
   SO_SNDLOWAT      = 19;
   SO_RCVTIMEO      = 20;
   SO_SNDTIMEO      = 21;

   // Security levels - as per NRL IPv6 - don't actually do anything
   SO_SECURITY_AUTHENTICATION       = 22;
   SO_SECURITY_ENCRYPTION_TRANSPORT = 23;
   SO_SECURITY_ENCRYPTION_NETWORK   = 24;

   SO_BINDTODEVICE  = 25;
   SO_ATTACH_FILTER = 26;
   SO_DETACH_FILTER = 27;
   SO_PEERNAME      = 28;
   SO_TIMESTAMP     = 29;
   SCM_TIMESTAMP    = SO_TIMESTAMP;
   SO_ACCEPTCONN    = 30;

   // From /usr/include/bits/in.h
   IP_TOS             = 1;    // int; IP type of service and precedence.
   IP_TTL             = 2;    // int; IP time to live.
   IP_HDRINCL         = 3;    // int; Header is included with data.
   IP_OPTIONS         = 4;    // ip_opts; IP per-packet options.
   IP_ROUTER_ALERT    = 5;    // bool
   IP_RECVOPTS        = 6;    // bool
   IP_RETOPTS         = 7;    // bool
   IP_PKTINFO         = 8;    // bool
   IP_PKTOPTIONS      = 9;
   IP_PMTUDISC        = 10;   // obsolete name?
   IP_MTU_DISCOVER    = 10;   // int; see below
   IP_RECVERR         = 11;   // bool
   IP_RECVTTL         = 12;   // bool
   IP_RECVTOS         = 13;   // bool
   IP_MULTICAST_IF    = 32;   // in_addr; set/get IP multicast i/f
   IP_MULTICAST_TTL   = 33;   // u_char; set/get IP multicast ttl
   IP_MULTICAST_LOOP  = 34;   // i_char; set/get IP multicast loopback
   IP_ADD_MEMBERSHIP  = 35;   // ip_mreq; add an IP group membership
   IP_DROP_MEMBERSHIP = 36;   // ip_mreq; drop an IP group membership

   // From /usr/include/bits/socket.h
   MSG_OOB            = $01;   // Process out-of-band data.  */
   MSG_PEEK           = $02;   // Peek at incoming messages.  */
   MSG_DONTROUTE      = $04;   // Don't use local routing.  */
   MSG_TRYHARD        = MSG_DONTROUTE;
   MSG_CTRUNC         = $08;   // Control data lost before delivery.  */
   MSG_PROXY          = $10;   // Supply or ask second address.  */
   MSG_TRUNC          = $20;
   MSG_DONTWAIT       = $40;   // Nonblocking IO.  */
   MSG_EOR            = $80;   // End of record.  */
   MSG_WAITALL        = $100;  // Wait for a full request.  */
   MSG_FIN            = $200;
   MSG_SYN            = $400;
   MSG_CONFIRM        = $800;  // Confirm path validity.  */
   MSG_RST            = $1000;
   MSG_ERRQUEUE       = $2000; // Fetch message from error queue.  */
   MSG_NOSIGNAL       = $4000; // Do not generate SIGPIPE.  */
   MSG_MORE           = $8000; // Sender will send more.  */


// *************************************************************************

type
   // Storage for a cmsghdr which contains a in_pktinfo in its data part.
   PacketInfoControlMessagePtr = ^PacketInfoControlMessage;
   PacketInfoControlMessage    = array[ 0..(ControlMsgSize -1)] of byte;


// *************************************************************************


{$ifdef KentUseLibC}
function RecvFrom( Sock: Longint; Var Buf; Buflen,Flags: Longint; Var Addr;
                   var AddrLen: longint) : longint; cdecl; external name 'recvfrom';
function RecvMsg( Sock:                Longint;
                  Var MessageHeader:   msghdr;
                  Flags:               Longint): longint; cdecl; external name 'recvmsg';

function getsockopt( s:          int32;
                     level:      int32;
                     optname:    int32;
                     var optval;
                     var optlen: int32): int32; cdecl; external name 'getsockopt';
{$else}
function SocketCall(SockCallNr,a1,a2,a3,a4,a5,a6:longint):longint;

function RecvFrom( Sock: Longint; Var Buf; Buflen,Flags: Longint; Var Addr;
                   var AddrLen: longint) : longint;
function RecvMsg( Sock:                Longint;
                  Var MessageHeader:   msghdr;
                  Flags:               Longint): longint;

function getsockopt( s:          int32;
                     level:      int32;
                     optname:    int32;
                     var optval;
                     var optlen: int32): int32; cdecl; external;
{$endif}


// *************************************************************************

implementation


{$ifndef KentUseLibC}
// *************************************************************************
// * RecvFrom() - Recieve a packet and tell us the interface
// *************************************************************************

Function RecvFrom( Sock: Longint; Var Buf; Buflen,Flags: Longint; Var Addr;
                   var AddrLen: longint): longint;

   begin

      RecvFrom:= SocketCall( Socket_Sys_RECVFROM, Sock, Longint(@buf),
                             buflen, flags, Longint(@Addr), LongInt(@AddrLen));
   end; // RecvFrom()


// *************************************************************************
// * RecvMsg() - Recieve a message from the socket
// *************************************************************************

Function RecvMsg( Sock:                Longint;
                  Var MessageHeader:   msghdr;
                  Flags:               Longint): longint;

   begin

      RecvMsg:= SocketCall( Socket_Sys_RECVMSG, Sock,
                            Longint(@MessageHeader), Flags, 0, 0, 0);
   end; // RecvMsg()


// *************************************************************************
// * SocketCall() - Performs the Linux syscall() for sockets
// *************************************************************************

Function SocketCall(SockCallNr,a1,a2,a3,a4,a5,a6:longint):longint;
   var
      Args:array[1..6] of longint;
   begin
      args[1]:= a1;
      args[2]:= a2;
      args[3]:= a3;
      args[4]:= a4;
      args[5]:= a5;
      args[6]:= a6;
      SocketCall:=do_Syscall( syscall_nr_socketcall, sockcallnr,
                              longint(@args));
      If SocketCall < 0 then
         SocketError:=fpgetErrno
      else
      SocketError:= 0;
   end;
{$endif}  // ifndef KentUseLibC


// *************************************************************************
// * GetInterfaceList() - Returns a DoubleLinkedList of network interface
// *                      names.
// *************************************************************************

function GetInterfaceList(): DoubleLinkedList;
   var
      Temp:          tInterfaceInfo;
      F:             Text;
      InterfaceName: string;
      Line:          string;
      i:             integer;
      j:             integer;
      L:             integer;
   begin
      result:= DoubleLinkedList.Create();

      assign( F, '/proc/net/dev');
      reset( F);
      ReadLn( F, Line);
      ReadLn( F, Line);
      // For each interface name
      while( not EOF( F)) do begin
         ReadLn( F, Line);
         L:= length( Line);
         i:= 1;
         while( (i <= L) and (Line[ i] = ' ')) do begin
            inc( i);
         end;
         j:= i + 1;
         while( (j <= L) and (Line[ j] <> ':')) do begin
            inc( j);
         end;

         InterfaceName:= System.Copy( Line, i, j - i);
         Temp:= GetInterfaceInfo( InterfaceName);
         result.Enqueue( Temp);
      end;
      close( F);
   end; // GetInterfaceList;


// *************************************************************************
// * GetInterfaceInfo() - Returns the named network interface's information.
// *                      Currently, MAC address and interface index number
// *************************************************************************

function GetInterfaceInfo( InterfaceName: string): tInterfaceInfo;
   var
      IFInfo:      ifreq;
      SockInfo:    sockaddr;
      L:           integer;
      FileHandle:  int32;
      TempMAC:     Word64Word8Array;
      TempNetMask: Word32Word8Array;
      TempIP:      Word32Word8Array;
      TempIndex:   word32;
      i:           integer;
   begin
      L:= length( InterfaceName);
      if(( L = 0) or ( L > IFNAMSIZ)) then begin
         result:= nil;
         exit;
      end;
      FileHandle:= fpSocket( AF_INET, SOCK_DGRAM, 0);

      
      // First find the NIC or MAC address.
      FillByte( IFInfo, sizeof( IFInfo), 0);
      // Note!  In the following call, the trailing null char MAY
      //        overwrite the first byte of storage after
      //        IFInfo.ifrn_name.  This is not a problem here.
      StrPCopy( IFInfo.ifrn_name, InterfaceName);


      if( fpIOCtl( FileHandle, SIOCGIFHWADDR, @IFInfo) < 0) then begin
         result:= nil;
         exit;
      end;

      SockInfo:= IFInfo.ifru_hwaddr;

      if( SockInfo.sa_family <> ARPHRD_ETHER) then begin
         raise Exception.Create(
            'lbp_socket_helper.GetInterfaceInfo():  Hardware adress sa_family has an invalid value.');
      end;

      {$ifdef ENDIAN_LITTLE}
         TempMAC.Word64Value:= 0;
         for i:= 0 to 5 do begin
            TempMAC.Word8Value[ i ]:= SockInfo.sa_data[ 5 - i];
         end;
      {$else}  // ENDIAN_LITTLE
         for i:= 0 to 5 do begin
            TempMAC.Word8Value[ i ]:= SockInfo.sa_data[ i];
         end;
      {$endif} // ENDIAN_LITTLE

      // Now Find the interface's index
      FillByte( IFInfo, sizeof( IFInfo), 0);
      // Note!  In the following call, the trailing null char MAY
      //        overwrite the first byte of storage after
      //        IFInfo.ifrn_name.  This is not a problem here.
      StrPCopy( IFInfo.ifrn_name, InterfaceName);

      if( fpIOCtl( FileHandle, SIOCGIFINDEX, @IFInfo) < 0) then begin
         raise Exception.Create(
            'lbp_socket_helper.GetInterfaceInfo():  SIOCGIFINDEX failed:  ' + StrError( errno));
      end;

      TempIndex:= IFInfo.ifru_ifindex;

      // Find the IP Address
      FillByte( IFInfo, sizeof( IFInfo), 0);
      // Note!  In the following call, the trailing null char MAY
      //        overwrite the first byte of storage after
      //        IFInfo.ifrn_name.  This is not a problem here.
      StrPCopy( IFInfo.ifrn_name, InterfaceName);


      if( fpIOCtl( FileHandle, SIOCGIFADDR, @IFInfo) < 0) then begin
         raise Exception.Create(
            'lbp_socket_helper.GetInterfaceInfo():  SIOCGIFADDR failed:  ' + StrError( errno));
      end;

      SockInfo:= IFInfo.ifru_addr;

      if( SockInfo.sa_family <> AF_INET) then begin
         raise Exception.Create(
            'lbp_socket_helper.GetInterfaceInfo():  IP adress sa_family has an invalid value.');
      end;

      {$ifdef ENDIAN_LITTLE}
         TempIP.Word32Value:= 0;
         for i:= 0 to 3 do begin
            TempIP.Word8Value[ i ]:= SockInfo.sa_data[ 5 - i];
         end;
      {$else}
         TempIP.Word32Value:= 0;
         for i:= 0 to 3 do begin
            TempIP.Word8Value[ i ]:= SockInfo.sa_data[ 2 +  i];
         end;
      {$endif}

      // Find the netmask
      FillByte( IFInfo, sizeof( IFInfo), 0);
      // Note!  In the following call, the trailing null char MAY
      //        overwrite the first byte of storage after
      //        IFInfo.ifrn_name.  This is not a problem here.
      StrPCopy( IFInfo.ifrn_name, InterfaceName);


      if( fpIOCtl( FileHandle, SIOCGIFNETMASK, @IFInfo) < 0) then begin
         raise Exception.Create(
            'lbp_socket_helper.GetInterfaceInfo():  SIOCGIFNETMASK failed:  ' + StrError( errno));
      end;

      SockInfo:= IFInfo.ifru_addr;

      if( SockInfo.sa_family <> AF_INET) then begin
         raise Exception.Create(
            'lbp_socket_helper.GetInterfaceInfo():  Netmask sa_family has an invalid value.');
      end;

      {$ifdef ENDIAN_LITTLE}
         TempNetMask.Word32Value:= 0;
         for i:= 0 to 3 do begin
            TempNetMask.Word8Value[ i ]:= SockInfo.sa_data[ 5 - i];
         end;
      {$else}
         TempNetMask.Word32Value:= 0;
         for i:= 0 to 3 do begin
            TempNetMask.Word8Value[ i ]:= SockInfo.sa_data[ 2 + i];
         end;
      {$endif}

      result:= tInterfaceInfo.Create( InterfaceName);
      result.MAC:= TempMAC.Word64Value;
      result.Index:= TempIndex;
      result.IP:= TempIP.Word32Value;
      result.NetMask:= TempNetMask.Word32Value;
   end; // GetInterfaceInfo()


// -------------------------------------------------------------------------
// - tInterfaceInfo
// -------------------------------------------------------------------------
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tInterfaceInfo.Create( iName: string);
   begin
      inherited Create();
      Name:=    iName;
      MAC:=     0;
      Index:=   0;
      IP:=      0;
      NetMask:= 0;
   end; // Create()


// *************************************************************************

end. // lbp_socket_helper unit
