{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

format and display hex dumps

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

unit lbp_hexdump;

// Simple debug unit used to format and display hex dumps

interface

{$include lbp_standard_modes.inc}


uses
   strutils;


// *************************************************************************

function  HexDumpStr( const Data; Size: integer): string;
procedure HexDump(    const Data; Size: integer);


// *************************************************************************

type
   tHexDump = class
      private
//         LineNumber:     integer;
         NumberOfLines:  integer;
         LineLength:     integer;
         LineHexOffset:  integer;  // from beginning of line
         LineCharOffset: integer;  // from beginning of line
         HexOffset:      integer;  // from beginning of HexStr;
         CharOffset:     integer;  // from beginning of HexStr;
         Count16:        integer;  // 0 to 15 counter;
         HexStr:         string;
      public
         Indent:         integer;
         Counter:        integer;
         AddCharDump:    boolean;
         HexCounter:     boolean;
         constructor     Create();
         function        ToHex( const Data; Size: integer): string;
         procedure       Dump( const Data; Size: integer);
      private
         procedure       InitString( Size: integer);
         procedure       ByteToHex( B: integer; HexStrIndex: integer);
  end; // tHexDump class


// *************************************************************************

var
   NewLine:   string;
   HexDumper: tHexDump;

// *************************************************************************


implementation

// =========================================================================
// = Global functions
// =========================================================================
// *************************************************************************
// * NibbleToHex() - returns the Hex value of a nibble (half byte)
// *************************************************************************
function NibbleToHex( N: integer): char;
   begin
      if( N > 9) then begin
         result:= char( N - 10 + ord( 'a'));
      end else begin
         result:= char( N + ord( '0'));
      end;
   end; // NibbleToHex()


// *************************************************************************
// * HexDumpStr() - Returns a hex string representation of the data
// *************************************************************************

function HexDumpStr( const Data; Size: integer): string;
   var
      Sz:        integer;  // Size of new string;
      S:         string;
      DataIndex: integer;
      StrIndex:  integer;
      B:         ^byte;
   begin
      B:= @(byte(Data));
      if( Size <= 0) then begin
         result:= '';
         exit;
      end;

      Sz:= Size - 1;
      SetLength( S, (Size * 3) - 1);

      StrIndex:= 1;
      for DataIndex:= 0 to Sz do begin
         if( StrIndex <> 1) then begin
            S[ StrIndex]:= ' ';
            inc( StrIndex);
         end;
         S[ StrIndex]:= NibbleToHex( (B[ DataIndex] shr 4) and $0f);
         inc( StrIndex);
         S[ StrIndex]:= NibbleToHex( B[ DataIndex] and $0f);
         inc( StrIndex);
      end; // for DataIndex

      result:= S;
   end; // HexDumpStr()


// *************************************************************************
// * HexDump() - prints the hex string representation of the data
// *************************************************************************

procedure HexDump( const Data; Size: integer);
   begin
      writeln( HexDumpStr( Data, Size));
   end; // HexDump()


// =========================================================================
// = tHexDump
// =========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor  tHexDump.Create();
   begin
      // Minimal dump by default
      Counter:=     -1;  // No counter
      Indent:=      0;
      AddCharDump:= false;
      HexCounter:=  false;
      HexStr:=      '';
   end; // Create()


// *************************************************************************
// * ToHex() - Convert a byte to hex
// *************************************************************************

function  tHexDump.ToHex( const Data; Size: integer): string;
   var
      StartOfLine: integer;
      DataIndex:   integer;
      B:           ^byte;
      Temp:        byte;
      C:           char;
      LineNumber:  integer;
   begin
      InitString( Size);
      result:= HexStr;
      B:= @(byte(Data));
      StartOfLine:= 1;
      DataIndex:= 0;
      for LineNumber:= 0 to NumberOfLines do begin
         StartOfLine:= 1 + (LineNumber * LineLength);
         HexOffset:= LineHexOffset + StartOfLine;
         CharOffset:= LineCharOffset + StartOfLine;
         while Count16 < 16 do begin
            Temp:= B[ DataIndex];
            ByteToHex( Temp, HexOffset + (Count16 * 3));
            if( AddCharDump) then begin
               if( (Temp <= 32) or (Temp >= 128)) then begin
                  c:= '.';
               end else begin
                  c:= chr( Temp);
               end;
               HexStr[ CharOffset + Count16]:= c;
            end; // if AddCharDump
            inc( Count16);
            inc( DataIndex);
            if( DataIndex >= Size) then begin
               result:= HexStr;
               exit;
            end;
         end; // while
         Count16:= 0;
      end;
   end; // ToHex()


// *************************************************************************
// * Dump() - Output the dump to stdout
// *************************************************************************

procedure  tHexDump.Dump( const Data; Size: integer);
   begin
      writeln( ToHex( Data, Size));
   end; // Dump()


// *************************************************************************
// * InitString - Initialize the HexStr with spaces and line feeds.
// *              Allso sets LineLength, etc.
// *************************************************************************

procedure  tHexDump.InitString( Size: integer);
   var
      TempSize:      integer;
      NLLen:         integer;
      i:             integer;
      j:             integer;
      c:             integer;
      cStr:          string;
      Base:          integer;
   begin
      NLLen:= Length( NewLine);
      if( Counter < 0) then begin
         LineHexOffset:= Indent;
         Count16:= 0;
      end else begin
         LineHexOffset:= 9 + Indent;
         Count16:= Counter mod 16;
      end;

      if( AddCharDump) then begin
         LineCharOffset:= LineHexOffset + 50;
      end else begin
         LineCharOffset:= 0;
      end;

      TempSize:= Size + Count16;
      NumberOfLines:= (TempSize div 16) + 1;
      LineLength:= LineHexOffset + 47 + NLLen;
      if( AddCharDump) then inc( LineLength, 19);

      TempSize:= NumberOfLines * LineLength - NLLen;
      SetLength(HexStr, TempSize);

      FillChar( HexStr[ 1], TempSize, ' ');

      // Add NewLines
      i:= LineLength - NLLen + 1;
      while( i < TempSize) do begin
         for j:= 1 to NLLen do begin
            HexStr[ i + j - 1]:= NewLine[ j];
         end;
         inc( i, LineLength);
      end;
      // Add counter
      if( Counter >= 0) then begin
         c:= (Counter div 16) * 16;
         if( HexCounter) then Base:= 16 else Base:= 10;
         i:= Indent + 1;
         while( i < TempSize) do begin
            cStr:= Dec2Numb( c, 6, Base);
            inc( c, 16);
            for j:= 0 to 5 do begin
               HexStr[ i + j]:= cStr[ j + 1];
            end;
            HexStr[ i + 6]:= ':';
            inc( i, LineLength);
         end; // while
      end;

      if( Counter >= 0) then inc( Counter, Size);
   end; // InitString()


// *************************************************************************
// * ByteToHex()
// *************************************************************************

procedure tHexDump.ByteToHex( B: integer; HexStrIndex: integer);
   begin
      HexStr[ HexStrIndex]:= NibbleToHex( (B shr 4) and $0f);
      inc( HexStrIndex);
      HexStr[ HexStrIndex]:= NibbleToHex( B and $0f);
   end; // ByteToHex()


// ========================================================================
// * Unit initialization and finalization.
// ========================================================================

initialization
   begin
      case DefaultTextLineBreakStyle of
         tlbsCR:   NewLine:= char( 13);
         tlbsCRLF: NewLine:= char( 13) + char( 10);
         tlbsLF:   NewLine:= char( 10);
      end; // case

      HexDumper:= tHexDump.Create();
   end;


// ************************************************************************

finalization
   begin
      HexDumper.Destroy;
   end;


// *************************************************************************

end.  // lbp_hexdump unit
