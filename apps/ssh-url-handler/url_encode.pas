{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

A utility program to url_encode a string

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or 
    (at your option) any later version.


    This program is distributed in the hope that it will be useful,but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU Lesser General Public 
    License along with this program.  If not, see 
    <http://www.gnu.org/licenses/>.

*************************************************************************** *}

program url_encode;

{$include kent_standard_modes.inc}
{$LONGSTRINGS ON}
{$R-}

uses
   kent_types,
   sysutils;

// ************************************************************************
// * URIDecode
// ************************************************************************

function URIDecode( InputURI : String) : string;
   const
      NoConvert = ['A'..'Z','a'..'z','*','@','.',
                   '_','-','0'..'9','$','!','''','(',')'];
      Numbers    = ['0'..'9'];
      UpperAlpha = ['A'..'Z'];
      LowerAlpha = ['a'..'z'];
   var
      EscSeq:   integer;
      i:        integer;
      C:        char;
      S:        string;
      Len:      integer;
      HexValue: integer;
   begin
      Len:= Length( InputURI);
      SetLength( S, Len);

      EscSeq:= 0;
      HexValue:= 0;
      for i:= 1 to Len do begin
         C:= InputURI[ i];

         // Are we in an escape sequence?
         if( EscSeq > 0) then begin
            HexValue:= HexValue shl 4;
            if( C in Numbers) then begin
               HexValue:= HexValue + ord( C) - ord( '0');
            end else if( C in UpperAlpha) then begin
               HexValue:= HexValue + ord( C) - ord( 'A') + 10;
            end else if( C in Loweralpha) then begin
               HexValue:= HexValue + ord( C) - ord( 'a') + 10;
            end else begin
               // We should never get here unless someone is trying to feed
               // us illegal values.
               raise KentException.Create( 
                        'Invalid data in the passed URI (''%S'') at index %D, ' +
                        'character ''%S''.', [InputURI, i, C]);
            end;
 
             // Prepare for the next character
             if( EscSeq = 2) then begin
                EscSeq:= 0;
                S:= S + Char( HexValue);
                HexValue:= 0;
             end else begin
                inc( HexValue);
             end;
         end else begin
            // We are outside a %XX escape sequence
            if( C in NoConvert) then begin
               S:= S + C;
            end else if( C = '+') then begin
               S:= S + ' ';
            end else if( C = '%') then begin
               EscSeq:= 1;
               HexValue:= 0;
            end else begin
               // We should never get here unless someone is trying to feed
               // us illegal values.
               raise KentException.Create( 
                        'Invalid data in the passed URI (''%S'') at index %D, ' +
                        'character ''%S''.', [InputURI, i, C]);
            end;
         end; // else we are outside a %xx escape sequence
      end; // for each character of InputURI
      Result:= S;
   end; // URIDecode()
 

// ************************************************************************
// * URIEncode
// ************************************************************************

function URLEncode( const InputURI: String): string;
   const
      NoConvert = ['A'..'Z','a'..'z','*','@','.',
                   '_','-','0'..'9','$','!','''','(',')'];
      Hex2Str : array[0..15] of char = '0123456789ABCDEF';
   var
      i : integer;
      C : char;
      S : string;
   begin
      // allocate some space for the result
      SetLength( S, Length( InputURI));

      for i:= 1 to Length( InputURI) do begin
         C:= InputURI[i];
         if( C in NoConvert) then begin
            S:= S + C;
         end else if( C = ' ') then begin
            S:= S + '+'
         end else begin
            S:= S + '%' + hex2str[ ord( c) shr 4] + hex2str[ ord( c) and $f];
         end;
      end;
      result:= S;
   end; // URLEncode()                                                                          
                                                                          

// ************************************************************************
// * main()
// ************************************************************************

begin
   writeln( URLEncode( ParamStr(1)));
end. // program url_encode
