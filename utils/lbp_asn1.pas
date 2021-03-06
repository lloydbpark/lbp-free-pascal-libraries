{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

A partial implementation of ASN1 for use in SNMP

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

unit lbp_asn1;

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_types,
   lbp_utils,
   lbp_hexdump,
   classes;

// *************************************************************************
// * Constants
// *************************************************************************

const
   HighBitMask          = $0080;
   ByteMask             = $00ff;
   Base128Mask          = $007f;

   TagClassMask         = $00c0;
   TagConstructedMask   = $0020;
   TagLowFormMask       = $001f;

   TagClass_Universal   = 0;
   TagClass_Application = $0040;
   TagClass_Context     = $0080;
   TagClass_private     = $00c0;

   Tag_EndOfContents    = 0;
   Tag_Boolean          = 1;
   Tag_Integer          = 2;
   Tag_BitString        = 3;
   Tag_OctetString      = 4;
   Tag_Null             = 5;
   Tag_ObjectIdentifier = 6;
   Tag_Sequence         = 16;
   Tag_Set              = 17;
   Tag_PrintableString  = 19;
   Tag_T61String        = 20;
   Tag_IA5String        = 22;
   Tag_UTCTimeString    = 23;


// *************************************************************************
// * Global variables
// *************************************************************************
var
   DebugASN1Progress: boolean = false;


// *************************************************************************
// * Class definitions
// *************************************************************************

type
   asn1Exception = class( lbp_exception)
      public
         constructor Create( Msg: string);
      end; // asn1Exception class


// -------------------------------------------------------------------------

type
   tASN1Object = class
      private
         ExpectedTag:       int32;
         ExpectedTagClass:  integer;
         TagName:           string;
         WordCount:         int32;   // Used by BerDecode128xxx to record
                                     // the bytes read.
      public
         Tag:               int32;
         TagClass:          int32;
         ConstructedMethod: boolean;
         DataLength:        int32;
         constructor  Create( itag: int32; iTagClass: int32; iTagName: string);
          function     GetValue(): string; virtual; abstract;
          procedure    SetValue( Value: string); virtual; abstract;
          function     BerEncodeData( OutStream: tMemoryStream): int32; virtual; abstract;
//          function     BerDecodeData( Length: int32; InStream:  tMemoryStream): int32; virtual; abstract;
         function     BerEncode128Integer( Value: int32; OutStream: tMemoryStream): int32;
         function     BerEncode128Long( Value: word64; OutStream: tMemoryStream): int32;
         function     BerEncode256Integer( Value: int64; OutStream: tMemoryStream): int32;
         function     BerEncodeTag( OutStream: tMemoryStream): int32;
//          function     BerEncodeLength( OutStream: tMemoryStream): int32;
//          function     BerEncode( OutStream: tMemoryStream): int32;
//          function     BerDecode128Integer( InStream: tMemoryStream): int32;
//          function     BerDecode128Long( InStream: tMemoryStream): int64;
//          function     BerDecode256Integer( InStream: tMemoryStream): int64;
//          procedure    BerDecodeTag( InStream: tMemoryStream);
//          procedure    BerDecodeLength( InStream: tMemoryStream);
//          function     BerDecode( InStream: tMemoryStream): int32;
//          function     GetTagClassString(): string;
//          function     GetTagString(): string;
//          function     Dump(): string;
//          function     Dump( Indent1: string; Indent2: string): string;
//          function     HexDump( Indent: String): string;
      end; // tASN1Object


// -------------------------------------------------------------------------

type
   tASN1Integer = class( tASN1Object)
      public
         Value:      int64;
         constructor Create();
         constructor Create( iValue: int64);
         constructor Create( iValue: string);
         constructor  Create( itag: int32; iTagClass: int32; iTagName: string);
         function     GetValue(): string; virtual; abstract;
         procedure    SetValue( iValue: string); virtual; abstract;
         function     BerEncodeData( OutStream: tMemoryStream): int32; virtual; abstract;
//          function     BerDecodeData( Length: int32; InStream:  tMemoryStream): int32; virtual; abstract;
      end; // tASN1Integer



// *************************************************************************


implementation


// ========================================================================
// = tASN1Exception class
// ========================================================================
// *************************************************************************
// * Constructor
// *************************************************************************

constructor ASN1Exception.Create( Msg: string);
   begin
      inherited Create( 'ASN1 Error:  ' + Msg);
   end; // Create()


// ========================================================================
// = tASN1Object class
// ========================================================================
// *************************************************************************
// * Constructor
// *************************************************************************

constructor tASN1Object.Create( itag:     int32;   iTagClass: int32;
                                iTagName: string);
   begin
      Tag:=               iTag;
      ExpectedTag:=       iTag;
      TagClass:=          iTagClass;
      ExpectedTagClass:=  iTagClass;
      TagName:=           iTagName;
      ConstructedMethod:= false;
      DataLength:=        0;
      WordCount:=         0;
   end; // Create()


// *************************************************************************
// * BerEncode128Integer() - Encode the integer using BER.  Only accepts
// *                         integers up to 28 bits long!  Returns the
// *                         number of bytes written to OutStream.  Note:
// *                         7 bits of each byte is used to encode data.
// *************************************************************************

function tASN1Object.BerEncode128Integer( Value: int32;
                                          OutStream: tMemoryStream): int32;
   var
      MaxLength:  integer;
      MaxIndex:   integer;
      TempByte:   array[0..3] of byte;
      i:          integer;
      Len:        integer;
   begin
      MaxLength:= 4;
      MaxIndex:= MaxLength - 1;

      i:= Maxindex;
      repeat
         dec( i, 2);
         TempByte[ i]:= byte( Value and Base128Mask);
         Value:= Value shr 7;

         if( i < MaxIndex) then begin
            TempByte[ i]:= byte( tempByte[ i] or HighBitMask);
         end;
      until (Value = 0);

      // Output it
      Len:= MaxLength - i;
      OutStream.Write( TempByte[ i], Len);

      result:= Len;
   end; // BerEncode128Integer()


// *************************************************************************
// * BerEncode128Long() - Encode the 64bit integer using BER.  7 bits of
// *                      each byte is used to encode data.
// *************************************************************************

function tASN1Object.BerEncode128Long( Value: word64;
                                       OutStream: tMemoryStream): int32;
   var
      MaxLength:  integer;
      MaxIndex:   integer;
      TempByte:   array[0..8] of byte;
      i:          integer;
      Len:        integer;
   begin
      MaxLength:= 9;
      MaxIndex:= MaxLength - 1;

      i:= Maxindex;
      repeat
         dec( i, 2);
         TempByte[ i]:= byte( Value and Base128Mask);
         Value:= Value shr 7;

         if( i < MaxIndex) then begin
            TempByte[ i]:= byte( tempByte[ i] or HighBitMask);
         end;
      until (Value = 0);

      // Output it
      Len:= MaxLength - i;
      OutStream.Write( TempByte[ i], Len);

      result:= Len;
   end; // BerEncode128Long()


// *************************************************************************
// * BerEncode256Integer()  Encode the integer using BER.  Returns the
// *                        number of bytes written.
// *************************************************************************

function tASN1Object.BerEncode256Integer( Value: int64;
                                          OutStream: tMemoryStream): int32;
   var
      MaxLength:      integer;
      MaxIndex:       integer;
      TempByte:       array[0..3] of byte;
      i:              integer;
      Len:            integer;
      FirstIndex:     integer;
      Negative:       boolean;
      Insignificant:  byte;
   begin
      MaxLength:= 4;
      MaxIndex:= MaxLength - 1;
      FirstIndex:= MaxIndex;
      Negative:= (Value < 0);
      if Negative then begin
         Insignificant:= byte( ByteMask);
      end else begin
         Insignificant:= 0;
      end;

      // Move the integer into the TempArray
      for i:= MaxIndex downto 0 do begin

         // Put the low 8 bits of the input value into our byte array
         TempByte[ i]:= byte( Value and ByteMask);
         Value:= Value shr 8;

         // Is this the first significant byte we found?
         if( TempByte[ i] <> Insignificant) then begin
            FirstIndex:= i;
         end;
      end; // for

      // Are the first byte negative while the whole number is positive or
      //    visa-vers?
      if( Negative xor ((TempByte[ FirstIndex] and HighBitMask) <> 0)) then begin
         dec( FirstIndex);
      end;

      Len:= MaxLength - FirstIndex;

      OutStream.write( TempByte[ FirstIndex], Len);

      result:= Len;
   end; // BerEncode256Integer()


// *********************************************************************
// * BerEncodeTag()  Encode the Tag using BER.  Returns the number of
// *                 bytes written to OutStream.
// *********************************************************************

function tASN1Object.BerEncodeTag( OutStream: tMemoryStream): int32;
   var
      TempTag:    integer;
      Len:        integer;
      B:          Byte;
   begin
      Len:= 1;

      // Set the class bits
      TempTag:= TagClass;

      // Add the Constructed flag
      if( ConstructedMethod) then begin 
         TempTag:= TagConstructedMask or TempTag;
      end;

      // Does the tag fit in one byte?
      if( Tag < TagLowFormMask) then begin

         B:= Tag or TempTag;
         OutStream.Write( B, 1);
      end else begin

         // Multi-byte tag
         B:= byte( TagLowFormMask or TempTag);
         OutStream.Write( B, 1);
         inc( Len, BerEncode128Integer( Tag, OutStream));
      end; // else mult-byte tag
      
      result:= Len;
   end; // BerEncodeTag()


// *************************************************************************
// * HexDump()
// *************************************************************************

//function tASN1Object.HexDump( 

// ========================================================================
// = tASN1Integer class
// ========================================================================
// *************************************************************************
// * Constructor
// *************************************************************************

constructor tASN1Integer.Create();
   begin
      inherited Create( Tag_Integer, TagClass_Universal, 'Integer');
      Value:= 0;
   end; // Create()


// -------------------------------------------------------------------------

constructor tASN1Integer.Create( iValue: int64);
   begin
      inherited Create( Tag_Integer, TagClass_Universal, 'Integer');
      Value:= iValue;
   end; // Create()


// -------------------------------------------------------------------------

constructor tASN1Integer.Create( iValue: string);
   var
      Code: word;
   begin
      inherited Create( Tag_Integer, TagClass_Universal, 'Integer');
      Code:= 0;
      Val( iValue, Value, Code);
      if( Code <> 0) then begin
         raise asn1Exception.Create( 'IValue + is an illegal int64 value!');
      end;
   end; // Create()


// -------------------------------------------------------------------------

constructor tASN1Integer.Create( itag:     int32;   iTagClass: int32;
                                iTagName: string;  iValue:    int64);
   begin
      inherited Create( itag, iTagClass, iTagName);
      Value:= iValue;
   end; // Create()


// *************************************************************************
// * GetValue()  Returns the data part of the object as a string
// *************************************************************************

function ASN1Integer.GetValue(): string;
   var
      Temp: string;
   begin
      Str( Value, Temp);
      result:= Temp;
   end; // GetValue()


// *************************************************************************
// * SetValue() - Sets the data part of the object
// *************************************************************************

procedure ASN1Integer.SetValue( iValue: string);
   var
      Code: word;
   begin
      Code:= 0;
      Val( iValue, Value, Code);
      if( Code <> 0) then begin
         raise asn1Exception.Create( IValue + ' is an illegal int64 value!');
      end;
   end; // Create()
   

// *************************************************************************
// * BerEncodeData()  Encode the data part of the object using BER.
// *                  Returns the number of bytes written.
// *************************************************************************

function ASN1Integer.BerEncode( OutStream: tMemoryStream): int32;
   begin
      ConstructedMethod:= false;
      result:= inherited BerEncode( OutStream);
   end; // BerEncodeData()



// *************************************************************************
// * BerDecodeData()  Decode the Data part of the object using BER.
// *                  Returns the actual number of bytes read.
// *************************************************************************

function ASN1Integer.BerEncodeData( OutStream: tMemoryStream): int32;
   var
      OldSize: int64;
   begin
      OldSize:= OutStream.GetSize();
      OutStream.write( 
   end; // BerEncodeData()


// *************************************************************************

end. // lbp_asn1
