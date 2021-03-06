{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Classes that know how to read their data from and write to a packet.

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

unit lbp_net_fields;

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

interface

uses
   lbp_types,      // word32, etc
   lbp_vararray,
   lbp_lists,
   lbp_utils,
   lbp_ip_utils,
   lbp_log;


// ************************************************************************

type
   tNetBuffer = array of word8;

// ========================================================================

   NetFieldException = class( lbp_exception);
   tNetField = class
      protected
         MyLength:  word16;
      public
         Code:    byte;    // Currently only used by DHCP fields
         Name:    String;
         constructor  Create( iName: string; iLength: word);
         destructor   Destroy();        override;
         function     GetName(): string;
         procedure    Clear(); virtual; abstract;
         function     GetStrValue(): string; virtual; abstract;
         procedure    SetStrValue( iValue: string); virtual; abstract;
         procedure    Log( LogLevel: int16; PacketID: word32); virtual;
         procedure    Read( var Buffer: tNetBuffer;
                            var Pos: word32);      virtual; abstract;
         procedure    Write( var Buffer: tNetBuffer;
                             var Pos: word32);     virtual; abstract;
      protected
         function     GetLength(): word16; virtual;
      public
         property     StrValue: string read GetStrValue write SetStrValue;
         property     Length: word16 read GetLength;
      end; // tNetField class


// ========================================================================

   tFixedWord8 = class( tNetField) // 8 bit
      public
         Value:   word8;
         DefaultValue: word8;
         constructor  Create( iName: string; iValue: byte);
         procedure    Clear();       override;
         function     GetStrValue(): string; override;
         procedure    SetStrValue( iValue: string); override;
         function     GetDefaultStrValue(): string; virtual;
         procedure    SetDefaultStrValue( iValue: string); virtual;
         procedure    Read( var Buffer: tNetBuffer;
                            var Pos: word32);      override;
         procedure    Write( var Buffer: tNetBuffer;
                             var Pos: word32);     override;
         property     DefaultStrValue: string read  GetDefaultStrValue
                                              write SetDefaultStrValue;
      end;


// ========================================================================

   tFixedWord16 = class( tNetField) // 16 bit
      public
         Value:   word16;
         DefaultValue: word16;
         SavePos: word32;
         constructor  Create( iName: string; iValue: word);
         procedure    Clear();       override;
         function     GetStrValue(): string; override;
         procedure    SetStrValue( iValue: string); override;
         function     GetDefaultStrValue(): string; virtual;
         procedure    SetDefaultStrValue( iValue: string); virtual;
         procedure    Read( var Buffer: tNetBuffer;
                            var Pos: word32);      override;
         procedure    Write( var Buffer: tNetBuffer);
         procedure    Write( var Buffer: tNetBuffer;
                             var Pos: word32);     override;
         property     DefaultStrValue: string read  GetDefaultStrValue
                                              write SetDefaultStrValue;
      end;


// ========================================================================

   tFixedWord32 = class( tNetField) // 32 bit
      public
         Value:       word32;
         DefaultValue: word32;
         constructor  Create( iName: string; iValue: word32);
         procedure    Clear();       override;
         function     GetStrValue(): string; override;
         procedure    SetStrValue( iValue: string); override;
         function     GetDefaultStrValue(): string; virtual;
         procedure    SetDefaultStrValue( iValue: string); virtual;
         procedure    Read( var Buffer: tNetBuffer;
                            var Pos: word32);      override;
         procedure    Write( var Buffer: tNetBuffer;
                             var Pos: word32);     override;
         property     DefaultStrValue: string read  GetDefaultStrValue
                                              write SetDefaultStrValue;
      end;


// ========================================================================

   tFixedStr = class( tNetField)
      public
         Value:   string;
         constructor  Create( iName: string; iLength: word; iValue: string);
         destructor   Destroy();     override;
         procedure    Clear();       override;
         function     GetStrValue(): string; override;
         procedure    SetStrValue( iValue: string); override;
         procedure    Read( var Buffer: tNetBuffer;
                            var Pos: word32);      override;
         procedure    Write( var Buffer: tNetBuffer;
                             var Pos: word32);     override;
      end;


// ========================================================================

   tFixedIPAddr = class( tFixedWord32)
      public
         constructor  Create( iName: string);
         function     GetStrValue(): string; override;
         procedure    SetStrValue( iValue: string); override;
         function     GetDefaultStrValue(): string; override;
         procedure    SetDefaultStrValue( iValue: string); override;
         property     DefaultStrValue: string read  GetDefaultStrValue
                                              write SetDefaultStrValue;
      end;


// ========================================================================

   tVarWord8Array = class( tNetField)
      public
         Value:       ByteArray; // Dynamic array
         DefaultValue: ByteArray;
         constructor  Create( iName: string; iLength: word16);
         destructor   Destroy();     override;
         procedure    Clear();       override;
         function     GetStrValue(): string; override;
         procedure    SetStrValue( iValue: string); override;
         function     GetDefaultStrValue(): string; virtual;
         procedure    SetDefaultStrValue( iValue: string); virtual;
         procedure    Read( var Buffer: tNetBuffer;
                            var Pos: word32);      override;
         procedure    Write( var Buffer: tNetBuffer;
                             var Pos: word32);     override;
         property     DefaultStrValue: string read  GetDefaultStrValue
                                              write SetDefaultStrValue;
         function     GetLength(): word16;         override;
      end;


// ========================================================================

   tVarHexString = class( tVarWord8Array) // 8 bit
      public
         constructor  Create( iName: string; iLength: word16);
         function     GetStrValue(): string; override;
         procedure    SetStrValue( iValue: string); override;
         function     GetDefaultStrValue(): string; override;
         procedure    SetDefaultStrValue( iValue: string); override;
      end;


// ========================================================================

   tVarWord32Array = class( tNetField)
      public
         Value:       Word32Array; // Dynamic array
         constructor  Create( iName: string; iLength: word16);
         destructor   Destroy();     override;
         procedure    Clear();       override;
         function     GetStrValue(): string; override;
         procedure    SetStrValue( iValue: string); override;
         procedure    Read( var Buffer: tNetBuffer;
                            var Pos: word32);      override;
         procedure    Write( var Buffer: tNetBuffer;
                             var Pos: word32);     override;
         function     GetLength(): word16;         override;
      end;


// ========================================================================

   tCompoundNetField = class( tNetField)
      public
         Fields:      DoubleLinkedList;
         StartPos:    word32;
         constructor  Create( iName: string);
         destructor   Destroy();                    override;
         procedure    Clear();                      override;
         function     GetStrValue(): string;        override;
         procedure    SetStrValue( iValue: string); override;
         procedure    Log( LogLevel: int16; PacketID: word32); override;
         procedure    Read( var Buffer: tNetBuffer;
                            var Pos: word32);       override;
         procedure    Write( var Buffer: tNetBuffer;
                            var Pos: word32);       override;
      protected
         function     GetLength(): word16;          override;
      end; // tCompoundNetFiel class


// ========================================================================

   tEthHeaderNetField = class( tCompoundNetField)
      public
         DstMAC:     tVarHexString;
         SrcMAC:     tVarHexString;
         EthType:    tFixedWord16;
         constructor  Create();
      end;


// ========================================================================

   tIPHeaderNetField = class( tCompoundNetField)
      public
         IPVerLen:    tFixedWord8;
         DifServices: tFixedWord8;
         IPLength:    tFixedWord16; // handle externaly
         IPIdent:     tFixedWord16;
         IPFlags:     tFixedWord8;
         IPFragOff:   tFixedWord8;
         IPTTL:       tFixedWord8;
         IPProtocol:  tFixedWord8;
         IPHdrChkSum: tFixedWord16; // handle externaly
         SrcIP:       tFixedIPAddr;
         DstIP:       tFixedIPAddr;
         constructor  Create();
      end;


// ========================================================================

   tUDPHeaderNetField = class( tCompoundNetField)
      public
         SrcPort:     tFixedWord16;
         DstPort:     tFixedWord16;
         UDPLength:   tFixedWord16; // handle externaly
         UDPChkSum:   tFixedWord16; // handle externaly
         constructor  Create();
      end;


// ========================================================================

   tARPHeaderNetField = class( tCompoundNetField)
      public
         HardwareType:  tFixedWord16;
         ProtocolType:  tFixedWord16;
         HardwareSize:  tFixedWord8;
         ProtocolSize:  tFixedWord8;
         OpCode:        tFixedWord16;
         SenderMAC:     tVarHexString;
         SenderIP:      tFixedIPAddr;
         TargetMAC:     tVarHexString;
         TargetIP:      tFixedIPAddr;
         // On recieve ARPPad18 is not needed.  Can we do away with it for sent packets?
         Pad18:         tVarHexString; // 18 bytes of 00 to make the packet large enough.
         constructor  Create();
      end;


// ************************************************************************

function IPchecksum( Buffer:  tNetBuffer;
                      StartPos: word32; EndPos: word32): word16;

function PartialIPchecksum( PreviousSum: word16;
                            Buffer:      tNetBuffer;
                            StartPos:    word32;
                            EndPos:      word32): word16;

function FinalizeIPchecksum( PreviousSum: word16): word16;


// ************************************************************************

implementation


// ************************************************************************

const
   NamePadSize      = 23;

type
   word32Ptr = ^word32;


// ========================================================================
// = tNetField
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tNetField.Create( iName: string; iLength: word);
   begin
      Name:=   iName;
      MyLength:= iLength;
   end; // Create()


// ************************************************************************
// * Destroy() - Destructor
// ************************************************************************

destructor tNetField.Destroy();
   begin
      Name:= '';
   end; // Destroy();


// ************************************************************************
// * GetName()  Returns the name of this Field
// ************************************************************************

function tNetField.GetName(): string;
   begin
      GetName:= Name + StringOfChar( ' ', NamePadSize - System.Length( Name));
   end; // GetName()


// ************************************************************************
// * Log() - Use lbp_log.Log() to log the packet
// ************************************************************************

procedure tNetField.Log( LogLevel: int16; PacketID: word32);
   begin
      lbp_log.Log( LogLevel, '[%7.7D] %s -- %s',
                    [PacketID, GetName(), GetStrValue()]);
   end; // Log()


// ************************************************************************
// * GetLength() - Return the length of the field
// ************************************************************************

function tNetField.GetLength(): word16;
   begin
      result:= MyLength;
   end; // GetLength()



// ========================================================================
// = tFixedWord8
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tFixedWord8.Create( iName: string; iValue: byte);
   begin
      inherited Create( iName, 1);
      Value:= iValue;
      DefaultValue:= iValue;
   end; // Create()


// ************************************************************************
// * Clear() - Set the value to the default or empty state
// ************************************************************************

procedure tFixedWord8.Clear();
   begin
      Value:= DefaultValue;
   end; // Clear()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tFixedWord8.GetStrValue(): string;
   var
      Temp: string;
   begin
      Str( Value, Temp);
      GetStrValue:= Temp;
   end; // GetStrValue()


// ************************************************************************
// * SetStrValue() - Sets the value of the field using a string.
// ************************************************************************

procedure tFixedWord8.SetStrValue( iValue: string);
   var
      ErrorCode: word;
      Temp:      int32;
   begin
      val( iValue, Temp, ErrorCode);
      if( (ErrorCode > 0) or (Temp < 0)) then begin
         raise NetFieldException.Create(
               'tFixedWord8.SetStrValue():  Invalid ordinal value (' +
                  iValue + ')!');
      end;
      Value:= Word8( Temp);
   end; // SetStrValue();


// ************************************************************************
// * GetDefaultStrValue() - Returns the default value of the field as a string.
// ************************************************************************

function tFixedWord8.GetDefaultStrValue(): string;
   var
      Temp: string;
   begin
      Str( DefaultValue, Temp);
      result:= Temp;
   end; // GetDefaultStrValue()


// ************************************************************************
// * SetDefaultStrValue() - Sets the default value of the field from a string.
// ************************************************************************

procedure tFixedWord8.SetDefaultStrValue( iValue: string);
   var
      ErrorCode: word;
      Temp:      int32;
   begin
      val( iValue, Temp, ErrorCode);
      if( (ErrorCode > 0) or (Temp < 0)) then begin
         raise NetFieldException.Create(
               'tFixedWord8.SetStrValue():  Invalid ordinal value (' +
                  iValue + ')!');
      end;
      DefaultValue:= Word8( Temp);
   end; // SetDefaultStrValue();


// ************************************************************************
// * Read() - Read this field's value from Buffer[ Pos].
// *          increments Pos to point at the next field.
// ************************************************************************

procedure tFixedWord8.Read( var Buffer: tNetBuffer;
                           var Pos:    word32);
   begin
      Value:= Buffer[ Pos];
      inc( Pos);
   end; // Read()


// ************************************************************************
// * Write() - Save this field's value in Buffer[ Pos].
// *           increments Pos to point at the next field.
// ************************************************************************

procedure tFixedWord8.Write( var Buffer: tNetBuffer;
                           var Pos:    word32);
   begin
      Buffer[ Pos]:= Value;
      inc( Pos);
   end; // Write()


// ========================================================================
// = tFixedWord16
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tFixedWord16.Create( iName: string; iValue: word);
   begin
      inherited Create( iName, 2);
      Value:= iValue;
      DefaultValue:= iValue;
   end; // Create()


// ************************************************************************
// * Clear() - Set the value to the default or empty state
// ************************************************************************

procedure tFixedWord16.Clear();
   begin
      Value:= DefaultValue;
   end; // Clear()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tFixedWord16.GetStrValue(): string;
   var
      Temp: string;
   begin
      Str( Value, Temp);
      GetStrValue:= Temp;
   end; // GetStrValue()


// ************************************************************************
// * SetStrValue() - Sets the value of the field using a string.
// ************************************************************************

procedure tFixedWord16.SetStrValue( iValue: string);
   var
      ErrorCode: word;
      Temp:      int32;
   begin
      val( iValue, Temp, ErrorCode);
      if( (ErrorCode > 0) or (Temp < 0)) then begin
         raise NetFieldException.Create(
               'tFixedWord8.SetStrValue():  Invalid ordinal value (' +
                  iValue + ')!');
      end;
      Value:= Word16( Temp);
   end; // SetStrValue();


// ************************************************************************
// * GetDefaultStrValue() - Returns the default value of the field as a string.
// ************************************************************************

function tFixedWord16.GetDefaultStrValue(): string;
   var
      Temp: string;
   begin
      Str( DefaultValue, Temp);
      result:= Temp;
   end; // GetDefaultStrValue()


// ************************************************************************
// * SetDefaultStrValue() - Sets the default value of the field from a string.
// ************************************************************************

procedure tFixedWord16.SetDefaultStrValue( iValue: string);
   var
      ErrorCode: word;
      Temp:      int32;
   begin
      val( iValue, Temp, ErrorCode);
      if( (ErrorCode > 0) or (Temp < 0)) then begin
         raise NetFieldException.Create(
               'tFixedWord8.SetStrValue():  Invalid ordinal value (' +
                  iValue + ')!');
      end;
      Value:= Word16( Temp);
   end; // SetDefaultStrValue();


// ************************************************************************
// * Read() - Read this field's value from Buffer[ Pos].
// *          increments Pos to point at the next field.
// ************************************************************************

procedure tFixedWord16.Read( var Buffer: tNetBuffer;
                           var Pos:    word32);
   begin
      Value:= Buffer[ Pos] shl 8;
      inc( Pos);
      Value += Buffer[ Pos];
      inc( Pos);
   end; // Read()


// ************************************************************************
// * Write() - Save this field's value in Buffer[ Pos].
// *           increments Pos to point at the next field.
// ************************************************************************

procedure tFixedWord16.Write( var Buffer: tNetbuffer);
   begin
      Write( Buffer, SavePos);
   end; // write()


// ------------------------------------------------------------------------

procedure tFixedWord16.Write( var Buffer: tNetBuffer;
                            var Pos:    word32);
   begin
      SavePos:= Pos;
      Buffer[ Pos]:= Hi( Value);
      inc( Pos);
      Buffer[ Pos]:= Lo( Value);
      inc( Pos);
   end; // Write()


// ========================================================================
// = tFixedWord32
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tFixedWord32.Create( iName: string; iValue: word32);
   begin
      inherited Create( iName, 4);
      Value:= iValue;
      DefaultValue:= iValue;
   end; // Create()


// ************************************************************************
// * Clear() - Set the value to the default or empty state
// ************************************************************************

procedure tFixedWord32.Clear();
   begin
      Value:= DefaultValue;
   end; // Clear()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tFixedWord32.GetStrValue(): string;
   var
      Temp: string;
   begin
      Str( Value, Temp);
      GetStrValue:= Temp;
   end; // GetStrValue()


// ************************************************************************
// * SetStrValue() - Sets the value of the field using a string.
// ************************************************************************

procedure tFixedWord32.SetStrValue( iValue: string);
   var
      ErrorCode: word;
   begin
      val( iValue, Value, ErrorCode);
      if( ErrorCode > 0) then begin
         raise NetFieldException.Create(
               'tFixedWord32.SetStrValue():  Invalid ordinal value (' +
                  iValue + ')!');
      end;
   end; // SetStrValue();


// ************************************************************************
// * GetDefaultStrValue() - Returns the default value of the field as a string.
// ************************************************************************

function tFixedWord32.GetDefaultStrValue(): string;
   var
      Temp: string;
   begin
      Str( DefaultValue, Temp);
      result:= Temp;
   end; // GetDefaultStrValue()


// ************************************************************************
// * SetDefaultStrValue() - Sets the default value of the field from a string.
// ************************************************************************

procedure tFixedWord32.SetDefaultStrValue( iValue: string);
   var
      ErrorCode: word;
   begin
      val( iValue, DefaultValue, ErrorCode);
      if( ErrorCode > 0) then begin
         raise NetFieldException.Create(
               'tFixedWord8.SetDefaultStrValue():  Invalid ' +
               'ordinal value (' + iValue + ')!');
      end;
   end; // SetDefaultStrValue();


// ************************************************************************
// * Read() - Read this field's value from Buffer[ Pos].
// *          increments Pos to point at the next field.
// ************************************************************************

procedure tFixedWord32.Read( var Buffer: tNetBuffer;
                          var Pos:    word32);
   var
      i:  integer;
   begin
      for i:= 3 downto 0 do begin
         Word32ByteArray( Value).ByteValue[ i]:= Buffer[ Pos];
         inc( Pos);
      end;
   end; // Read()


// ************************************************************************
// * Write() - Save this field's value in Buffer[ Pos].
// *           increments Pos to point at the next field.
// ************************************************************************

procedure tFixedWord32.Write( var Buffer: tNetBuffer;
                           var Pos:    word32);
   var
      i:  integer;
   begin
      for i:= 3 downto 0 do begin
         Buffer[ Pos]:= Word32ByteArray( Value).ByteValue[ i];
         inc( Pos);
      end;
   end; // Write()


// ========================================================================
// = tFixedStr
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tFixedStr.Create( iName: string; iLength: word; iValue: string);
   begin
      inherited Create( iName, iLength);
      if( iLength < System.Length( iValue)) then begin
         raise NetFieldException.Create(
            'tFixedStr.Create():  String value is too long!');
      end;
      Value:= iValue;
   end; // Create()


// ************************************************************************
// * Destroy() - Destructor
// ************************************************************************

destructor tFixedStr.Destroy();
   begin
      Value:= '';
      inherited Destroy();
   end; // Destroy();


// ************************************************************************
// * Clear() - Set the value to the default or empty state
// ************************************************************************

procedure tFixedStr.Clear();
   begin
      Value:= '';
   end; // Clear()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tFixedStr.GetStrValue(): string;
   begin
      GetStrValue:= Value;
   end; // GetStrValue()


// ************************************************************************
// * SetStrValue() - Sets the value of the field using a string.
// ************************************************************************

procedure tFixedStr.SetStrValue( iValue: string);
   begin
      if( MyLength < System.Length( iValue)) then begin
         raise NetFieldException.Create(
            'tFixedStr.SetStrValue():  String value is too long!');
      end;
      Value:= iValue;
   end; // SetStrValue();


// ************************************************************************
// * Read() - Read this field's value from Buffer[ Pos].
// *          increments Pos to point at the next field.
// ************************************************************************

procedure tFixedStr.Read( var Buffer: tNetBuffer;
                          var Pos:    word32);
   var
      i:         word;
      L:         word;
      FoundNull: boolean;
   begin
      // Set Values length to the maximum size.
      System.SetLength( Value, MyLength);
      L:= MyLength;

      FoundNull:= false;
      i:= 0;
      while( i < L) do begin
         inc( i);
         if( not FoundNull) then begin
            if( Buffer[ Pos] = 0) then begin
               FoundNull:= true;
               System.SetLength( Value, i);
            end else begin
               Value[ i]:= chr( Buffer[ Pos]);
            end;
         end;
         inc( Pos);
      end;
      Pos += word32( MyLength - L);
   end; // Read()


// ************************************************************************
// * Write() - Save this field's value in Buffer[ Pos].
// *           increments Pos to point at the next field.
// ************************************************************************

procedure tFixedStr.Write( var Buffer: tNetBuffer;
                           var Pos:    word32);
   var
      i:  integer;
      L:  integer;
   begin
      L:= System.Length( Value);
      if( L > MyLength) then begin
         raise NetFieldException.Create(
            'tFixedStr.Read():  String value is too long!');
      end;
      i:= 0;
      while( i < L) do begin
         inc( i);
         Buffer[ Pos]:= ord( Value[ i]);
         inc( Pos);
      end;
      while( i < MyLength) do begin
         inc( i);
         Buffer[ Pos]:= 0;
         inc( pos)
      end;
   end; // Write()


// ========================================================================
// = tFixedIPAddr
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tFixedIPAddr.Create( iName: string);
   begin
      inherited Create( iName, 0);
   end; // Create()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tFixedIPAddr.GetStrValue(): string;
   begin
      GetStrValue:= IPWord32ToString( Value);
   end; // GetStrValue()


// ************************************************************************
// * SetStrValue() - Sets value of the field from a string.
// ************************************************************************

procedure tFixedIPAddr.SetStrValue( iValue: string);
   begin
      Value:= IPStringToWord32( iValue);
   end; // SetStrValue()


// ************************************************************************
// * GetDefaultStrValue() - Returns the default value of the field as a string.
// ************************************************************************

function tFixedIPAddr.GetDefaultStrValue(): string;
   begin
      result:= IPWord32ToString( DefaultValue);
   end; // GetStrValue()


// ************************************************************************
// * SetDefaultStrValue() - Sets default value of the field from a string.
// ************************************************************************

procedure tFixedIPAddr.SetDefaultStrValue( iValue: string);
   begin
      DefaultValue:= IPStringToWord32( iValue);
   end; // SetStrValue()




// ========================================================================
// = tVarWord8Array
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tVarWord8Array.Create( iName: string; iLength: word16);
   var
      L: word16;
      i: word16;
   begin
      inherited Create( iName, iLength);
      Value:= ByteArray.Create( iLength);
      DefaultValue:= ByteArray.Create( iLength);

      // Clear the Value and Default value to zeros
      L:= iLength - 1;
      for i:= 0 to L do begin
         DefaultValue[ i]:= 0;
         Value[ i]:= 0;
      end;
   end; // Create()


// ************************************************************************
// * Destroy() - Destructor
// ************************************************************************

destructor tVarWord8Array.Destroy();
   begin
      Value.Destroy();
      DefaultValue.Destroy();
      inherited Destroy();
   end; // Destroy();


// ************************************************************************
// * Clear() - Set the value to the default or empty state
// ************************************************************************

procedure tVarWord8Array.Clear();
   var
      L: word16;
      i: word16;
   begin
      Value.UpperBound:= -1;
      L:= DefaultValue.UpperBound;
      for i:= 0 to L do begin
         Value[ i]:= DefaultValue[ i];
      end;
   end; // Clear()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tVarWord8Array.GetStrValue(): string;
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
// * SetStrValue() - Sets the value of the field using a string.
// ************************************************************************

procedure tVarWord8Array.SetStrValue( iValue: string);
   var
      TempStr:   string;
      StrI:      word16;
      StrStart:  word16;
      StrLen:    word16;
      ValueI:    word16;
      ErrorCode: word;
      Temp:      int32;
   begin
      StrLen:= system.Length( iValue);
      if( StrLen = 0) then begin
         Value.UpperBound:= -1;
         exit;
      end;

      StrI:= 1;
      StrStart:= 1;
      ValueI:= 0;
      while( StrI <= StrLen) do begin
         while( (StrI <= StrLen) and (iValue[ StrI] <> ',')) do begin
            inc( StrI);
         end;

         TempStr:= Copy( iValue, StrStart, StrI - StrStart);
         Temp:= Value[ ValueI];
         val( TempStr, Temp, ErrorCode);
         if( (ErrorCode > 0) or (Temp < 0)) then begin
            raise NetFieldException.Create(
                  'tVarWord8Array.SetStrValue():  Invalid ordinal value (' +
                     TempStr + ')!');
         end; // if Error
         Value[ ValueI]:= Word8( Temp);
         inc( ValueI);
      end; // while
   end; // SetStrValue();


// ************************************************************************
// * GetDefaultStrValue() - Returns the default value of the field as a string.
// ************************************************************************

function tVarWord8Array.GetDefaultStrValue(): string;
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
            Str( DefaultValue[ i], Temp);
            ReturnValue:= ReturnValue + ', ' + Temp;
         end;
      end;
      result:= ReturnValue;
   end; // GetDefaultStrValue()


// ************************************************************************
// * SetDefaultStrValue() - Sets the Default value of the field using a string.
// ************************************************************************

procedure tVarWord8Array.SetDefaultStrValue( iValue: string);
   var
      TempStr:   string;
      StrI:      word16;
      StrStart:  word16;
      StrLen:    word16;
      ValueI:    word16;
      ErrorCode: word;
      Temp:      int32;
   begin
      StrLen:= system.Length( iValue);
      if( StrLen = 0) then begin
         Value.UpperBound:= -1;
         exit;
      end;

      StrI:= 1;
      StrStart:= 1;
      ValueI:= 0;
      while( StrI <= StrLen) do begin
         while( (StrI <= StrLen) and (iValue[ StrI] <> ',')) do begin
            inc( StrI);
         end;

         TempStr:= Copy( iValue, StrStart, StrI - StrStart);
         Temp:= DefaultValue[ ValueI];
         val( TempStr, Temp, ErrorCode);
         if( (ErrorCode > 0) or (Temp < 0)) then begin
            raise NetFieldException.Create(
                  'tVarWord8Array.SetDefaultStrValue():  Invalid ordinal value (' +
                     TempStr + ')!');
         end; // if Error
         DefaultValue[ ValueI]:= Word8( Temp);
         inc( ValueI);
      end; // while
   end; // SetDefaultStrValue();


// ************************************************************************
// * Read() - Read this field's value from Buffer[ Pos].
// *          increments Pos to point at the next field.
// ************************************************************************

procedure tVarWord8Array.Read( var Buffer: tNetBuffer;
                              var Pos:    word32);
   var
      i:  integer;
      UB: integer;
   begin
      Value.UpperBound:= -1;
      UB:= MyLength - 1;
      for i:= 0 to UB do begin
         Value[ i ]:= Buffer[ Pos];
         inc( Pos);
      end;
   end; // Read()


// ************************************************************************
// * Write() - Save this field's value in Buffer[ Pos].
// *           increments Pos to point at the next field.
// ************************************************************************

procedure tVarWord8Array.Write( var Buffer: tNetBuffer;
                                var Pos:    word32);
   var
      i:  integer;
      UB: integer;
   begin
      UB:= Value.UpperBound;
      for i:= 0 to UB do begin
         Buffer[ Pos]:= Value[ i];
         inc( Pos);
      end;
   end; // Write()


// ************************************************************************
// * GetLength() - Return the length of the field
// ************************************************************************

function tVarWord8Array.GetLength(): word16;
   begin
      result:= word16( Value.UpperBound + 1);
   end; // GetLength()



// ========================================================================
// = tVarHexString
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tVarHexString.Create( iName: string; iLength: word16);
   begin
      inherited Create( iName, iLength);
   end; // Create()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tVarHexString.GetStrValue(): string;
   var
      i:           word;
      Temp:        string = '';
      ValueLength: int32;
   begin
      ValueLength:= Value.UpperBound;
      for i:= 0 to ValueLength do begin
         Temp:= Temp + HexStr( longint( Value[ i]), 2);
      end;
      Temp:= lowercase( Temp);
      result:= Temp;
   end; // GetStrValue()


// ************************************************************************
// * SetStrValue() - Sets value of the field from a string.
// ************************************************************************

procedure tVarHexString.SetStrValue( iValue: string);
   var
      TempValue:  string;
      TempLength: word;
      iStr:       word;
      iByte:      word;
      HighNibble: boolean;
      Temp:       byte;
   begin
      TempValue:= RemoveNonHexCharacters( iValue);
      TempLength:= (Value.UpperBound + 1) * 2;
      if( System.Length( TempValue) <> TempLength) then begin
         raise NetFieldException.Create( 'tVarHexString.SetStrValue():  ' +
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
            raise  NetFieldException.Create( 'tVarHexString.SetStrValue():  ' +
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

function tVarHexString.GetDefaultStrValue(): string;
   var
      i:           word;
      Temp:        string = '';
      ValueLength: int32;
   begin
      ValueLength:= Value.UpperBound;
      for i:= 0 to ValueLength do begin
         Temp:= Temp + HexStr( longint( DefaultValue[ i]), 2);
      end;
      Temp:= lowercase( Temp);
      result:= Temp;
   end; // GetDefaultStrValue()


// ************************************************************************
// * SetDefaultStrValue() - Sets default value of the field from a string.
// ************************************************************************

procedure tVarHexString.SetDefaultStrValue( iValue: string);
   var
      TempValue:  string;
      TempLength: word;
      iStr:       word;
      iByte:      word;
      HighNibble: boolean;
      Temp:       byte;
   begin
      TempValue:= RemoveNonHexCharacters( iValue);
      TempLength:= (Value.UpperBound + 1) * 2;
      if( System.Length( TempValue) <> TempLength) then begin
         raise NetFieldException.Create(
                    'tVarHexString.SetStrValue():  ' +
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
            raise  NetFieldException.Create(
                        'tVarHexString.SetDefaultStrValue():  ' +
                        'Invalid character in input string!');
         end;
         if( HighNibble) then begin
            DefaultValue[ iByte]:= Temp SHL 4;
         end else begin
            DefaultValue[ iByte]:= DefaultValue[ iByte] + Temp;
            inc( iByte);
         end;
         HighNibble:= not HighNibble;
      end;
   end; // SetDefaultStrValue()



// ========================================================================
// = tVarWord32Array
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tVarWord32Array.Create( iName: string; iLength: word16);
   begin
      inherited Create( iName, iLength);
      Value:= Word32Array.Create( iLength);
      Clear();
   end; // Create()


// ************************************************************************
// * Destroy() - Destructor
// ************************************************************************

destructor tVarWord32Array.Destroy();
   begin
      inherited Destroy();
      Value.Destroy();
   end; // Destroy();


// ************************************************************************
// * Clear() - Set the value to the default or empty state
// ************************************************************************

procedure tVarWord32Array.Clear();
   begin
      Value.UpperBound:= -1;
   end; // Clear()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tVarWord32Array.GetStrValue(): string;
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
// * SetStrValue() - Sets the value of the field using a string.
// ************************************************************************

procedure tVarWord32Array.SetStrValue( iValue: string);
   var
      TempStr:   string;
      Temp:      word32;
      StrI:      word16;
      StrStart:  word16;
      StrLen:    word16;
      ValueI:    word16;
      ErrorCode: word;
   begin
      StrLen:= system.Length( iValue);
      if( StrLen = 0) then begin
         Value.UpperBound:= -1;
         exit;
      end;

      StrI:= 1;
      StrStart:= 1;
      ValueI:= 0;
      while( StrI <= StrLen) do begin
         while( (StrI <= StrLen) and (iValue[ StrI] <> ',')) do begin
            inc( StrI);
         end;

         TempStr:= Copy( iValue, StrStart, StrI - StrStart);
         Temp:= Value[ ValueI];
         val( TempStr, Temp, ErrorCode);
         if( ErrorCode > 0) then begin
            raise NetFieldException.Create(
                  'tVarWord32Array.SetStrValue():  Invalid ordinal value (' +
                     TempStr + ')!');
         end; // if Error
         Value[ ValueI]:= Temp;
         inc( ValueI);
      end; // while
   end; // SetStrValue();


// ************************************************************************
// * Read() - Read this field's value from Buffer[ Pos].
// *          increments Pos to point at the next field.
// ************************************************************************

procedure tVarWord32Array.Read( var Buffer: tNetBuffer;
                                var Pos:    word32);
   var
      WordIndex:  integer;
      i:          integer;
      UB:         integer;
      Temp: Word32ByteArray;
   begin
      UB:= (MyLength div 4) - 1;
      Value.UpperBound:= -1;

      for WordIndex:= 0 to UB do begin
         // Output each word32 value
         for i:= 3 downto 0 do begin
            Temp.ByteValue[ i]:= Buffer[ Pos];
            inc( Pos);
         end;
         Value[ WordIndex]:= Temp.Word32Value;
      end;
   end; // Read()


// ************************************************************************
// * Write() - Save this field's value in Buffer[ Pos].
// *           increments Pos to point at the next field.
// ************************************************************************

procedure tVarWord32Array.Write( var Buffer: tNetBuffer;
                            var Pos:    word32);
   var
      WordIndex:  integer;
      i:          integer;
      UB:         integer;
      Temp: Word32ByteArray;
   begin
      UB:= Value.UpperBound;
      for WordIndex:= 0 to UB do begin
         // Output each word32 value
         Temp:= Word32ByteArray( Value[ WordIndex]);
         for i:= 3 downto 0 do begin
            Buffer[ Pos]:= Temp.ByteValue[ i];
            inc( Pos);
         end;
      end;
   end; // Write()


// ************************************************************************
// * GetLength() - Return the length of the field
// ************************************************************************

function tVarWord32Array.GetLength(): word16;
   begin
      result:= word16( Value.UpperBound + 1) * 4;
   end; // GetLength()



// ========================================================================
// = tCompoundNetField
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tCompoundNetField.Create( iName: string);
   begin
      inherited Create( iName, 0);
      Fields:= DoubleLinkedList.Create();
      StartPos:= 0;
   end; // Create()


// ************************************************************************
// * Destroy() - Destructor
// ************************************************************************

destructor tCompoundNetField.Destroy();
   var
      Temp: tNetField;
   begin
      while( not Fields.Empty()) do begin
         Temp:= tNetField( Fields.Dequeue());
         Temp.Destroy();
      end;
      Fields.Destroy();
   end; // Destroy();


// ************************************************************************
// * Clear() - Set the value to the default or empty state
// ************************************************************************

procedure tCompoundNetField.Clear();
   var
      F: tNetField;
   begin
      StartPos:= 0;
      MyLength:= 0;
      F:= tNetField( Fields.GetFirst());
      while( F <> nil) do begin
         F.Clear();
         F:= tNetField( Fields.GetNext());
      end;
   end; // Clear()


// ************************************************************************
// * GetStrValue() - Returns the value of the field as a string.
// ************************************************************************

function tCompoundNetField.GetStrValue(): string;
   var
      F:    tNetField;
      Temp: string;
   begin
      Temp:= '';
      F:= tNetField( Fields.GetFirst());
      while( F <> nil) do begin
         if( system.length( Temp) = 0) then begin
            Temp:= F.GetStrValue();
         end else begin
            Temp:= Temp + LineEnding + F.GetStrValue();
         end;
         F:= tNetField( Fields.GetNext());
      end;
      result:= Temp;
   end; // GetStrValue()


// ************************************************************************
// * SetStrValue() - Sets the value of the field using a string.
// ************************************************************************

procedure tCompoundNetField.SetStrValue( iValue: string);
   begin
      raise NetFieldException.Create(
              'tCompoundNetField.SetStrValue():  ' +
              'Not possible to set a compound value!');
   end; // SetStrValue();


// ************************************************************************
// * Read() - Read this field's value from Buffer[ Pos].
// *          increments Pos to point at the next field.
// ************************************************************************

procedure tCompoundNetField.Read( var Buffer: tNetBuffer;
                           var Pos:    word32);
   var
      F: tNetField;
   begin
      StartPos:= Pos;
      F:= tNetField( Fields.GetFirst());
      while( F <> nil) do begin
         F.Read( Buffer, Pos);
         F:= tNetField( Fields.GetNext());
      end;
      MyLength:= Pos - StartPos;
   end; // Read()


// ************************************************************************
// * Write() - Save this field's value in Buffer[ Pos].
// *           increments Pos to point at the next field.
// ************************************************************************

procedure tCompoundNetField.Write( var Buffer: tNetBuffer;
                           var Pos:    word32);
   var
      F: tNetField;
   begin
      StartPos:= Pos;
      F:= tNetField( Fields.GetFirst());
      while( F <> nil) do begin
         F.Write( Buffer, Pos);
         F:= tNetField( Fields.GetNext());
      end;
      MyLength:= Pos - StartPos;
   end; // Write()


// ************************************************************************
// * Log() - Use lbp_log.Log() to log the packet
// ************************************************************************

procedure tCompoundNetField.Log( LogLevel: int16; PacketID: word32);
   var
      F: tNetField;
   begin
      F:= tNetField( Fields.GetFirst());
      while( F <> nil) do begin
         F.Log( LogLevel, PacketID);
         F:= tNetField( Fields.GetNext());
      end;
   end; // Log()


// ************************************************************************
// * GetLength() - Return the length of the field
// ************************************************************************

function tCompoundNetField.GetLength(): word16;
   var
      F: tNetField;
   begin
      if( MyLength = 0) then begin
         F:= tNetField( Fields.GetFirst());
         if( F = nil) then begin
            result:= 0;
            exit;
         end;

         while( F <> nil) do begin
            MyLength:= MyLength + F.Length;
            F:= tNetField( Fields.GetNext());
         end;
      end; // if MyLength = 0;
      result:= MyLength;
   end; // GetLength()


// ========================================================================
// = tEthHeaderNetField
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tEthHeaderNetField.Create();
   begin
      inherited Create( 'Ethernet Header');
      DstMAC:= tVarHexString.Create( 'Destination MAC', 6);
      SrcMAC:= tVarHexString.Create( 'Source MAC', 6);
      EthType:= tFixedWord16.Create( 'Ethernet protocol', $0800);

      Fields.Enqueue( DstMAC);
      Fields.Enqueue( SrcMAC);
      Fields.Enqueue( EthType);
   end; // Create()


// ========================================================================
// = tIPHeaderNetField
// ========================================================================

constructor tIPHeaderNetField.Create();
   begin
      inherited Create( 'IP Header');

      // Initialize our list of fields.
      IPVerLen:=    tFixedWord8.Create( 'IP Version & Length', $45);
      DifServices:= tFixedWord8.Create( 'IP Diff. Serv.', 0);
      // Length of packet from start of IP header
      IPLength:=    tFixedWord16.Create( 'IP Total Length', 0);
      IPIdent:=     tFixedWord16.Create( 'IP Identification', 0);
      IPFlags:=     tFixedWord8.Create( 'IP Flags', 64);
      IPFragOff:=   tFixedWord8.Create( 'IP Fragment Offset', 0);
      IPTTL:=       tFixedWord8.Create( 'IP Time To Live', 64);
      IPProtocol:=  tFixedWord8.Create( 'IP Protocol', 17); //udp
      IPHdrChkSum:= tFixedWord16.Create( 'IP Header Checksum', 0);
      SrcIP:=       tFixedIPAddr.Create( 'IP Source Address');
      DstIP:=       tFixedIPAddr.Create( 'IP Destination Address');

      Fields.Enqueue( IPVerLen);
      Fields.Enqueue( DifServices);
      Fields.Enqueue( IPLength);
      Fields.Enqueue( IPIdent);
      Fields.Enqueue( IPFlags);
      Fields.Enqueue( IPFragOff);
      Fields.Enqueue( IPTTL);
      Fields.Enqueue( IPProtocol);
      Fields.Enqueue( IPHdrChkSum);
      Fields.Enqueue( SrcIP);
      Fields.Enqueue( DstIP);
   end; // Create()


{// ************************************************************************
// * Read() - Read this field's value from Buffer[ Pos].
// *          increments Pos to point at the next field.
// ************************************************************************

procedure tIPHeaderNetField.Read( var Buffer: tNetBuffer;
                                  var Pos:    word32);
   begin
      inherited Read( Buffer, Pos);

      // Do we need to check the checksum?
      if( IPHdrChkSum.Value <> 0) then begin
         if( IPchecksum( Buffer, StartPos, StartPos + Length -1) <> 0)
                                            then begin
            raise NetFieldException.Create( 'IP Header checksum failed!');
         end;
      end;
   end; // Read()


// ************************************************************************
// * Write() - Save this field's value in Buffer[ Pos].
// *           increments Pos to point at the next field.
// ************************************************************************

procedure tIPHeaderNetField.Write( var Buffer: tNetBuffer;
                           var Pos:    word32);
   begin
      inherited Write( Buffer, Pos);

      IPHdrChkSum.Value:= IPchecksum( Buffer, StartPos, StartPos + Length -1);
      IPHdrChkSum.Write( Buffer);
   end; // Write()


}
// ========================================================================
// = tUDPHeaderNetField
// ========================================================================

constructor tUDPHeaderNetField.Create();
   begin
      inherited Create( 'UDP Header');

      // Initialize our list of fields.
      SrcPort:=     tFixedWord16.Create( 'Source Port', 0);
      DstPort:=     tFixedWord16.Create( 'Destination Port', 0);
      UDPLength:=   tFixedWord16.Create( 'UDP length', 0);
      UDPChkSum:=   tFixedWord16.Create( 'UDP Checksum', 0);

      Fields.Enqueue( SrcPort);
      Fields.Enqueue( DstPort);
      Fields.Enqueue( UDPLength);
      Fields.Enqueue( UDPChkSum);
   end; // Create()


// ========================================================================
// = tUDPHeaderNetField
// ========================================================================
{$WARNING tARPHeaderNetField.Create() is untested!}
constructor tARPHeaderNetField.Create();
   begin
      inherited Create( 'ARP Protocol');

      // Initialize our list of fields.
      HardwareType:=  tFixedWord16.Create( 'ARP Hardware Type', 1);
      ProtocolType:=  tFixedWord16.Create( 'ARP Protocol Type', $800);
      HardwareSize:=  tFixedWord8.Create( 'ARP Hardware Size', 6);
      ProtocolSize:=  tFixedWord8.Create( 'ARP Protocol Size', 4);
      OpCode:=        tFixedWord16.Create( 'ARP OpCode', 1);
      SenderMAC:=     tVarHexString.Create( 'ARP Sender MAC', 6);
      SenderIP:=      tFixedIPAddr.Create( 'ARP Sender IP');
      TargetMAC:=     tVarHexString.Create( 'ARP Target MAC', 6);
      TargetIP:=      tFixedIPAddr.Create( 'ARP Target IP');
      Pad18:=        tVarHexString.Create( 'Padding', 18);

      Fields.Enqueue( HardwareType);
      Fields.Enqueue( ProtocolType);
      Fields.Enqueue( HardwareSize);
      Fields.Enqueue( ProtocolSize);
      Fields.Enqueue( OpCode);
      Fields.Enqueue( SenderMAC);
      Fields.Enqueue( SenderIP);
      Fields.Enqueue( TargetMAC);
      Fields.Enqueue( TargetIP);
      Fields.Enqueue( Pad18);
   end; // Create()


// ========================================================================
// = Global procedures
// ========================================================================
// ************************************************************************
// * PartialIPchecksum() - Calculates partial checksums used in IP
// *                       packets.  You can call this once for each
// *                       part of a packet (Payload, header) and then
// *                       call FinalizeIPchcksum() to finish the sum.
// ************************************************************************

function PartialIPchecksum( PreviousSum: word16;
                            Buffer:      tNetBuffer;
                            StartPos:    word32;
                            EndPos:      word32): word16;
   var
      Sum:             word32;
      i:               word32;
      AddHigh:         boolean;
   begin
      Sum:= PreviousSum;
      AddHigh:= true;

      for i:= StartPos to EndPos do begin
         if( AddHigh) then begin
            Sum:= Sum + (word32( Buffer[ i]) shl 8);
         end else begin
            Sum:= Sum + word32( Buffer[ i]);
         end;

         // Add the carry
         if( Sum > $ffff) then begin
            Sum:= Sum - $ffff;
         end;

         AddHigh:= not AddHigh;
      end;

      result:= word16( Sum);
   end; // PartialIPchecksum()


// ************************************************************************
// * FinalizeIPchecksum() - Finishes the checksum started in Calculates checksums used in IP packets
// ************************************************************************

function FinalizeIPchecksum( PreviousSum: word16): word16;
   begin
      result:= not PreviousSum;
   end; // FinalizeIPchecksum()


// ************************************************************************
// * IPchecksum() - Calculates checksums used in IP packets
// ************************************************************************

function IPchecksum( Buffer:  tNetBuffer;
                     StartPos: word32; EndPos: word32): word16;
   var
      TempSum:         word16;
   begin
      TempSum:= PartialIPchecksum( 0, Buffer, StartPos, EndPos);
      result:= FinalizeIPchecksum( TempSum);
   end; // IPchecksum()


// ************************************************************************

end.  // lbp_Net_fields unit
