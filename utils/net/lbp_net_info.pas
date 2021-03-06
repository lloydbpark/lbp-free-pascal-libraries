{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Get network interface information from ipconfig command.

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

// This unit should be updated to not rely on an external program.

unit lbp_net_info;

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   lbp_types,
   lbp_utils,  // StripSpaces()
   lbp_ip_utils, // IP Conversion
   lbp_ip_network,
   lbp_lists,
   baseunix,
   unix;


// =========================================================================
// = tNetInterfaceInfo - Store network device information
// =========================================================================

type
   tNetInterfaceInfo = class
      private
         MyName:        string;
         MyMAC:         word64;
         MyBroadcast:   word64;
         MyIsUp:        boolean;
         MyIsBroadcast: boolean;
         MyIsEthernet:  boolean;
         MyIPList:      DoubleLinkedList;
         function       GetMACStr:       string;
         procedure      SetMACstr( const S: string);
         function       GetBroadcastStr: string;
         procedure      SetBroadcastStr( const S: string);
      public
         constructor Create( const iName: string);
         destructor  Destroy(); override;
         property Name:         string read  MyName       write MyName;
         property MAC:          word64 read  MyMAC        write MyMAC;
         property MACstr:       string read  GetMACStr    write SetMACStr;
         property Broadcast:    word64 read  MyBroadcast  write MyBroadcast;
         property BroadcastStr: string read  GetBroadcastStr
                                       write SetBroadcastStr;
         property IsUp:         boolean read MyISUp       write MyIsUp;
         property IsBroadcast:  boolean read MyIsBroadcast write MyIsBroadcast;
         property IsEthernet:   boolean read MyIsEthernet write MyIsEthernet;
         property IPList:       DoubleLinkedList read MyIPList write MyIPList;
      end; // tNetInterfaceInfo

// *************************************************************************

var
   // A list of the local host's network interfaces (tNetInterfaceInfo)
   NetInterfaceList: DoubleLinkedList;

function   GetNetInterfaceInfo( Name: string): tNetInterfaceInfo;

// Return the first IP address associated with the named interface.
function   GetNetInterfaceIP( Name: string):   word32;

// *************************************************************************

implementation

// =========================================================================
// = tNetInterfaceInfo - Store network device information
// =========================================================================
// *************************************************************************
// * Create()
// *************************************************************************

constructor tNetInterfaceInfo.Create( const iName: string);
   begin
      MyName:= iName;
      MyIPList:= DoubleLinkedList.Create();
      MyIsUp:= false;
      MyIsBroadcast:= false;
      MyIsEthernet:= false;
   end; // Create()


// *************************************************************************
// * Destroy()
// *************************************************************************

destructor tNetInterfaceInfo.Destroy();
   var
      NetworkInfo: tNetworkInfo;
   begin
      // Clear out our IP List and destroy it.
      while( not MyIPList.Empty) do begin
         NetworkInfo:= tNetworkInfo( MyIPList.Dequeue());
         NetworkInfo.Destroy;
      end;
      MyIPList.Destroy();
   end; // Destroy()


// *************************************************************************
// * GetMACstr() - Returns the MAC broadcast address for this interface in
// *               string format.
// *************************************************************************

function tNetInterfaceInfo.GetMACstr(): string;
   begin
      result:= MACWord64ToString( MyMAC);
   end; // GetMACstr()


// *************************************************************************
// * SetMACstr() - Set the MAC broadcast from a string representation of the
// *               word64 value.
// *************************************************************************

procedure tNetInterfaceInfo.SetMACstr( const S: string);
   begin
      MyMAC:= MACStringToWord64( S);
   end; // SetMACstr()


// *************************************************************************
// * GetBroadcastStr() - Returns the MAC broadcast address for this
// *                     interface in string format.
// *************************************************************************

function tNetInterfaceInfo.GetBroadcastStr(): string;
   begin
      result:= MACWord64ToString( MyBroadcast);
   end; // GetBroadcastStr()


// *************************************************************************
// * SetBroadcastStr() - Set the MAC broadcast from a string representation
// *                     of the word64 value.
// *************************************************************************

procedure tNetInterfaceInfo.SetBroadcastStr( const S: string);
   begin
      MyBroadcast:= MACStringToWord64( S);
   end; // SetBroadcastStr()



// =========================================================================
// = Global procedures
// =========================================================================
// *************************************************************************
// * ParseDevice() - Handle reading the Device line from IP addr list.
// *                 Called by DiscoverNetworkInterfaces().  Returns
// *                 the tNetworkInterfaceInfo from InterfaceList which
// *                 matches the name in the parsed line.
// *************************************************************************

function ParseDevice( const Line:   String;
                      InterfaceList: DoubleLinkedList): tNetInterfaceInfo;
   var
      iStart:  integer;  // starting index in a string
      iEnd:    integer;  // ending index in a string
      Len:     integer;  // Length of Line
      DevName: string;
      Flags:   string;
      Temp:    string;
   begin
      Len:= Length( Line);
      // Find the Device name in the line.
      iStart:= 1;
      while( (iStart < Len) and (Line[ iStart] <> ':'))do inc( iStart);
      inc( iStart);
      iEnd:= iStart;
      while( (iEnd < Len) and
            ((Line[ iEnd] <> ':') and (Line[ iEnd] <> '@'))) do inc( iEnd);
      DevName:= copy( Line, iStart, iEnd - iStart);
      StripSpaces( DevName);

      // Now find the device in our InterfaceList
      result:= tNetInterfaceInfo( InterfaceList.GetFirst());
      while( (result <> nil) and (DevName  <> result.Name)) do begin
         result:= tNetInterfaceInfo( InterfaceList.GetNext());
      end;

      if( result = nil) then begin
         raise lbp_exception.Create( 'Error parsing ''ip addr list'' line');
      end;

      // Now find UP, BROADCAST flags.
      //    Get the Flags section
      iStart:= pos( '<', Line) + 1;
      iEnd:=   pos( '>', Line);
      Flags:= copy( Line, iStart, iEnd - iStart);

      // Now parse the flags
      iStart:= 1;
      iEnd:= 1;
      Len:= length( Flags);
      while( iEnd <= Len) do begin
         while( (iEnd <= Len) and (Flags[ iEnd] <> ',')) do begin
            inc( iEnd);
         end;
         // Found a single flag
         Temp:= copy( Flags, iStart, iEnd - iStart);
         inc( iEnd);
         iStart:= iEnd;

         // Act on each flag
         if( Temp = 'BROADCAST') then begin
            result.IsBroadcast:= true;
         end else if( Temp = 'UP') then begin
            result.IsUp:= true;
         end;
      end;
   end; //ParseDevice()


// *************************************************************************
// * ParseLink() - Handle reading the link information.  Called by
// *               DiscoverNetworkInterfaces()
// *************************************************************************

procedure ParseLink( Line: String; IFInfo: tNetInterfaceInfo);
   var
      iStart:  integer;  // starting index in a string
      iEnd:    integer;  // ending index in a string
      Len:     integer;  // Length of Line
      Temp:    string;
   begin
      Len:= length( Line);

      // Find out if it is an ethernet interface.
      iStart:= 1;
      while( (iStart <= Len) and (Line[ iStart] <> '/')) do inc( iStart);
      inc( iStart);
      iEnd:= iStart;
      while( (iEnd <= Len) and (Line[ iEnd] <> ' ')) do inc( iEnd);
      Temp:= copy( Line, iStart, iEnd - iStart);
      if( Temp = 'ether') then IFInfo.IsEthernet:= true;

      // Find the MAC address
      inc( iEnd);
      iStart:= iEnd;
      while( (iEnd <= Len) and (Line[ iEnd] <> ' ')) do inc( iEnd);
      Temp:= copy( Line, iStart, iEnd - iStart);
      IFInfo.MACstr:= Temp;

      // Find the MAC broadcast address
      inc( iEnd);
      while( (iEnd <= Len) and (Line[ iEnd] <> ' ')) do inc( iEnd);
      inc( iEnd);
      iStart:= iEnd;
      while( (iEnd <= Len) and (Line[ iEnd] <> ' ')) do inc( iEnd);
      Temp:= copy( Line, iStart, iEnd - iStart);
      IFInfo.BroadcastStr:= Temp;
   end; // ParseLink()


// *************************************************************************
// * ParseInet() - Handle reading the Inet information.  Called by
// *               DiscoverNetworkInterfaces()
// *************************************************************************

procedure ParseInet( Line: String; IFInfo: tNetInterfaceInfo);
   var
      iStart:  integer;  // starting index in a string
      iEnd:    integer;  // ending index in a string
      Len:     integer;  // Length of Line
      Temp:    string;
      NetInfo: tNetworkInfo;
   begin
      Len:= length( Line);

      // Find the IP Address/prefix part
      iStart:= 1;
      while( (iStart <= Len) and (Line[ iStart] <> ' ')) do inc( iStart);
      inc( iStart);
      iEnd:= iStart;
      while( (iEnd <= Len) and (Line[ iEnd] <> ' ')) do inc( iEnd);
      Temp:= copy( Line, iStart, iEnd - iStart);

      NetInfo:= tNetworkInfo.Create( Temp);
      IFInfo.IPList.Enqueue( NetInfo);
   end; // ParseInet()


// *************************************************************************
// * DiscoverNetworkInterfaces() - Read the Linux /proc/net/dev file to find
// *                               all our network interfaces.
// *************************************************************************

const DevFileName = '/proc/net/dev';
const IPAddrCmd   = '/sbin/ip addr list';

procedure DiscoverNetworkInterfaces( InterfaceList: DoubleLinkedList);
   var
      F:        Text;
      Temp:     string;
      IFInfo:   tNetInterfaceInfo;
      ColonPos: integer;
   begin
      assign( F, DevFileName);
      reset( F);

      // Throw away the header lines;
      Readln( F);
      Readln( F);

      // Read each device line and get it's name.
      while not EOF( F) do begin
         readln( F, Temp);
         ColonPos:= pos( ':', Temp);
         if( ColonPos > 1) then begin
            setlength( Temp, ColonPos - 1);
            StripSpaces( Temp);
            IFInfo:= tNetInterfaceInfo.Create( Temp);
            InterfaceList.Enqueue( IFInfo);
         end;
      end;

      close( F);

      // Get IP and link information for each device.
      // Pipe 'ip addr list' to F.
      popen( F, IPAddrCmd, 'R');
      {$WARNING The reset(f) below prevents crashes on some versions of linux, but causes this to fail for others!}
//      reset( F);
      try
         while not EOF( F) do begin
            readln( F, Temp);
            if( Temp[ 1] in ['0'..'9']) then begin
               // Find an interface in our list which matches the name.
               IFInfo:= ParseDevice( Temp, InterfaceList);
            end else begin
               StripSpaces( Temp);
               if( pos( 'link', Temp) = 1) then begin
                  ParseLink( Temp, IFInfo);
               end else if( pos( 'inet ', Temp) = 1) then begin
                  ParseInet( Temp, IFInfo);
               end;
            end;
         end;
      finally
         pclose( F);
      end; // try/finally
   end; // DiscoverNetworkInterfaces()


// *************************************************************************
// * GetNetInterfaeInfo() - Returns the named network interface information.
// *************************************************************************

function   GetNetInterfaceInfo( Name: string): tNetInterfaceInfo;
   var
      Info: tNetInterfaceInfo;
   begin
      Info:= tNetInterfaceInfo( NetInterfaceList.GetFirst());
      while( ( Info <> nil) and (Info.Name <> Name)) do begin
         Info:= tNetInterfaceInfo( NetInterfaceList.GetNext());
      end;

      if( Info = nil) then begin
         writeln( StdErr, 'Invalid interface name: ' + Name);
         raise lbp_exception.Create( 'Invalid interface name: ' + Name);
      end;
      result:= Info;

   end; // GetNetInterfacInfo()


// *************************************************************************
// * GetNetInterfaceIP() - Return the first IP address associated with the
// *                       named interface.  Returns 0 on failure.
// *************************************************************************

function   GetNetInterfaceIP( Name: string):   word32;
   var
      NetInfo:       tNetworkInfo;
      InterfaceInfo: tNetInterfaceInfo;
   begin
      InterfaceInfo:= GetNetInterfaceInfo( Name);
      NetInfo:= tNetworkInfo( InterfaceInfo.IPList.GetFirst());
      if( NetInfo = nil) then begin
         result:= 0;
      end else begin
         result:= NetInfo.IPAddr;
      end;
   end; // GetNetInterfaceIP()


// =========================================================================
// = Initialization/Finalization
// =========================================================================

var
   IFInfo:  tNetInterfaceInfo;

// *************************************************************************
// * Initialization
// *************************************************************************

initialization
   begin
      NetInterfaceList:= DoubleLinkedList.Create();
      DiscoverNetworkInterfaces( NetInterfaceList);
   end; // initialization


// *************************************************************************
// * Finalization
// *************************************************************************

finalization
   begin
      // Clean up the InterfaceList and display our results.
      while( not NetInterfaceList.Empty()) do begin
         IFInfo:= tNetInterfaceInfo( NetInterfaceList.Dequeue());
         IFInfo.Destroy();
      end;
      NetInterfaceList.Destroy();
   end; // finalization


// *************************************************************************

end.  // lbp_net_info unit
