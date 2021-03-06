{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

utility routines that don't fit elsewhere

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

unit lbp_utils;


interface

{$include lbp_standard_modes.inc}
{$modeswitch typehelpers}

uses
   lbp_Types;


// ************************************************************************

type
   tLbpStringHelper = type helper for string
      function StartsWith( SubString: string): boolean;
      function EndsWith( SubString: string): boolean;
      function Contains( SubString: string): boolean;
   end; // tLbpStringHelper
  

// ************************************************************************

procedure StripSpaces( Var S: string);
procedure PadLeft(  var S: string; SLen:   integer);
procedure PadRight( var S: string; SLen:   integer);
function  HexStr( X: word64; Count: byte): string;


// General purpose bit setting and clearing routines.
procedure SetBit( var BitSet: int32; BitNumber: integer);
procedure ClearBit( var BitSet: int32; BitNumber: integer);

var
   HexTable: array[ 0..15] of char = '0123456789abcdef';

// ************************************************************************

const
   Tab = char( 9);

// ************************************************************************

implementation

// ========================================================================
// = Global functions
// ========================================================================
// ************************************************************************
// * SetBit() Set the BitNumber bit of BitSet.
// ************************************************************************

procedure SetBit( var BitSet: int32; BitNumber: integer);
   begin
      if( (BitNumber >= 1) and (BitNumber <= 32)) then begin
         Dec( BitNumber);
         BitSet:= BitSet or (1 shl BitNumber); // Bitwise shift
      end;
   end;


// ************************************************************************
// * ClearBit() Clears the BitNumber bit of BitSet.
// ************************************************************************

procedure ClearBit( var BitSet: int32; BitNumber: integer);
   begin
      if( (BitNumber >= 1) and (BitNumber <= 32)) then begin
         Dec( BitNumber);
         BitSet:= BitSet and (not (1 shl BitNumber)); // Bitwise shift
      end;
   end;


// ************************************************************************
// * StripSpaces() - Strips leading and trailing spaces from a string
// ************************************************************************

procedure StripSpaces( Var S: string);
   var
      Start:  integer;  // The first non space character
      Finish: integer;  // The last non space character
   begin

      // find the first non space char
      Start:= 1;
      while (Start <= length( S)) and ((S[ Start] = ' ') or
                                       (S[ Start] = Tab)) do begin
         inc( Start);
      end;

      // if there are nothing but spaces then return an empty string
      if Start > length( S) then begin
         S:= '';
         Exit;
      end;

      // Find the last non space char
      Finish:= length( S);
      while( Finish > 1) and ((S[ Finish] = ' ') or
                              (S[ Finish] = Tab)) do begin
         dec( Finish);
      end;

      // Return the string
      S:= copy( S, Start, succ( Finish) - Start);
   end; // StripSpaces


// ************************************************************************
// * PadRight() - Pad a string with spaces on the right
// ************************************************************************

procedure PadRight( var S: string; SLen: integer);
   begin
      if( Length( S) < SLen) then begin
         S:= S + Space( SLen - Length( S));
      end;
   end; // PadRight


// ************************************************************************
// * PadLeft() - Pad a string with spaces on the left
// ************************************************************************

procedure PadLeft(  var S: string; SLen: integer);
   begin
      if( Length( S) < SLen) then begin
         S:= Space( SLen - Length( S)) + S;
      end;
   end;  // PadLeft


// ************************************************************************
// * HexStr() - Convert a word64 to a hex string
// ************************************************************************

function HexStr( X: word64; Count: byte): string;
   var
      i : longint;
   begin
      setlength( result, Count);

      for i:= Count downto 1 do begin
         result[ i]:= HexTable[ X and $f];
         X:= X shr 4;
      end;
   end; // HexStr()


// ========================================================================
// = tLbpStringHelper
// ========================================================================
// ************************************************************************
// * StartsWith() - Returns true if Source starts with SubString
// ************************************************************************

function tLbpStringHelper.StartsWith( SubString: string): boolean;
   var
     i:           integer;
     LSubString:  integer;
     LSelf:       integer;
   begin
      result:= false;
      LSubString:= Length( SubString);
      LSelf:=      Length( Self);

      if( LSubString = 0) then begin
         result:= true;
         exit;
      end;
      if( LSelf < LSubString) then exit;

      for i:= 1 to LSubString do begin
         result:= (Self[ i] = Substring[ i]);
         if( not result) then exit; // exit loop
      end;
   end; // StartsWtih()


// ************************************************************************
// * EndsWith() - Returns true if Source ends with SubString
// ************************************************************************

function tLbpStringHelper.EndsWith( SubString: string): boolean;
   var
     iSubString:  integer;
     iSelf:       integer;
     LSubString:  integer;
     LSelf:       integer;
   begin
      result:= false;
      LSubString:= Length( SubString);
      LSelf:=    Length( Self);

      if( LSubString = 0) then begin
         result:= true;
         exit;
      end;
      if( LSelf < LSubString) then exit;
      
      iSelf:= LSelf;
      for iSubString:= LSubString downto 1 do begin
         result:= (Self[ iSelf] = Substring[ iSubString]);
        if( not result) then exit; // exit loop
         dec(iSelf);
      end;
   end; // EndsWith()


// ************************************************************************
// * Contains() - Returns true if Source contains SubString
// ************************************************************************

function tLbpStringHelper.Contains( SubString: string): boolean;
   var
     P:           SizeInt;
   begin
      if( Length( SubString) = 0) then begin
          result:= true;
         exit;
      end;
       
      P:= Pos( SubString, Self);
      result:= (P > 0);
   end; // Contains()


// ************************************************************************

end. // lbp_utils unit
