{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

define a container class to hold IP address information

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

unit lbp_ip_network;

// A simple unit to hold the tNetworkInfo class which holds an IP address
// netmask, prefix, network number, and broadcast address.

interface

{$include lbp_standard_modes.inc}

uses
   lbp_types, // show_debug boolean
   lbp_ip_utils,
   lbp_binary_trees, // IP Conversion
   sysutils;   // Format()


// =========================================================================
// = Global variable to control how LongDump works
// =========================================================================

var
   SkipEmptyVlan: boolean = true;


// =========================================================================
// = tNetworkInfo - Store network numbers and netmasks
// =========================================================================

type
   tNetworkInfo = class
      private
         MyIPAddr:         word32;
         MyNetMask:        word32;
         MyZoneCount:      integer;
         MyZoneIndex:      word;
         MyZoneInc:        word32;   // How much to increment the Network Number for the next DNS Zone.
         MyZonePrefix:     word32;
         MyPrefix:         word;
         MyGateway:        word32;
         MyComment:        string;
         MyVLAN:           string;
         MyVLANID:         word;
         MyL2InVLan:       string;
         MyL2InVlanId:     word;
         MyEsxiVlan:       string;   // VMware VLAN/Network Name
         MyPaloZone:       string;
         MyPaloL2InZone:   string;
         function  GetNetNum(): word32;
         procedure SetNetMask( const W: word32);
         procedure SetPrefix( const W: word);
         function  GetNetNumStr(): string;
         function  GetIPAddrStr(): string;
         procedure SetIPAddrStr( const S: string);
         function  GetNetMaskStr(): string;
         procedure SetNetMaskStr( const S: string);
         function  GetFullStr(): string;
         procedure SetFullStr( const S: string);
         function  GetPrefixStr(): string;
         procedure SetPrefixStr( const S: string);
         function  GetGatewayStr(): string;
         procedure SetGatewayStr( const S: string);
         function  GetBroadcast(): word32;
         function  GetBroadcastStr(): string;
         function  GetZoneCount():    integer;
         function  GetZoneIndex():    word;
         function  GetVLANIDStr(): string;
         procedure SetVLANIDStr( const V: string);
         function  GetL2InVlanIdStr(): string;
         procedure SetL2InVlanIdStr( const V: string);
         function  GetZoneCIDR( Index: word): string;
      public
         AuxData:    tObject;
         constructor Create( const iCIDR: string);
         constructor Create();
         procedure   Dump();    virtual; // Just prints the CIDR.  Used for debugging trees.
         procedure   LongDump( HostName: string = ''; PaloObj: string = ''); virtual;
         function    Contains( Network: tNetworkInfo): boolean;
         function    Contains( iCIDR:   string): boolean;
         function    FirstZoneCIDR(): string;
         function    NextZoneCIDR():  string;
         property IPAddr:         word32  read MyIPAddr          write MyIPAddr;
         property IPAddrStr:      string  read GetIPAddrStr      write SetIPAddrStr;
         property NetNum:         word32  read GetNetNum;
         property NetMask:        word32  read MyNetMask         write SetNetMask;
         property Gateway:        word32  read MyGateway         write MyGateway;
         property Prefix:         word    read MyPrefix          write SetPrefix;
         property Broadcast:      word32  read GetBroadcast;
         property NetNumStr:      string  read GetNetNumStr;
         property NetMaskStr:     string  read GetNetMaskStr     write SetNetMaskStr;
         property GatewayStr:     string  read GetGatewayStr     write SetGatewayStr;
         property PrefixStr:      string  read GetPrefixStr      write SetPrefixStr;
         property BroadcastStr:   string  read GetBroadcastStr;
         property CIDR:           string  read GetFullStr        write SetFullStr;
         property Comment:        string  read MyComment         write MyComment;
         property VLAN:           string  read MyVLAN            write MyVLAN;
         property VLANID:         word    read MyVLANID          write MyVLANID;
         property VLANIDStr:      string  read GetVLANIDStr      write SetVLANIDStr;
         property L2InVlan:       string  read MyL2InVlan        write MyL2InVlan;
         property L2InVlanId:     word    read MyL2InVlanId      write MyL2InVlanId;
         property L2InVlanIdStr:  string  read GetL2InVlanIdStr  write SetL2InVlanIdStr;
         property EsxiVlan:       string  read MyEsxiVlan        write MyEsxiVlan;
         property PaloZone:       string  read MyPaloZone        write MyPaloZone;
         property PaloL2InZone:   string  read MyPaloL2InZone    write MyPaloL2InZone;
         property ZoneCount:      integer read GetZoneCount;
         property ZoneIndex:      word    read GetZoneIndex;
         property ZoneCIDR[ Index: word]:     string read GetZoneCIDR;
      end; // tNetworkInfo class


// =========================================================================
// = tNetworkInfoTree - A tree to hold tNetworkInfo sorted by NetNum/Prefix
// =========================================================================

type
   tNetworkInfoTree = class( tBalancedBinaryTree)
      public
         constructor  Create();
         constructor  Create( iCompare:     tCompareProcedure;
                              iDuplicateOK: boolean);
         constructor  Create( iCompare:     tCompareProcedure;
                              iDuplicateOK: boolean;
                              OtherTree: tBalancedBinaryTree);
         procedure    Add( Item: tObject); override;
      end; // tNetworkInfoTree


function CompareByComment(  N1: tNetworkInfo; N2: tNetworkInfo): int8;


// =========================================================================
// = tNetworkInfoLookupParent - An object to facilitate finding out which
// =                            subnet, DNS reverse Zone, or DHCP Network
// =                            an IP belongs.
// =   -- DO NOT USE THIS CLASS DIRECTLY - Use one of the child classes --
// =========================================================================

type
   tNetworkInfoLookupParent = class
      protected
         Trees:       array of tNetworkInfoTree;
         TreesMax:    integer;
         Prefixes:    array of word;
         CurrentI:    integer;    // Current index into Trees for GetFirst and GetNext
      public
         constructor  Create();
         destructor   Destroy;                                        override;
         procedure    Add( N: tNetworkInfo);                          virtual;
         function     Find( IP: string): tNetworkInfo;                virtual;
         function     Find( IP: word32): tNetworkInfo;                virtual;
         function     Find( SearchNode: tNetworkInfo): tNetworkInfo;  virtual;
         function     GetFirst(): tNetworkInfo;                       virtual;
         function     GetNext(): tNetworkInfo;                        virtual;
         procedure    RemoveAll( FreeThem: boolean = false);          virtual;
         procedure    Dump();
         procedure    LongDump();                                     virtual;
      end; // tNetworkInfoLookupParent class


// =========================================================================
// = tDNSNetworkInfoLookup - A tNetworkInfoLookupParent which only
// =                         contains /8 /16 and /24 networks
// =========================================================================

type
   tDNSNetworkInfoLookup = class( tNetworkInfoLookupParent)
      public
         constructor Create();
      end; // tReverseDNSNetworkLookup class


// =========================================================================
// = tNetworkLookup - A tNetworkInfoLookupParent which can contain all
// =                  possible network prefixes
// =========================================================================

type
   tNetworkInfoLookup = class( tNetworkInfoLookupParent)
      public
         constructor Create();
      end; // tReverseDNSNetworkLookup class


// *************************************************************************

var
   // A netmask of 255.255.255.255
   Slash32:             word32 = $ffffffff;

// *************************************************************************

implementation

var
   MyZoneCountError: word = 256;  // Any number above 255
   MyZoneIndexError: word = 257;  // Any number above MyZoneCount;

// =========================================================================
// = Global function to support handling empty VLANs
// =========================================================================

procedure WriteVlanVariable( VarName:       string; 
                             DefaultValue:  string; 
                             OriginalValue: string);
   var
      Temp: string;
   begin
      if( OriginalValue = '') then begin
         if( (DefaultValue = '') or SkipEmptyVlan) then exit;
         Temp:= DefaultValue;
      end else Temp:= OriginalValue;
      writeln( Format( '%-22s%s', [VarName, Temp]));
   end; // writeVlanVariable();


// =========================================================================
// = tNetworkInfo - Store network numbers and netmasks
// =========================================================================
// *************************************************************************
// * Create()
// *************************************************************************

constructor tNetworkInfo.Create( const iCIDR: string);
   begin
      SetFullStr( iCIDR);
      MyComment:= '';
      MyVLANID:= 0;
      MyVLAN:= '';
      AuxData:= nil;
      inherited Create();
   end; // Create

// -------------------------------------------------------------------------

constructor tNetworkInfo.Create();
   begin
      MyIPAddr:= 0;
      MyNetMask:= 0;
      MyPrefix:= 0;
      MyComment:= '';
      MyVLANID:= 0;
      MyVLAN:= '';
      AuxData:= nil;
      inherited Create();
   end; // Create()


// *************************************************************************
// * Dump() - Print the CIDR.  This is used for debugging trees which hold
//            tNetworkInfo objects.  Children can override it to print
//            additional information.
// *************************************************************************

procedure tNetworkInfo.Dump();
   begin
      writeln( CIDR, ',', Comment);
   end; // Dump();


// *************************************************************************
// * LongDump() - Prints the fields one per line with a separator.
// *************************************************************************

procedure tNetworkInfo.LongDump( HostName: string; PaloObj: string);
   begin
      writeln();
      WriteVlanVariable( 'Palo Obj:',             '',        PaloObj);
      WriteVlanVariable( 'Host Name:',            '',        HostName);
      if( IPAddr <>  NetNum) then begin
         WriteVlanVariable( 'IP Address:',        '',        IPAddrStr + '/32');
      end;
      if( (Length( PaloObj) > 0) or (Length( HostName) > 0) or (IPAddr <> NetNum)) then writeln;
      WriteVlanVariable( 'CIDR:',                 '',        CIDR);
      WriteVlanVariable( 'Net Number:',           '',        NetNumStr);
      WriteVlanVariable( 'Broadcast:',            '',        BroadcastStr);
      WriteVlanVariable( 'Netmask:',              '',        NetMaskStr);
      if( Gateway > 0) then WriteVlanVariable( 'Gateway:', '', GatewayStr);
      if( (Length( VLAN) > 0) or (VLANID > 0) or( Length( Comment) > 0)) then writeln;
      WriteVlanVariable( 'VMware VLAN:',          VLAN,      EsxiVlan);
      WriteVlanVariable( 'Palo Zone:',            VLAN,      PaloZone);
      WriteVlanVariable( 'VLAN Name:',            '',        VLAN);
      WriteVlanVariable( 'VLAN ID:',              '',        VlanIdStr);
      WriteVlanVariable( 'Palo L2 Inside Zone:',  L2InVlan,  PaloL2InZone);
      WriteVlanVariable( 'L2 Inside VLAN:',       '',        L2InVlan);
      WriteVlanVariable( 'L2 Inside VLAN ID:',    '',        L2InVlanIdStr);
      if( Length( Comment) > 0) then begin
         writeln;
         WriteVlanVariable( 'Comment:',           '',        Comment);
      end;
      writeln( '---------------------------------------------');
      writeln();
   end; // LongDump();


// *************************************************************************
// * Contains() - Returns true if the passed Network is in this network
// *************************************************************************

function tNetworkInfo.Contains( Network: tNetworkInfo): boolean;
   begin
      result:= (Network.NetNum >= NetNum) and (Network.Broadcast <= Broadcast);
   end; // Contains();


// -------------------------------------------------------------------------

function tNetworkInfo.Contains( iCIDR:   string): boolean;
   var
      Network: tNetworkInfo;
   begin
      Network:= tNetworkInfo.Create( iCIDR);
      result:= Contains( Network);
      Network.Destroy;
   end; // Contains();


// *************************************************************************
// * FirstZoneCIDR() - Returns the first DNS zone CIDR.  Returns an
// *                   empty string if no DNS zones are possible.
// *************************************************************************

function tNetworkInfo.FirstZoneCIDR(): string;
   begin
      // Make sure the Zone fields are initialized and catch errors.
      try
         GetZoneCount;
      except
         on IPConversionException do begin
            result:= '';
            exit;
         end;
      end; // try/except

      MyZoneIndex:= 0;
      if( MyZoneIndex >=  MyZoneCount) then begin
         result:= '';
      end else begin
         result:= ZoneCIDR[ MyZoneIndex];
         inc( MyZoneIndex);
      end;
   end; // FirstZoneCIDR()


// *************************************************************************
// * NextZoneCIDR() - Returns the next DNS zone CIDR.  Returns an empty
// *                  string if all DNS zones have been enumerated.
// *************************************************************************

function tNetworkInfo.NextZoneCIDR():  string;
   begin
      if( (MyZoneIndex >= MyZoneCount) or ( MyZoneIndex = 0)) then begin
         result:= '';
      end else begin
         result:= ZoneCIDR[ MyZoneIndex];
         inc( MyZoneIndex);
      end;
   end; // NextZoneCIDR()


// *************************************************************************
// * GetNetNum() - Return the network number as a string
// *************************************************************************

function  tNetworkInfo.GetNetNum(): word32;
   begin
      result:= MyIPAddr and MyNetMask;
   end; // GetNetNum();


// *************************************************************************
// * SetNetMask() - Set the netmask and prefix from a word32 representation
// *                of the mask.
// *************************************************************************

procedure tNetworkInfo.SetNetMask( const W: word32);
   var
      i:           word;
      Bit:         word32;
      ChangeCount: word;
      ChangeIndex: word;
      ExpectOne:   boolean;
      IsOne:       boolean;
      DontMatch:   boolean;
   begin
      MyZoneCount:= MyZoneCountError;
      MyZoneIndex:= MyZoneIndexError;
      i:=           1;
      Bit:=         1;
      ChangeCount:= 0;
      ExpectOne:=   false;

      // For each bit of the netmask
      for i:= 32 downto 1 do begin
         IsOne:= ((Bit and W) > 0);  // If the bit is on
         DontMatch:= IsOne xor ExpectOne; // Did we get what we expected?
         if( DontMatch) then begin
            ExpectOne:= not ExpectOne;
            ChangeIndex:= i;
            inc( ChangeCount);
         end;
         Bit:= Bit shl 1;
      end; // For each bit

      case ChangeCount of
         0:  begin
                MyPrefix:= 0;
                MyNetMask:= W;
             end;
         1:  begin
                MyPrefix:= ChangeIndex;
                MyNetMask:= w;
             end;
         else begin
            raise IPConversionException.Create(
                  'tNetworkInfo.SetNetMask(): Invalid netmask!');
         end;
      end // case
   end; // SetNetMask();


// *************************************************************************
// * GetGatewayStr() - Return the Gateway as a string
// *************************************************************************

function  tNetworkInfo.GetGatewayStr(): string;
   begin
      result:= IPWord32ToString( MyGateway);
   end; // GetGatewayStr();


// *************************************************************************
// * SetGatewaStr() - Set the Gateway from a string
// *************************************************************************

procedure tNetworkInfo.SetGatewayStr( const S: string);
   begin
      MyGateway:= IPStringToWord32( S);
   end; // SetGatewayStr();


// *************************************************************************
// * SetPrefix() - Set the netmask and prefix from a word representation
// *               of the prefix.
// *************************************************************************

procedure tNetworkInfo.SetPrefix( const W: word);
   var
      ShiftValue: word32;
   begin
      MyZoneCount:= MyZoneCountError;
      MyZoneIndex:= MyZoneIndexError;

      if( W > 32) then begin
         raise IPConversionException.Create(
               'tNetworkInfo.SetPrefix(): Invalid network prefix!');
      end;

      MyPrefix:= W;
      if( W = 0) then begin
         MyNetMask:= 0;
      end else begin
         ShiftValue:= 32 - W;
         MyNetMask:= Slash32 shl ShiftValue;
      end;
   end; // SetPrefix()


// *************************************************************************
// * GetIPAddrStr() - Return the IPAddress as a string
// *************************************************************************

function  tNetworkInfo.GetIPAddrStr(): string;
   begin
      result:= IPWord32ToString( MyIPAddr);
   end; // GetIPAddrStr();


// *************************************************************************
// * SetIPAddrStr() - Set the IP Address from a string
// *************************************************************************

procedure tNetworkInfo.SetIPAddrStr( const S: string);
   begin
      MyZoneCount:= MyZoneCountError;
      MyZoneIndex:= MyZoneIndexError;

      MyIPAddr:= IPStringToWord32( S);
   end; // SetIPAddrStr();


// *************************************************************************
// * GetNetNumStr() - Return the network number as a string
// *************************************************************************

function  tNetworkInfo.GetNetNumStr(): string;
   begin
      result:= IPWord32ToString( NetNum);
   end; // GetNetNumStr();


// *************************************************************************
// * GetNetNaskStr() - Return the netmask as a string
// *************************************************************************

function  tNetworkInfo.GetNetMaskStr(): string;
   begin
      result:= IPWord32ToString( MyNetMask);
   end; // GetNetMaskStr();


// *************************************************************************
// * SetNetMaskStr() - Set the netmask from a string
// *************************************************************************

procedure tNetworkInfo.SetNetMaskStr( const S: string);
   begin
      SetNetMask( IPStringToWord32( S));
   end; // SetNetMaskStr();


// *************************************************************************
// * GetFullString() - Get the full netnum/prefix string representing this
// *                   network.
// *************************************************************************

function tNetworkInfo.GetFullStr(): string;
   begin
      result:= GetNetNumStr() + '/' + GetPrefixStr();
   end;


// *************************************************************************
// * SetFullString() - Set the network info from the full netnum/prefix
// *                   representation.
// *************************************************************************

procedure tNetworkInfo.SetFullStr( const S: string);
   var
      IPAddrPart: string;
      PrefixPart: string;
      SlashIndex: integer;
   begin
      SlashIndex:= pos( '/', S);
      if( SlashIndex > 0) then begin

         // Slash was found so we have a prefix or a netmask following the IP
         PrefixPart:= Copy( S, SlashIndex + 1, Length( S) - SlashIndex);
         if( Length( PrefixPart) < 3) then begin
            // It can't be a netmask, so try it as a Prefix
            SetPrefixStr( PrefixPart);
         end else begin
            // It must be a netmask, so try that
            SetNetMaskStr( PrefixPart)
         end;

         // Now get the IPAddrPart ready
         IPAddrPart:= Copy( S, 1, SlashIndex - 1);
      end else begin

         // No slash, so we treat it as a network of one IP
         IPAddrPart:= S;
         MyNetmask:= high( word32);
         MyPrefix:= 32;
      end;
      SetIPAddrStr( IPAddrPart);
   end; // SetFullString();


// *************************************************************************
// * GetVLANIDStr() - Returns the string version of the VLAN ID or an empty
// *                  string if VlanID = 0.
// *************************************************************************

function tNetworkInfo.GetVLANIDStr(): string;
   begin
      result:= '';
      if( VlanID <> 0) then str( VLANID, result);
   end; // GetVLANIDStr()


// *************************************************************************
// * SetVLANIDStr() - Set the VLANID from a string representation of the
// *                  word value
// *************************************************************************

procedure tNetworkInfo.SetVLANIDStr( const V: string);
   var
      Code: integer;
      Temp: integer;
   begin
      MyZoneCount:= MyZoneCountError;
      MyZoneIndex:= MyZoneIndexError;

      VlanID:= 0;
      if( Length( V) = 0) then exit;
      val( V, Temp, Code);
      if( Code > 0) then begin
         raise IPConversionException.Create(
               'tNetworkInfo.SetVLANIDStr(): Invalid VLAN ID value!');
      end;
      VLANID:= word( Temp);
   end; // SetVLANIDStr()


// *************************************************************************
// * GetL2InVlanIdStr() - Returns the string version of the VLAN ID.
// *************************************************************************

function tNetworkInfo.GetL2InVlanIdStr(): string;
   begin
      result:= '';
      if( MyL2InVlanId <> 0) then str( MyL2InVlanId, result)
   end; // GetL2InVlanIdStr()


// *************************************************************************
// * SetL2InVlanIdStr() - Set the VLANID from a string representation of the
// *                  word value
// *************************************************************************

procedure tNetworkInfo.SetL2InVlanIdStr( const V: string);
   var
      Code: integer;
      Temp: integer;
   begin
      MyZoneCount:= MyZoneCountError;
      MyZoneIndex:= MyZoneIndexError;

      MyL2InVlanId:= 0;
      if( Length( V) = 0) then exit;
      val( V, Temp, Code);
      if( Code <> 0) then begin
         raise IPConversionException.Create(
               'tNetworkInfo.SetL2InVlanIdStr(): Invalid L2 VLAN ID value!');
      end;
      MyL2InVlanId:= word( Temp);
   end; // SetL2InVlanIdStr()


// *************************************************************************
// * GetPrefixStr() - Returns the string version of the network number.
// *************************************************************************

function tNetworkInfo.GetPrefixStr(): string;
   begin
      result:= '';
      str( MyPrefix, result)
   end; // GetPrefixStr()


// *************************************************************************
// * SetPrefixStr() - Set the prefix from a string representation of the
// *                  word value
// *************************************************************************

procedure tNetworkInfo.SetPrefixStr( const S: string);
   var
      Code: integer;
      Temp: integer;
   begin
      MyZoneCount:= MyZoneCountError;
      MyZoneIndex:= MyZoneIndexError;

      val( S, Temp, Code);
      if( Code <> 0) then begin
         raise IPConversionException.Create(
               'tNetworkInfo.SetPrefix(): Invalid prefix value!');
      end;

      SetPrefix( word( Temp));
   end; // SetPrefix()


// *************************************************************************
// * GetBroadcast() - Returns the standard all ones broadcast for this net
// *************************************************************************

function tNetworkInfo.Getbroadcast(): word32;
   begin
      result:= MyIPAddr or (not MyNetMask);
   end; // GetBroadcast()


// *************************************************************************
// * GetBroadcastStr() - Returns the standard all ones broadcast for this net
// *************************************************************************

function tNetworkInfo.GetBroadcastStr(): string;
   begin
      result:= IPWord32ToString( GetBroadcast);
   end; // GetBroadcastStr()


// *************************************************************************
// * GetZoneCount() - Returns the number of Reverse DNS zones required for
// *                  this network.
// *************************************************************************

function tNetworkInfo.GetZoneCount(): integer;
   begin
      // If we haven't yet calculated the DNS zone information, then do it now.
      if( MyZoneCount > 255) then begin
         if( MyPrefix > 16) then MyZonePrefix:= 24
         else if( MyPrefix > 8) then MyZonePrefix:= 16
         else begin
            result:= 0;
            exit;
         end;
         //raise IPConversionException.Create( CIDR + ' has too small a prefix to automatically create reverse DNS information!');

         MyZoneInc:= 1 shl (32 - MyZonePrefix);
         if( MyPrefix <= 24) then begin
            MyZoneCount:= 1 shl( MyZonePrefix - MyPrefix);
         end else begin
            MyZoneCount:= 1;
         end;
         MyZoneIndex:= 0;
      end;
      result:= MyZoneCount;
   end; // GetZoneCount()


// *************************************************************************
// * GetZoneIndex() - Returns the index into DNS Zones for this network
// *                  which will be used for the next call to the GetNextXXX()
// *                  GetNextXXX function.
// *************************************************************************

function tNetworkInfo.GetZoneIndex(): word;
   begin
      if( MyZoneCount > 255) then GetZoneCount;
      result:= MyZoneIndex;
   end; // GetZoneIndex()


// *************************************************************************
// * GetZoneCIDR() - Returns CIDR for the Indexth DNS Zone.
// *                 Returns the empty string if the Index is out of range.
// *************************************************************************

function tNetworkInfo.GetZoneCIDR( Index: word): string;
   var
      MyPrefixStr: string;
      ZoneNetNum:  word32;
      MyNetNumStr: string;
   begin
      if( Index >= ZoneCount) then begin // Side effect of setting the zone variables.
        result:= '';
        exit;
      end;
      str( MyZonePrefix, MyPrefixStr);

      ZoneNetNum:= NetNum + (Index * MyZoneInc);
      MyNetNumStr:= IPWord32ToString( ZoneNetNum);

      result:= MyNetNumStr + '/' + MyPrefixStr;
   end; // GetBroadcastStr()



// =========================================================================
// = tNetworkInfoTree - A sorted tree of tNetworkInfo
// =========================================================================
// *************************************************************************
// * CompareByNetwork() - global function used to order the tree (default)
// *************************************************************************

function CompareByNetwork(  N1: tNetworkInfo; N2: tNetworkInfo): int8;
   begin
      if( N1.NetNum > N2.NetNum) then begin
         result:= 1;
      end else if( N1.NetNum < N2.NetNum) then begin
         result:= -1;
      end else begin
         if( N1.Prefix > N2.Prefix) then begin
            result:= 1;
         end else if( N1.Prefix < N2.Prefix) then begin
            result:= -1;
         end else begin
            result:= 0;
         end;
      end;
   end; // CompareByNetwork()


// *************************************************************************
// * CompareByComment() - global function used to order the tree
// *************************************************************************

function CompareByComment(  N1: tNetworkInfo; N2: tNetworkInfo): int8;
   begin
      if( N1.Comment > N2.Comment) then begin
         result:= 1;
      end else if( N1.Comment < N2.Comment) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareByComment()


// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tNetworkInfoTree.Create();
   begin
      inherited  Create( tCompareProcedure( @CompareByNetwork), false);
   end; // Create()

// -------------------------------------------------------------------------

constructor tNetworkInfoTree.Create( iCompare: tCompareProcedure; iDuplicateOK: boolean);
   begin
      inherited Create( iCompare, iDuplicateOK);
   end; // Create()

// -------------------------------------------------------------------------

constructor tNetworkInfoTree.Create( iCompare: tCompareProcedure; iDuplicateOK: boolean; OtherTree: tBalancedBinaryTree);
   begin
      inherited Create( iCompare, iDuplicateOK, OtherTree);
   end; // Create()


procedure tNetworkInfoTree.Add( Item: tObject);
   begin
      inherited Add( Item);
      if( show_debug) then begin
         writeln( '   tNetworkInfoTree.Add( ', tNetworkInfo( Item).CIDR, ')');
      end;
   end; // Add()


// ========================================================================
// = tNetworkInfoLookupParent
// ========================================================================
// ************************************************************************
// * Create() - constructor
// ************************************************************************

constructor tNetworkInfoLookupParent.Create();
   begin
      inherited Create();
      CurrentI:= -1;
   end; // Create()


// ************************************************************************
// * Destructor() - destructor
// ************************************************************************

destructor tNetworkInfoLookupParent.Destroy();
   var
      i:     integer;
   begin
      for i:= 0 to TreesMax do begin
         Trees[ i].RemoveAll( true);
         Trees[ i].Destroy();
      end;
      inherited Destroy();
   end; // Destroy()


// ************************************************************************
// * Find() - Find the network node which contains IP
// ************************************************************************

procedure tNetworkInfoLookupParent.Add( N: tNetworkInfo);
   var
      i: word;
   begin
      // Can the prefix be the direct index into Trees?
      if( TreesMax = 32) then begin
         i:= N.Prefix;
      end else begin
         // The prefix must be looked up in Prefixes.
         i:= 0;
         while( (i <= TreesMax) and (Prefixes[ i] <> N.Prefix)) do inc( i);
         if( i > TreesMax) then begin
            raise IPConversionException.Create( 'This tNetworkInfoLookupParent object is not configured to accept prefixes of this size!');
         end;
      end;

      Trees[ i].Add( N);
   end; // Add()


// ************************************************************************
// * Find() - Find the network node which contains IP
// ************************************************************************

function tNetworkInfoLookupParent.Find( IP: string): tNetworkInfo;
   var
      SN: tNetworkInfo;
   begin
      SN:= nil;
      try
         SN:= tNetworkInfo.Create();
         SN.IPAddrStr:= IP;

         result:= Find( SN);
      finally
         if( SN <> nil) then SN.Destroy();
      end; // try / finally
   end; // Find()


// ------------------------------------------------------------------------

function tNetworkInfoLookupParent.Find( IP: word32): tNetworkInfo;
   var
      SN: tNetworkInfo;
   begin
      SN:= nil;
      try
         SN:= tNetworkInfo.Create();
         SN.IPAddr:= IP;
         result:= Find( SN);
      finally
         if( SN <> nil) then SN.Destroy();
      end; // try / finally
   end; // Find()


// ------------------------------------------------------------------------

function tNetworkInfoLookupParent.Find( SearchNode: tNetworkInfo): tNetworkInfo;
   var
      T:    tNetworkInfoTree;
      i:    integer;
   begin
      result:= nil;
      i:= length( Trees) - 1;
      repeat
         T:= Trees[ i];
         SearchNode.Prefix:= Prefixes[ i];
         result:= tNetworkInfo( T.Find( SearchNode));
         dec( i);
         if( i < 0) then exit;
      until( result <> nil);
   end; // Find()


// ************************************************************************
// * GetFirst() - Returns our first element
// ************************************************************************

function tNetworkInfoLookupParent.GetFirst(): tNetworkInfo;
   begin
      CurrentI:= 0;
      result:= tNetworkInfo( Trees[ CurrentI].GetFirst);
      while( result = nil) do begin
         inc( CurrentI);
         if( CurrentI > TreesMax) then exit;
         result:= tNetworkInfo( Trees[ CurrentI].GetFirst);
      end;
   end; // GetFirst()


// ************************************************************************
// * GetNext() - Returns our next element
// ************************************************************************

function tNetworkInfoLookupParent.GetNext(): tNetworkInfo;
   begin
      if( CurrentI < 0) then begin
         CurrentI:= 0;
         result:= tNetworkInfo( Trees[ CurrentI].GetFirst);
      end else begin
         result:= tNetworkInfo( Trees[ CurrentI].GetNext);
      end;
      while( result = nil) do begin
         inc( CurrentI);
         if( CurrentI > TreesMax) then exit;
         result:= tNetworkInfo( Trees[ CurrentI].GetFirst);
      end;
   end; // GetNext()


// ************************************************************************
// * RemoveAll() - Removes the objects in the tree.  Optionally frees the
// *               memory used by each object.
// ************************************************************************

procedure tNetworkInfoLookupParent.RemoveAll( FreeThem: boolean = false);
   var
      i: integer;
   begin
      for i:= 0 to TreesMax do begin
         Trees[ i].RemoveAll( FreeThem);
      end;
   end; // RemoveAll()


// ************************************************************************
// * Dump()
// ************************************************************************

procedure tNetworkInfoLookupParent.Dump();
   var
      N:    tNetworkInfo;
   begin
      CurrentI:= -1;
      repeat
         N:= tNetworkInfo( GetNext);
         if( N <> nil) then N.Dump;
      until( N = nil);
   end; // Dump()


// ************************************************************************
// * LongDump()
// ************************************************************************

procedure tNetworkInfoLookupParent.LongDump();
   var
      N:    tNetworkInfo;
   begin
      CurrentI:= -1;
      repeat
         N:= tNetworkInfo( GetNext);
         if( N <> nil) then N.LongDump;
      until( N = nil);
   end; // LongDump()



// ========================================================================
// = tDNSNetworkInfoLookup
// ========================================================================
// ************************************************************************
// * Create() - constructor
// ************************************************************************

constructor tDNSNetworkInfoLookup.Create();
   begin
      inherited Create();
      TreesMax:= 2; // Maximum index of the Trees array
      SetLength( Trees, 3);
      Trees[ 0]:= tNetworkInfoTree.Create();
      Trees[ 1]:= tNetworkInfoTree.Create();
      Trees[ 2]:= tNetworkInfoTree.Create();
      SetLength( Prefixes, 3);
      Prefixes[ 0]:= 8;
      Prefixes[ 1]:= 16;
      Prefixes[ 2]:= 24;
   end; // Create()


// ========================================================================
// = tNetworkInfoLookup
// ========================================================================
// ************************************************************************
// * Create() - constructor
// ************************************************************************

constructor tNetworkInfoLookup.Create();
   var
      i: integer;
   begin
      inherited Create();
      TreesMax:= 32; // Maximum index of the Trees array
      SetLength( Trees, 33);
      SetLength( Prefixes, 33);
      for i:= 0 to TreesMax do begin
         Trees[ i]:= tNetworkInfoTree.Create();
         Prefixes[ i]:= i;
      end;
   end; // Create()


// *************************************************************************

end.  // lbp_ip_network unit
