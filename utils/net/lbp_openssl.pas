{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Interfaces with the openssl library functions and structures.  

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

// This unit is most likely superceded by Free Pascal's built in libraries.

unit openssl;
// This unit defines openssl library functions and structures.
//  See man sha
//      man md5

interface

{$LINKLIB crypto}       // OpenSSL
{$include kent_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   kent_types,
   unix,
//   oldlinux,     // linux file IO commands
   SysUtils;  // Exceptions


// *************************************************************************
// * SHA1 digest
// *************************************************************************

const
   SHA_LBLOCK = 16;
   SHA_DIGEST_LENGTH = 20;
type
   SHA_LONG = word32;

   tSHAResult = array[ 0..SHA_DIGEST_LENGTH - 1] of word8;
   pSHAResult = ^tSHAResult;

   SHA_CTX = record
         h0,h1,h2,h3,h4: SHA_LONG;
         Nl,Nh:          SHA_LONG;
         data:           array[ 0..SHA_LBLOCK - 1] of SHA_LONG;
         num:            int32;
      end; // SHA_CTX

function SHA1( var InputData;
                   InputLength: int32;
               var SHAResult:   tSHAResult): pSHAResult; cdecl; external;
procedure SHA1_Init(   var CTX:       SHA_CTX); cdecl; external;
procedure SHA1_Update( var CTX:       SHA_CTX;
                       var InputData;
                       InputLength:   int32); cdecl; external;
procedure SHA1_Final(  var SHAResult: tSHAResult;
                       var CTX:       SHA_CTX); cdecl; external;

procedure SHA1( InputData: string; var SHAResult: tSHAResult);
procedure SHA1ofFile( FileName: string; var SHAResult: tSHAResult);
// Allow us to compare two digests for equality.
operator = ( var Digest1, Digest2: tSHAResult): boolean;


// *************************************************************************
// * MD5 digest
// *************************************************************************

const
   MD5_LBLOCK = 16;
   MD5_DIGEST_LENGTH = 16;
type
   MD5_LONG = word32;

   tMD5Result = array[ 0..MD5_DIGEST_LENGTH - 1] of word8;
   pMD5Result = ^tMD5Result;

   MD5_CTX = record
         A, B, C, D:  MD5_LONG;
         Nl, Nh:      MD5_LONG;
         data:        array[ 0..MD5_LBLOCK - 1] of MD5_LONG;
         num:         int32;
      end; // MD5_CTX

function MD5( var InputData;
                   InputLength: int32;
               var MD5Result:   tMD5Result): pMD5Result; cdecl; external;
procedure MD5_Init(    var CTX:       MD5_CTX); cdecl; external;
procedure MD5_Update( var CTX:       MD5_CTX;
                       var InputData;
                       InputLength:   int32); cdecl; external;
procedure MD5_Final( var MD5Result:   tMD5Result;
                     var CTX:       MD5_CTX); cdecl; external;

procedure MD5( InputData: string; var MD5Result: tMD5Result);
procedure MD5ofFile( FileName: string; var MD5Result: tMD5Result);
// Allow us to compare two digests for equality.
operator = ( var Digest1, Digest2: tMD5Result): boolean;


// *************************************************************************

function DigestToHex( var Digest: array of word8): string;
procedure HexToDigest( HexString: string; var Digest: array of word8);

// *************************************************************************

implementation


// *************************************************************************
// * SHA1() - Return an SHA1 digest of the passed string
// *************************************************************************

procedure SHA1( InputData: string; var SHAResult: tSHAResult);
   begin
      SHA1( InputData[ 1], Length( InputData), ShaResult);
   end;  // SHA1()


// *************************************************************************
// * SHA1ofFile() - Produce a SHA1 digest of the file at FileName.
// *************************************************************************

procedure SHA1ofFile( FileName: string; var SHAResult: tSHAResult);
   var
      Block:     array[ 1..2048] of word8;
      FromFile:  file;
      BytesRead: word32;
      CTX:       SHA_CTX;
   begin
      SHA1_Init( CTX);

      assign( FromFile, FileName);
      reset( FromFile);
      Repeat
         BlockRead( FromFile, Block, SizeOf( Block), BytesRead);
         if( BytesRead > 0) then begin
            SHA1_Update( CTX, Block, BytesRead);
         end;
      until( BytesRead <= 0);
      SHA1_Final( SHAResult, CTX);
      Close( FromFile);
   end; // SHA1ofFile



// *************************************************************************
// * =  - Compare two tSHAResult digests for equality.
// *************************************************************************

operator = ( var Digest1, Digest2: tSHAResult): boolean;
   var
      Top: integer;
      i:   integer;
   begin
      Top:= High( Digest1);
      for i:= 0 to Top do begin
         if( Digest1[ i] <> Digest2[ i]) then exit( false);
      end;

      result:= true;
   end; // =


// *************************************************************************
// * MD51() - Return an MD51 digest of the passed string
// *************************************************************************

procedure MD5( InputData: string; var MD5Result: tMD5Result);
   begin
      MD5( InputData[ 1], Length( InputData), MD5Result);
   end;  // MD51()


// *************************************************************************
// * MD5ofFile() - Produce a MD5 digest of the file at FileName.
// *************************************************************************

procedure MD5ofFile( FileName: string; var MD5Result: tMD5Result);
   var
      CTX:       MD5_CTX;
      BytesRead: word32;
      Block:     array[ 1..2048] of word8;
      FromFile:  File;
   begin
      MD5_Init( CTX);

      assign( FromFile, FileName);
      reset( FromFile);
      Repeat
         BlockRead( FromFile, Block, SizeOf( Block), BytesRead);
         if( BytesRead > 0) then begin
            MD5_Update( CTX, Block, BytesRead);
         end;
      until( BytesRead <= 0);
      MD5_Final( MD5Result, CTX);
      Close( FromFile);
   end; // MD5ofFile



// *************************************************************************
// * =  - Compare two tMD5Result digests for equality.
// *************************************************************************

operator = ( var Digest1, Digest2: tMD5Result): boolean;
   var
      Top: integer;
      i:   integer;
   begin
      Top:= High( Digest1);
      for i:= 0 to Top do begin
         if( Digest1[ i] <> Digest2[ i]) then exit( false);
      end;

      result:= true;
   end; // =


// *************************************************************************
// * DigestToHex() - Convert a digest (byte array) to a hex string.
// *************************************************************************

function DigestToHex( var Digest: array of word8): string;
   var
     DigestTop: int32;
     i:         int32;
     Temp:      byte;
     HexValue:  string;
     HexIndex:  int32;
   begin
      DigestTop:= High( Digest);
      HexValue:= StringOfChar( '.', 2 * (DigestTop + 1));

      HexIndex:= 1;
      for i:= 0 to DigestTop do begin

         // Handle the upper nibble
         Temp:= byte( Digest[ i] SHR 4);
         if( Temp > 9) then begin
            HexValue[ HexIndex]:= Chr( Temp + ord( 'a') - 10);
         end else begin
            HexValue[ HexIndex]:= Chr( Temp + ord( '0'));
         end;
         inc( HexIndex);

         // Handle the lower nibble
         Temp:= Digest[ i] and 15;
         if( Temp > 9) then begin
            HexValue[ HexIndex]:= Chr( Temp + ord( 'a') - 10);
         end else begin
            HexValue[ HexIndex]:= Chr( Temp + ord( '0'));
         end;
         inc( HexIndex);
      end;
      DigestToHex:= HexValue;
   end; // DigestToHex


// *************************************************************************
// * HexToDigest() - Convert a string of hex numbers to a digest
// *************************************************************************

procedure HexToDigest( HexString: string; var Digest: array of word8);
   var
      DigestTop:   int32;
      L:           int32;
      i:           int32;
      TempStr:     string;
      DigestIndex: int32;
      Code:        int32;
      Temp:        int32;
   begin
      L:= length( HexString);
      DigestTop:= High( Digest);

      if( L  <> (DigestTop + 1) * 2) then begin
         raise Exception.Create(
            'openssl.HexToDigest(): String and Digest length mismatch!');
      end;

      i:= 1;
      for DigestIndex:= 0 to DigestTop do begin
         TempStr:= '$' + Copy( HexString, i, 2);
         i:= i + 2;
         Temp:= Digest[ DigestIndex];
         Val( TempStr, Temp, Code);
         if( (Code > 0) or (Temp < 0)) then begin
            raise Exception.Create(
            'openssl.HexToDigest(): The string contains non-hex characters!');
         end;
         Digest[ DigestIndex]:= byte( Temp);
      end;
   end; // HexToDigest();


// *************************************************************************

end.

