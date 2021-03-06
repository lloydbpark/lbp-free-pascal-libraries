{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Utility functions to convert string representations of IP addresses / netmasks 
to 32 bit words and string ethernet addresses to 64 bit words.

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

// Utilities to convert IP addresses / netmasks to network numbers, broadcast
// numbers, 32 bit integers, 64 bit integers, etc.

unit lbp_ip_utils;

{$include lbp_standard_modes.inc}


// *************************************************************************

interface

uses
   lbp_types,
   lbp_utils,
   sysutils;

// ************************************************************************

// IP address conversion
function IPWord32ToString( const X: Word32; const Dot: char = '.'): string;
function IPWord32ToPaddedString( const X: Word32; const Dot: char = '.'): string;
function IPStringToWord32( const S: string): Word32;
function NetmaskToPrefix( NetMask: Word32): Word8;
function PrefixToNetMask( Prefix: Word8): Word32;

// Reverse the order of elements in a '.' separated string
function ReverseDottedOrder( const S: string; const Dot: char = '.'): string;


// ************************************************************************

// MAC address conversion
function MACWord64ToString( const X:     word64;
                                  C:     char = ':';
                                  Count: int32 = 4): string;
function MACStringToWord64( const S: String): word64;
function InsertSeparators( S:     string;
                           C:     char = ':';
                           Count: int32 = 4): string;
function RemoveNonHexCharacters( const S: String): String;


// *************************************************************************

type
   IPConversionException  = class( lbp_exception);
   MACConversionException = class( lbp_exception);

// ************************************************************************

type
   Word32ByteArray = record
      case byte of
         0: (Word32Value: Word32);
         1: (ByteValue:     array[ 0..3] of byte);
   end;
   Word32ByteArrayPtr = ^Word32ByteArray;

// *************************************************************************

const
   // Each possible netmask.  A /24 netmask is Slash[ 24]
   Slash:         array[ 0..32] of Word32 = (
                  $000000000, $080000000, $0c0000000, $0e0000000,
                  $0f0000000, $0f8000000, $0fc000000, $0fe000000,
                  $0ff000000, $0ff800000, $0ffc00000, $0ffe00000,
                  $0fff00000, $0fff80000, $0fffc0000, $0fffe0000,
                  $0ffff0000, $0ffff8000, $0ffffc000, $0ffffe000,
                  $0fffff000, $0fffff800, $0fffffc00, $0fffffe00,
                  $0ffffff00, $0ffffff80, $0ffffffc0, $0ffffffe0,
                  $0fffffff0, $0fffffff8, $0fffffffc, $0fffffffe,
                  $0ffffffff);


const
   MACSize: byte = 12;

// *************************************************************************

implementation

// ************************************************************************
// * IPWord32ToString()  Convert the Word32 (in host order)
//                         representation of an IP address to a String.
// ************************************************************************

function IPWord32ToString( const X: Word32; const Dot: char = '.'): string;
   var
      Temp:    Word32ByteArray;
      Octet:   string[ 4];
      IPStr:   string[ 15];
      i:       word;
   begin
      IPStr:= '';
      Temp.Word32Value:= X;
      for i:= 3 downto 0 do begin
         Str( Temp.ByteValue[ i], Octet);
         if( i < 3) then begin
            IPStr:= IPStr + Dot + Octet;
         end else begin
            IPStr:= IPStr + Octet;
         end;
      end; // for

      result:= IPStr;
   end; // IPWord32ToString();


// ************************************************************************
// * IPWord32ToPaddedString()  Convert the Word32 (in host order)
//                         representation of an IP address to a String with
//                         each octet zero padded to 3 digits.
// ************************************************************************

function IPWord32ToPaddedString( const X: Word32; const Dot: char = '.'): string;
   var
      Temp:    Word32ByteArray;
      Octet:   string[ 4];
      B:       byte;
      IPStr:   string[ 15];
      i:       word;
   begin
      IPStr:= '';
      Temp.Word32Value:= X;
      for i:= 3 downto 0 do begin
         B:= Temp.ByteValue[ i];
         Str( B, Octet);

         // Left pad with zeros to 3 digits
         if( B < 10) then begin
            Octet:= '00' + Octet;
         end else if( B < 100) then begin
            Octet:= '0' + Octet;
         end;

         if( i < 3) then begin
            IPStr:= IPStr + Dot + Octet;
         end else begin
            IPStr:= IPStr + Octet;
         end;
      end; // for

      result:= IPStr;
   end; // IPWord32ToPaddedString();


// ************************************************************************
// * IPStringToWord32()  Convert the string representation of an IP
// *                       address to a Word32 (in host order).
// ************************************************************************

function IPStringToWord32( const S: string): Word32;
   var
      Temp:        Word32ByteArray;
      iByte:       smallint; // index into Temp.ByteValue
      iStr:        smallint; // index into S
      Octet:       String[ 4];
      iOctet:      smallint; // index into Octet
      Found:       boolean;
      ByteValue:   word32;
      Code:        word;
      StrLength:   word;
   begin
      iByte:= 3;
      iOctet:= 0;
      Found:= false;
      StrLength:= Length( S);

      // for each character is S
      for iStr:= 1 to StrLength do begin

         // Handle 0 to 9
         if( (S[ iStr] >= '0') and (S[ iStr] <= '9')) then begin
            inc( iOctet);
            if( iOctet > 3) then begin
               raise IPConversionException.Create(
                 S + ': Each octet in an IP address must be 1 to 3 characters long!');
            end;
            Octet[ iOctet]:= S[ iStr];
            if( iStr = StrLength) then begin
               Found:= true;
            end;

         // Handle the dot between octets.
         end else if( S[ iStr] = '.' ) then begin
            Found:= true;
         // Any other character is an error!
         end else begin
            raise IPConversionException.Create(
              S + ': An IP address can only contain ''0''-''9'' and ''.''!');
         end; // else S[ iStr] <> '.'

         // Have we found an octet?
         if( Found) then begin

            // Make sure we got 1 to 3 characters
            if( iOctet < 1) then begin
               raise IPConversionException.Create(
                 S + ': Each octet in an IP address must be 1 to 3 characters long!');
            end;

            // Make sure we haven't gotten too many octets
            if( iByte < 0) then begin
               raise IPConversionException.Create(
                  S + ': An IP address must contain 4 octets!');
            end;

            SetLength( Octet, iOctet);
            // Convert the Octet to a byte
            val( Octet, ByteValue, Code);
            if( (Code > 0) or (ByteValue > 255)) then begin
               raise IPConversionException.Create(
                 S + ': Each octet in an IP address must be between 0 and 255!');
            end;

            Temp.ByteValue[ iByte]:= word8( ByteValue);

            Found:= false;
            dec( iByte);
            iOctet:= 0;
         end; // if we found an octet

      end; // for each character in S

      if( iByte >= 0) then begin
         raise IPConversionException.Create(
            S + ': An IP address must contain 4 octets!');
      end;

      IPStringToWord32:= Temp.Word32Value;
   end; // IPStringToWord32()


// *************************************************************************
// * NetmaskToPrefix() - Converts a 32 bit word representation of a
// *                     netmask to an 8 bit word prefix value.
// *************************************************************************

function NetmaskToPrefix( Netmask: Word32): Word8;
   var
      i: integer;
   begin
      i:= 32;
      while( (i >= 0) and (Slash[ i] <> NetMask)) do dec( i);
      if( i < 0) then begin
         raise IPConversionException.Create( 'NetmaskToPrefix(): ' + IPWord32ToString( Netmask) + ' is not a valid IP netmask!');
      end;
      result:= byte( i);
   end; // IPMaskToSlash()


// *************************************************************************
// * PrefixToNetmask() - Converts an 8 bit word prefix value to a 32 bit
// *                     word representation of a netmask.
// *************************************************************************

function PrefixToNetmask( Prefix: Word8): Word32;
   var
      Netmask: Word32 = Word32( not 0);
      Temp:    Word8;
   begin
      if( Prefix > 32) then begin
         raise IPConversionException.Create( 'PrefixToNetmask():  A prefix value greater than 32 was passed!');
      end;
      Temp:= 32 - Prefix;
      if( Prefix = 0) then result:= 0
      else if( Temp > 0) then result:= Netmask SHL Temp
      else result:= Netmask;
   end; // PrefixToNetmask()


// ************************************************************************
// Reverse the order of elements in a '.' separated string
// ************************************************************************

function ReverseDottedOrder( const S: string; const Dot: char = '.'): string;
   var
      i:    integer;
      Temp: string;
   begin
      Temp:= S;
      i:= pos( '.', Temp);
      if( i > 0) then begin
         result:= copy( Temp, 1, i - 1);
         Temp:= copy( Temp, i + 1, Length( Temp) - i);
         repeat
            i:= pos( Dot, Temp);
            result:= copy( Temp, 1, i - 1) + Dot + result;
            Temp:= copy( Temp, i + 1, Length( Temp) - i);
         until( i = 0);
         result:= Temp + result;
      end else begin
         result:= S;
      end;
   end; // ReverseDottedOrder()


// *************************************************************************
// * MACStringToWord64() - Convert the String representation of a MAC
// *                       address to a 64 bit word.
// *************************************************************************

function MACStringToWord64( const S: String): word64;
   var
      Code: word;
      Temp: string;
   begin
      Temp:= '$' + RemoveNonHexCharacters( S);
      val( Temp, result, code);
      if( Code > 0) then begin
         raise MACConversionException.Create(
            S + ' is an invalid NIC address.');
      end;
   end; // MACStringToWord32()


// *************************************************************************
// * MACWord64ToString() - Convert the 64 bit word representation of a MAC
// *                       address to a String.
// *************************************************************************

function MACWord64ToString( const X:     word64;
                                  C:     char = ':';
                                  Count: int32 = 4): string;
   begin
      result:=
         InsertSeparators( HexStr( int64( X), MACSize), C, Count);
   end; // MACWord64ToString()


// *************************************************************************
// * InsertSeparators() - Inserts a separator character (C) between each
// *                      Count characters of the MAC (S).
// *************************************************************************

function InsertSeparators( S:     string;
                           C:     char = ':';
                           Count: int32 = 4): string;
   var
      Temp:  string;
      i:     integer;
      Len:   integer;
   begin
      Len:= length( S);
      if ( Len < Count) then begin
         exit( S);
      end;

      // Copy the first portion in.
      Temp:= copy( S, 1, Count);

      // Now copy each remaining group preceeded by the separator character
      i:= Count + 1;
      while( i <= Len) do begin
         Temp:= Temp + C + copy( S, i, Count);
         i:= i + Count;
      end; // while

      InsertSeparators:= Temp;
   end; // InsertSeparators()


// ******************************************************************
// * RemoveNonHexCharacters() - Strip non-hex characters from a hex
// *                            representation of a number.
// ******************************************************************

function RemoveNonHexCharacters( const S: String): String;
   var
      B:     String;
      i:     integer;
      Len:   integer;
      TempS: String;
      TempC: char;
   begin
      B:= '';
      TempS:= Lowercase( S);
      Len:= Length( TempS);

      // For each character in the input string
      for i:= 1 to Len do begin
         TempC:= TempS[ i];

         // Is it a valid character?
         if( ((TempC >= '0') and (tempC <= '9')) or
             ((TempC >= 'a') and (tempC <= 'f'))) then begin

            // Yes, so copy it to B
            B:= B + TempC;

         end; // if valid characters
      end; // For each character in the input string

      RemoveNonHexCharacters:= B;

   end; // RemoveNonHexCharacters()


// ************************************************************************

end. // lbp_ip_utils unit
