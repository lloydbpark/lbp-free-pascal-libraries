{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

<brief description of the file.  for exampl: Definition of common types>

Defines dhcp fields within a packet

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

// Classes that know how to read their data from and write to a DHCP packet.
unit lbp_dhcp_fields;

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

interface

uses
   lbp_types,
   lbp_utils,
   lbp_ip_utils,
   lbp_log,
   lbp_net_fields,
   sysutils;         // Format() function


// ************************************************************************

const
   NamePadSize      = 23;
   EthernetHWType   = 1;
   EthernetHWLength = 6;
   ValidMajicCookie = 1669485411;

   // Possibe Op Code values
   BootRequestOp    = 1;
   BootReplyOp      = 2;

   // Possible DHCP Op Code values
   bootpRequest     = 0;
   dhcpDiscover     = 1;
   dhcpOffer        = 2;
   dhcpRequest      = 3;
   dhcpDecline      = 4;
   dhcpAck          = 5;
   dhcpNAck         = 6;
   dhcpRelease      = 7;
   dhcpInform       = 8;

   // Possible NetBIOS Node values
   BroadcastNode = 1; // Broadcast only
   UnicastNode   = 2; // WINS only
   MixedNode     = 4; // Broadcast, then WINS
   HybridNode    = 8; // WINS, then Broadcast

   // Default lease for VarLease
   DefaultLeaseHours   = 6;
   DefaultLeaseMinutes = 0;
   DefaultLeaseSeconds = 0;
   DefaultLease: word32 = (((DefaultLeaseHours * 60) +
                            DefaultLeaseMinutes) * 60) + DefaultLeaseSeconds;


// ************************************************************************

type
   DHCPFieldException = class( lbp_exception);


// ========================================================================

type
   tFixedOpCode = class( tFixedWord8)
      public
         constructor  Create();
         function     GetStrValue(): string; override;
         procedure    Read( var Buffer: tNetBuffer;
                            var Pos:    word32);      override;
      end;


// ========================================================================

type
   tFixedHWType = class( tFixedWord8) // Hardware Address Type
      public
         constructor  Create();
         function     GetStrValue(): string; override;
      end;


// ========================================================================

type
   tFixedHWLength = class( tFixedWord8) // Hardware Address Length
      public
         constructor  Create();
         function     GetStrValue(): string; override;
         procedure    Read( var Buffer: tNetBuffer;
                            var Pos: word32);      override;
         procedure    Write( var Buffer: tNetBuffer;
                             var Pos: word32);     override;
      end;


// ========================================================================

type
   tFixedTransID = class( tFixedWord32)
      public
         constructor  Create();
         procedure    Clear();       override;
      end;


// ========================================================================

type
   tFixedNIC = class( tVarHexString) // 8 bit
      public
         HWLength:    tFixedHWLength;
         constructor  Create( iHWLength: tFixedHWLength);
         destructor   Destroy();     override;
         function     GetStrValue(): string; override;
         procedure    SetStrValue( iValue: string); override;
         function     GetDefaultStrValue(): string; override;
         procedure    SetDefaultStrValue( iValue: string); override;
      end;


// ========================================================================

   tFixedMajic = class( tFixedWord32)
      public
         constructor  Create();
         function     GetStrValue(): string; override;
      end;


// ========================================================================

type
   tVarByte = class( tFixedWord8) // 8 bit
      public
         constructor  Create( iCode: byte; iName: string; iValue: byte);
         procedure    Read( var Buffer: tNetBuffer;
                            var Pos: word32);      override;
         procedure    Write( var Buffer: tNetBuffer;
                             var Pos: word32);     override;
         function     GetLength(): word16;         override;
      end;


// ========================================================================

type
   tDHCPOpCode = class( tVarByte)
      public
         constructor  Create();
         function     GetStrValue(): string; override;
      end;


// ========================================================================

   tVarNetBIOSNode = class( tVarByte)
      public
         constructor  Create();
         function     GetStrValue(): string; override;
      end;


// ========================================================================

   tVarWord32 = class( tFixedWord32) // 32 bit
      public
         constructor  Create( iCode: byte; iName: string; iValue: word32);
         procedure    Read( var Buffer: tNetBuffer;
                            var Pos: word32);      override;
         procedure    Write( var Buffer: tNetBuffer;
                             var Pos: word32);     override;
         function     GetLength(): word16;         override;
      end;


// ========================================================================

   tVarIPAddrArray = class( tVarWord32Array)
      public
         constructor  Create( iCode: byte; iName: string);
         function     GetStrValue(): string; override;
         procedure    Read( var Buffer: tNetBuffer;
                            var Pos: word32);      override;
         procedure    Write( var Buffer: tNetBuffer;
                             var Pos: word32);     override;
         function     GetLength(): word16;         override;
      end;


// ========================================================================

   tVarIPAddr = class( tVarWord32)
      public
         constructor  Create( iCode: byte; iName: string; iValue: string);
         function     GetStrValue(): string; override;
         procedure    SetStrValue( iValue: string); override;
      end;


// ========================================================================

   tVarLease = class( tVarWord32)
      public
         constructor  Create();
         function     GetStrValue(): string; override;
      end;


// ========================================================================

   tVarStr = class( tFixedStr)
      public
         constructor  Create( iCode: byte; iName: string; iValue: string);
         procedure    SetStrValue( iValue: string);  override;
         procedure    Read( var Buffer: tNetBuffer;
                            var Pos: word32);        override;
         procedure    Write( var Buffer: tNetBuffer;
                             var Pos: word32);       override;
         function     GetLength(): word16;           override;
      end;


// ========================================================================

   tVarByteArray = class( tVarWord8Array)
      public
         constructor  Create( iCode: byte; iName: string);
         function     GetStrValue(): string; override;
         procedure    Read( var Buffer: tNetBuffer;
                            var Pos: word32);      override;
         procedure    Write( var Buffer: tNetBuffer;
                             var Pos: word32);     override;
         function     GetLength(): word16;         override;
      end;


// ========================================================================

   tVarClientID = class( tVarByteArray)
      public
         constructor  Create();
         function     GetStrValue(): string;         override;
         procedure    SetStrValue( iValue: string);  override;
      end;


// ========================================================================

   tVarParamReq = class( tVarByteArray)
      public
         constructor  Create();
         procedure    Clear();       override;
      end;


// ========================================================================

   tVarUnknown = class( tVarByteArray)
      public
         constructor  Create( iCode: byte);
         function     GetStrValue(): string; override;
      end;


// ========================================================================

   tVarEnd = class( tFixedWord8)
      public
         constructor  Create();
         procedure    Clear();       override;
         function     GetStrValue(): string; override;
      end;


// ========================================================================

   tVarPad = class( tFixedWord8)
      public
         constructor  Create();
      end;



// ************************************************************************

// ************************************************************************

implementation


// ========================================================================
// = FixedOpCode
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tFixedOpCode.Create();
   begin
      inherited Create( 'OpCode', BootRequestOp);
   end; // Create()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tFixedOpCode.GetStrValue(): string;
   begin
      case value of
         BootRequestOp:  GetStrValue:= 'BootP Request';
         BootReplyOp:    GetStrValue:= 'BootP Reply';
         else GetStrValue:= 'Unknown operation';
      end; // case
   end; // GetStrValue()


// ************************************************************************
// * Read() - Read this field's value from Buffer[ Pos].
// *          increments Pos to point at the next field.
// ************************************************************************

procedure tFixedOpCode.Read( var Buffer: tNetBuffer;
                             var Pos:    word32);
   begin
      inherited Read( Buffer, Pos);
      if ((Value <> BootRequestOp) and (Value <> BootReplyOp)) then begin
         raise DHCPFieldException.Create( 'Invalid bootp opcode!');
      end;
   end; // Read()



// ========================================================================
// = FixedHWType
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tFixedHWType.Create();
   begin
      inherited Create( 'Hardware Type', EthernetHWType);
   end; // Create()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tFixedHWType.GetStrValue(): string;
   var
      Temp: string;
   begin
      if( Value = EthernetHWType) then begin
         GetStrValue:= 'Ethernet';
      end else begin
         Str( Value, Temp);
         GetStrValue:= Temp + ':  Unknown type!';
      end;
   end; // GetStrValue()



// ========================================================================
// = FixedHWLength
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tFixedHWLength.Create();
   begin
      inherited Create( 'Hardware Address Length', EthernetHWLength);
   end; // Create()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tFixedHWLength.GetStrValue(): string;
   var
      Temp: string;
   begin
      if( Value = EthernetHWLength) then begin
         GetStrValue:= 'Ethernet';
      end else begin
         Str( Value, Temp);
         GetStrValue:= Temp;
      end;
   end; // GetStrValue()


// ************************************************************************
// * Read() - Read this field's value from Buffer[ Pos].
// *          increments Pos to point at the next field.
// ************************************************************************

procedure tFixedHWLength.Read( var Buffer: tNetBuffer;
                               var Pos:    word32);
   begin
      inherited Read( Buffer, Pos);
      if( Value > 16) then begin
         raise DHCPFieldException.Create(
                  'tFixedHWLength.Read():  HW Length too long!');
      end;
   end; // Read()


// ************************************************************************
// * Write() - Save this field's value in Buffer[ Pos].
// *           increments Pos to point at the next field.
// ************************************************************************

procedure tFixedHWLength.Write( var Buffer: tNetBuffer;
                                var Pos:    word32);
   begin
      if( Value > 16) then begin
         raise DHCPFieldException.Create(
                  'tFixedHWLength.Write():  HW Length too long!');
      end;
      inherited Write( Buffer, Pos);
   end; // Write()



// ========================================================================
// = FixedTransID
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tFixedTransID.Create();
   begin
      inherited Create( 'Transaction ID', random( High( longint)));
   end; // Create()


// ************************************************************************
// * Clear() - Set the value to the default or empty state
// ************************************************************************

procedure tFixedTransID.Clear();
   begin
      Value:= random( High( longint));
   end; // Clear()


// ========================================================================
// = FixedNIC
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tFixedNIC.Create( iHWLength: tFixedHWLength);
   begin
      HWLength:= iHWLength;
      inherited Create( 'ClientHardwareAddress', 16);
   end; // Create()


// ************************************************************************
// * Destroy() - Destructor
// ************************************************************************

destructor tFixedNIC.Destroy();
   begin
      HWLength:= nil;
      inherited Destroy();
   end; // Destroy();


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tFixedNIC.GetStrValue(): string;
   var
      i:           word;
      Temp:        string = '';
      ValueLength: int32;
   begin
      ValueLength:= HWLength.Value - 1;
      for i:= 0 to ValueLength do begin
         Temp:= Temp + HexStr( longint( Value[ i]), 2);
      end;
      Temp:= lowercase( Temp);
      result:= Temp;
   end; // GetStrValue()


/// ************************************************************************
// * SetStrValue() - Sets value of the field from a string.
// ************************************************************************

procedure tFixedNIC.SetStrValue( iValue: string);
   var
      TempValue:  string;
      TempLength: word;
      iStr:       word;
      iByte:      word;
      HighNibble: boolean;
      Temp:       byte;
   begin
      TempValue:= RemoveNonHexCharacters( iValue);
      TempLength:= HWLength.Value * 2;

      if( System.Length( TempValue) <> TempLength) then begin
         raise NetFieldException.Create( 'tFixedNIC.SetStrValue():  ' +
                                   'Input string has the wrong length!');
      end;

      HighNibble:= true;
      iByte:= 0;
      for iStr:= 1 to TempLength do begin
         if( TempValue[ iStr] in ['0'..'9']) then begin
            Temp:= ord( TempValue[ iStr]) - ord('0');
         end else if( TempValue[ iStr] in ['a'..'f']) then begin
            Temp:= ord( TempValue[ iStr]) - ord('a') + 10;
         end else if( TempValue[ iStr] in ['A'..'F']) then begin
            Temp:= ord( TempValue[ iStr]) - ord('A') + 10;
         end else begin
            raise  NetFieldException.Create( 'tFixedNIC.SetStrValue():  ' +
                                   'Invalid character in input string!');
         end;
         if( HighNibble) then begin
            Value[ iByte]:= Temp SHL 4;
         end else begin
            Value[ iByte]:= Value[ iByte] + Temp;
            inc( iByte);
         end;
         HighNibble:= not HighNibble;
      end;
   end; // SetStrValue()


// ************************************************************************
// * GetDefaultStrValue() - Returns the default value of the field as a string.
// ************************************************************************

function tFixedNIC.GetDefaultStrValue(): string;
   var
      i:           word;
      Temp:        string = '';
      ValueLength: int32;
   begin
      ValueLength:= HWLength.Value - 1;
      for i:= 0 to ValueLength do begin
         Temp:= Temp + HexStr( longint( DefaultValue[ i]), 2);
      end;
      Temp:= lowercase( Temp);
      result:= Temp;
   end; // GetStrValue()


// ************************************************************************
// * SetDefaultStrValue() - Sets default value of the field from a string.
// ************************************************************************

procedure tFixedNIC.SetDefaultStrValue( iValue: string);
   var
      TempValue:  string;
      TempLength: word;
      iStr:       word;
      iByte:      word;
      HighNibble: boolean;
      Temp:       byte;
   begin
      TempValue:= RemoveNonHexCharacters( iValue);
      TempLength:= HWLength.Value * 2;

      if( System.Length( TempValue) <> TempLength) then begin
         raise NetFieldException.Create( 'tFixedNIC.SetStrValue():  ' +
                                   'Input string has the wrong length!');
      end;

      HighNibble:= true;
      iByte:= 0;
      for iStr:= 1 to TempLength do begin
         if( TempValue[ iStr] in ['0'..'9']) then begin
            Temp:= ord( TempValue[ iStr]) - ord('0');
         end else if( TempValue[ iStr] in ['a'..'f']) then begin
            Temp:= ord( TempValue[ iStr]) - ord('a') + 10;
         end else if( TempValue[ iStr] in ['A'..'F']) then begin
            Temp:= ord( TempValue[ iStr]) - ord('A') + 10;
         end else begin
            raise  NetFieldException.Create( 'tFixedNIC.SetStrValue():  ' +
                                   'Invalid character in input string!');
         end;
         if( HighNibble) then begin
            DefaultValue[ iByte]:= Temp SHL 4;
         end else begin
            DefaultValue[ iByte]:= Value[ iByte] + Temp;
            inc( iByte);
         end;
         HighNibble:= not HighNibble;
      end;
   end; // SetDefaultStrValue()



// ========================================================================
// = tFixedMajic
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tFixedMajic.Create();
   begin
      inherited Create( 'MajicCookie', ValidMajicCookie);
   end; // Create()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tFixedMajic.GetStrValue(): string;
   begin
      if( Value = ValidMajicCookie) then begin
         GetStrValue:= 'OK';
      end else begin
         GetStrValue:= 'Invalid!  ' + inherited GetStrValue();
      end;
   end; // GetStrValue()



// ========================================================================
// = VarByte
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tVarByte.Create( iCode: byte; iName: string; iValue: byte);
   begin
      inherited Create( iName, iValue);
      Code:= iCode;
   end; // Create()


// ************************************************************************
// * Read() - Read this field's value from Buffer[ Pos].
// *          increments Pos to point at the next field.
// ************************************************************************

procedure tVarByte.Read( var Buffer: tNetBuffer;
                         var Pos:    word32);
   begin
      Code:= Buffer[ Pos];
      inc( Pos);
      MyLength:= Buffer[ Pos];
      inc( Pos);
      inherited Read( Buffer, Pos);
   end;


// ************************************************************************
// * Write() - Save this field's value in Buffer[ Pos].
// *           increments Pos to point at the next field.
// ************************************************************************

procedure tVarByte.Write( var Buffer: tNetBuffer;
                          var Pos:    word32);
   begin
      Buffer[ Pos]:= Code;
      inc( Pos);
      Buffer[ Pos]:= Lo( Length) - 2;
      inc( Pos);
      inherited Write( Buffer, Pos);
   end;


// ************************************************************************
// * GetLength() - Returns the length of the field in bytes
// ************************************************************************

function tVarByte.GetLength(): word16;
   begin
      result:= inherited GetLength + 2;
   end; // GetLength()


// ========================================================================
// = tDHCPOpCode
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tDHCPOpCode.Create();
   begin
      inherited Create( 53, 'DHCP Op-Code', bootpRequest);
   end; // Create()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

 function tDHCPOpCode.GetStrValue(): string;
    begin
       case Value of
          bootpRequest:   GetStrValue:= 'BootP Request';
          dhcpDiscover:   GetStrValue:= 'DHCP Discover';
          dhcpOffer:      GetStrValue:= 'DHCP Offer';
          dhcpRequest:    GetStrValue:= 'DHCP Request';
          dhcpDecline:    GetStrValue:= 'DHCP Decline';
          dhcpAck:        GetStrValue:= 'DHCP Acknowledge';
          dhcpNAck:       GetStrValue:= 'DHCP Negative Acknowledge';
          dhcpRelease:    GetStrValue:= 'DHCP Release';
          dhcpInform:     GetStrValue:= 'DHCP Inform';
          else            GetStrValue:= 'Unknown operation';
       end; // case
    end; // GetStrValue()



// ========================================================================
// = tVarNetBIOSNode
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tVarNetBIOSNode.Create();
   begin
      inherited Create( 46, 'NetBIOS Node Type', BroadcastNode);
   end; // Create()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tVarNetBIOSNode.GetStrValue(): string;
   begin
      case Value of
         BroadcastNode:  GetStrValue:= 'Broadcast only node';
         UnicastNode:    GetStrValue:= 'WINS only node';
         MixedNode:      GetStrValue:= 'Broadcast, then WINS node';
         HybridNode:     GetStrValue:= 'WINS, then broadcast node';
         else            GetStrValue:= 'Invalid NetBIOS node type';
      end; // case
   end; // GetStrValue()



// ========================================================================
// = VarWord32
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tVarWord32.Create( iCode: byte; iName: string; iValue: word32);
   begin
      inherited Create( iName, iValue);
      Code:= iCode;
   end; // Create()


// ************************************************************************
// * Read() - Read this field's value from Buffer[ Pos].
// *          increments Pos to point at the next field.
// ************************************************************************

procedure tVarWord32.Read( var Buffer: tNetBuffer;
                         var Pos:    word32);
   begin
      Code:= Buffer[ Pos];
      inc( Pos);
      MyLength:= Buffer[ Pos];
      inc( Pos);
      inherited Read( Buffer, Pos);
   end;


// ************************************************************************
// * Write() - Save this field's value in Buffer[ Pos].
// *           increments Pos to point at the next field.
// ************************************************************************

procedure tVarWord32.Write( var Buffer: tNetBuffer;
                          var Pos:    word32);
   begin
      Buffer[ Pos]:= Code;
      inc( Pos);
      Buffer[ Pos]:= Lo( Length) - 2;
      inc( Pos);
      inherited Write( Buffer, Pos);
   end;


// ************************************************************************
// * GetLength() - Returns the length of the field in bytes
// ************************************************************************

function tVarWord32.GetLength(): word16;
   begin
      result:= inherited GetLength + 2;
   end; // GetLength()



// ========================================================================
// = tVarIPAddrArray
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tVarIPAddrArray.Create( iCode: byte; iName: string);
   begin
      inherited Create( iName, 1);
      Code:= iCode;
   end; // Create()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tVarIPAddrArray.GetStrValue(): string;
   var
      ReturnValue: string;
      i:           shortint;
      UB:          longint;
   begin
      UB:= Value.UpperBound;
      if( UB < 0) then begin
         ReturnValue:= '0.0.0.0';
      end else begin
         ReturnValue:= IPWord32ToString( Value[ 0]);
         for i:= 1 to UB do begin
            ReturnValue:= ReturnValue + ', ' +
                     IPWord32ToString( Value[ i]);
         end;
      end;
      GetStrValue:= ReturnValue;
   end; // GetStrValue()


// ************************************************************************
// * Read() - Read this field's value from Buffer[ Pos].
// *          increments Pos to point at the next field.
// ************************************************************************

procedure tVarIPAddrArray.Read( var Buffer: tNetBuffer;
                         var Pos:    word32);
   begin
      Code:= Buffer[ Pos];
      inc( Pos);
      MyLength:= Buffer[ Pos];
      inc( Pos);
      inherited Read( Buffer, Pos);
   end;


// ************************************************************************
// * Write() - Save this field's value in Buffer[ Pos].
// *           increments Pos to point at the next field.
// ************************************************************************

procedure tVarIPAddrArray.Write( var Buffer: tNetBuffer;
                          var Pos:    word32);
   begin
      Buffer[ Pos]:= Code;
      inc( Pos);
      Buffer[ Pos]:= Lo( Length) - 2;
      inc( Pos);
      inherited Write( Buffer, Pos);
   end;


// ************************************************************************
// * GetLength() - Returns the length of the field in bytes
// ************************************************************************

function tVarIPAddrArray.GetLength(): word16;
   begin
      result:= inherited GetLength + 2;
   end; // GetLength()



// ========================================================================
// = VarIPAddr
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tVarIPAddr.Create( iCode: byte; iName: string; iValue: string);
   begin
      inherited Create( iCode, iName, IPStringToWord32( iValue));
   end; // Create()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tVarIPAddr.GetStrValue(): string;
   begin
      GetStrValue:= IPWord32ToString( Value);
   end; // GetStrValue()


// ************************************************************************
// * SetStrValue() - Set the value of the field from a string.
// ************************************************************************

procedure tVarIPAddr.SetStrValue( iValue: string);
   begin
      Value:= IPStringToWord32( iValue);
   end; // SetStrValue()


// ========================================================================
// = VarLease
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tVarLease.Create();
   begin
      inherited Create( 51, 'DHCP Lease', DefaultLease);
   end; // Create()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tVarLease.GetStrValue(): string;
   var
      Remainder:   word32;
      Hours:       word32;
      Minutes:     word32;
      Seconds:     word32;

   begin
      Hours:=     Value div 3600;
      Remainder:= Value mod 3600;
      Minutes:=   Remainder div 60;
      Seconds:=   Remainder mod 60;

      GetStrValue:= Format( '%2.2D:%2.2D:%2.2D', [Hours, Minutes, Seconds]);
   end; // GetStrValue()



// ========================================================================
// = tVarStr
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tVarStr.Create( iCode: byte; iName: string; iValue: string);
   begin
      inherited Create( iName, System.Length( iValue), iValue);
      Code:= iCode;
   end; // Create()


// ************************************************************************
// * SetStrValue() - Sets the value of the field using a string.
// ************************************************************************

procedure tVarStr.SetStrValue( iValue: string);
   begin
      MyLength:= System.Length( iValue);
      Value:= iValue;
   end; // SetStrValue();


// ************************************************************************
// * Read() - Read this field's value from Buffer[ Pos].
// *          increments Pos to point at the next field.
// ************************************************************************

procedure tVarStr.Read( var Buffer: tNetBuffer;
                         var Pos:    word32);
   begin
      Code:= Buffer[ Pos];
      inc( Pos);
      MyLength:= Buffer[ Pos];
      inc( Pos);
      inherited Read( Buffer, Pos);
   end;


// ************************************************************************
// * Write() - Save this field's value in Buffer[ Pos].
// *           increments Pos to point at the next field.
// ************************************************************************

procedure tVarStr.Write( var Buffer: tNetBuffer;
                          var Pos:    word32);
   begin
      Buffer[ Pos]:= Code;
      inc( Pos);
      Buffer[ Pos]:= Lo( Length) - 2;
      inc( Pos);
      inherited Write( Buffer, Pos);
   end;


// ************************************************************************
// * GetLength() - Returns the length of the field in bytes
// ************************************************************************

function tVarStr.GetLength(): word16;
   begin
      result:= inherited GetLength + 2;
   end; // GetLength()



// ========================================================================
// = tVarByteArray
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tVarByteArray.Create( iCode: byte; iName: string);
   begin
      inherited Create( iName, 1);
      Code:= iCode;
   end; // Create()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tVarByteArray.GetStrValue(): string;
   var
      Temp:        string;
      ReturnValue: string;
      i:           shortint;
      UB:          longint;
   begin
      UB:= Value.UpperBound;
      if( UB < 0) then begin
         ReturnValue:= '';
      end else begin
         Str( Value[ 0], ReturnValue);
         for i:= 1 to UB do begin
            Str( Value[ i], Temp);
            ReturnValue:= ReturnValue + ', ' + Temp;
         end;
      end;
      GetStrValue:= ReturnValue;
   end; // GetStrValue()


// ************************************************************************
// * Read() - Read this field's value from Buffer[ Pos].
// *          increments Pos to point at the next field.
// ************************************************************************

procedure tVarByteArray.Read( var Buffer: tNetBuffer;
                              var Pos:    word32);
   begin
      Code:= Buffer[ Pos];
      inc( Pos);
      MyLength:= Buffer[ Pos];
      inc( Pos);
      inherited Read( Buffer, Pos);
   end;


// ************************************************************************
// * Write() - Save this field's value in Buffer[ Pos].
// *           increments Pos to point at the next field.
// ************************************************************************

procedure tVarByteArray.Write( var Buffer: tNetBuffer;
                          var Pos:    word32);
   begin
      Buffer[ Pos]:= Code;
      inc( Pos);
      Buffer[ Pos]:= Lo( Length) - 2;
      inc( Pos);
      inherited Write( Buffer, Pos);
   end;


// ************************************************************************
// * GetLength() - Returns the length of the field in bytes
// ************************************************************************

function tVarByteArray.GetLength(): word16;
   begin
      result:= inherited GetLength + 2;
   end; // GetLength()


// ========================================================================
// = tVarClientID
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tVarClientID.Create();
   begin
      inherited Create( 61, 'Client Identifier');
   end; // Create()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tVarClientID.GetStrValue(): string;
   var
      i:         word;
      Temp:      string;
      UB:        longint;
      ColonFlag: boolean;
   begin
      UB:= Value.UpperBound;
      if( UB < 0) then begin
         Temp:= '[Invalid value!]';
      end else begin
         case Value[ 0] of
            1: Temp:= '[ethernet] '
            else Temp:= '[unknown] '
         end; // case
      end;

      ColonFlag:= false;
      for i:= 1 to UB do begin
         Temp:= Temp + HexStr( longint( Value[ i]), 2);
         if( ColonFlag and (i <> UB)) then begin
            Temp:= Temp + ':'
         end;
         ColonFlag:= not ColonFlag;
      end;
      Temp:= lowercase( Temp);
      GetStrValue:= Temp;
   end; // GetStrValue()


// ************************************************************************
// * SetStrValue() - Sets value of the field from a string.
// ************************************************************************

procedure tVarClientID.SetStrValue( iValue: string);
   var
      TempValue:  string;
      TempLength: word;
      iStr:       word;
      iByte:      word;
      HighNibble: boolean;
      Temp:       byte;
   begin
      TempValue:= RemoveNonHexCharacters( iValue);
      TempLength:= System.Length( TempValue);

      case TempLength of
         12: Value[ 0]:= 1; // ethernet
         else begin
            raise DHCPFieldException.Create(
               'VarClientID.SetStrValue(): Length does not match known types!');
         end;
      end; // case

      HighNibble:= true;
      iByte:= 1;
      for iStr:= 1 to TempLength do begin
         if( TempValue[ iStr] in ['0'..'9']) then begin
            Temp:= ord( TempValue[ iStr]) - ord('0');
         end else if( TempValue[ iStr] in ['a'..'f']) then begin
            Temp:= ord( TempValue[ iStr]) - ord('a') + 10;
         end else if( TempValue[ iStr] in ['A'..'F']) then begin
            Temp:= ord( TempValue[ iStr]) - ord('A') + 10;
         end else begin
            raise  DHCPFieldException.Create( 'VarClientID.SetStrValue():  ' +
                                   'Invalid character in input string!');
         end;
         if( HighNibble) then begin
            Value[ iByte]:= Temp SHL 4;
         end else begin
            Value[ iByte]:= Value[ iByte] + Temp;
            inc( iByte);
         end;
         HighNibble:= not HighNibble;
      end;
   end; // SetStrValue()


// ========================================================================
// = tVarParamReq
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tVarParamReq.Create();
   begin
      inherited Create( 55, 'Parameter Request List');
      Clear();
   end; // Create()


// ************************************************************************
// * Clear() - Set the value to the default or empty state
// ************************************************************************

procedure tVarParamReq.Clear();
   begin
      Value.UpperBound:= -1;
      Value[ 0]:= 1;
      Value[ 1]:= 15;
      Value[ 2]:= 3;
      Value[ 3]:= 6;
      Value[ 4]:= 44;
      Value[ 5]:= 46;
      Value[ 6]:= 47;
   end; // Clear()


// ========================================================================
// = tVarUnknown
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tVarUnknown.Create( iCode: byte);
   begin
      inherited Create( iCode, 'Unknown Option');
   end; // Create()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

// There is a bug in this section of code.
// The for loop never increments the i variable!

function tVarUnknown.GetStrValue(): string;
//    var
//       HexValue:    string;
//       ChrValue:    string;
//       i:           integer;
//       UB:          longint;
//       HexIndex:    shortint;
//       StrIndex:    shortint;
//       Temp:        byte;
//    begin
//       UB:= Value.UpperBound;
//       MyLength:= UB + 1;
//       if( UB < 0) then begin
//          result:= '';
//       end else begin
//
//          // Convert the array of bytes to a hex dump format
//          ChrValue:= StringOfChar( '.', Length);
//          HexValue:= StringOfChar( ' ', Length * 3);
//          HexIndex:= 1;
//          StrIndex:= 1;
//
//          // For each byte
//          for i:= 0 to UB do begin
// writeln( 'tVarUnknown.GetStrValue(): 1:  i = ', i);
//             Temp:= Value[ i];
//
//             // Add to the character string.
//             if( Chr( Temp) in  ['A'..'Z', 'a'..'z', '0'..'9', ' ']) then begin
//                ChrValue[ StrIndex]:= Chr( Temp);
//             end;
//             inc( StrIndex);
//
// //writeln( 'tVarUnknown.GetStrValue(): 2:  i = ', i);
//
//             // Handle the upper nibble
//             Temp:= Value[ i] SHR 4;
//             if( Temp > 9) then begin
//                HexValue[ HexIndex]:= Chr( Temp + ord( 'a') - 10);
//             end else begin
//                HexValue[ HexIndex]:= Chr( Temp + ord( '0'));
//             end;
//             inc( HexIndex);
//
// //writeln( 'tVarUnknown.GetStrValue(): 3:  i = ', i);
//
//             // Handle the lower nibble
//             Temp:= Value[ i] and 15;
//             if( Temp > 9) then begin
//                HexValue[ HexIndex]:= Chr( Temp + ord( 'a') - 10);
//             end else begin
//                HexValue[ HexIndex]:= Chr( Temp + ord( '0'));
//             end;
//             inc( HexIndex, 2);
// writeln( 'tVarUnknown.GetStrValue(): 4:  i = ', i);
//          end; // For each byte
//          Result:= HexValue + StrValue;
//       end; // else

   // Do this instead until the code above can be fixed
   begin
      result:= inherited GetStrValue();
   end; // GetStrValue()



// ========================================================================
// = tVarEnd
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tVarEnd.Create();
   begin
      inherited Create( 'End', $ff);
   end; // Create()


// ************************************************************************
// * Clear() - Clear the value to it's default
// ************************************************************************

procedure tVarEnd.Clear();
   begin
      Value:= $ff;
   end; // clear()

// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tVarEnd.GetStrValue(): string;
   begin
      case Value of
         $ff:  result:= 'Valid end of data code';
         0:    result:= 'Broken client ''pad'' = end of data';
         else  result:= 'invalid value (' + HexStr( Value, 2) + ')';
      end;
   end; // GetStrValue();


// ========================================================================
// = tVarPad
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tVarPad.Create();
   begin
      inherited Create( 'Pad', 0);
   end; // Create()



// ************************************************************************

end.  // lbp_dhcp_fields unit
