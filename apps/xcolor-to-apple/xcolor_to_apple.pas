{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

convert UNIX X Windows color values to Apple's OS X color format.

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

program xcolor_to_apple;

{$include lbp_standard_modes.inc}

uses
   lbp_types;

var
   FileName: string = '/etc/rgb.txt';
   Red:      word32;
   Green:    word32;
   Blue:     word32;


// ************************************************************************
// * Usage() - Print a usage message and exit the program.
// ************************************************************************

procedure Usage( ErrorMsg: string = '');
   begin
      writeln();
      writeln();
      if( Length( ErrorMsg) > 0) then begin
         writeln( ErrorMsg);
         writeln();
      end;
      writeln( 'xcolor_to_apple takes the X Windows representation of a');
      writeln( 'screen color and converts it to the Apple OS X representation');
      writeln();
      writeln( '   Usage:  xcolor_to_apple <X Windows color value>');
      writeln();
      writeln('      Where ''X Windows color value'' is a six digit hex number');
      writeln('      proceeded by a ''#'' or it is a color name as defined in');
      writeln('      the X windows rgb.txt file.');
      writeln();
      writeln();

      halt(255);
   end; // Usage();


// ************************************************************************
// * HexStrToWord32() - Converts the passed hexidecimal string to a number
// ************************************************************************

function HexStrToWord32( H: string): word32;
   var
      Digit: char;
      i:     integer;
   begin
      result:= 0;
      for i:= 1 to length( H) do begin
         result:= result * 16;
         Digit:= H[ i];
         
         if( (Digit >= '0') and (Digit <= '9')) then begin
            result:= result + word32(ord( Digit) - ord( '0'));
         end else if( (Digit >= 'a') and (Digit <= 'f')) then begin
            result:= result + word32(ord( Digit) - ord( 'a') + 10);
         end else if( (Digit >= 'A') and (Digit <= 'F')) then begin
            result:= result + word32(ord( Digit) - ord( 'A') + 10);
         end else begin
            usage( 'Error!  Invalid character in the Unix hex representation');
         end; 
      end; // for
   end; // HexStrToWord32
   
   
// ************************************************************************
// * ParseHexColor() - Sets Red, Green, Blue from the passed X Windows
// *                   color definition.
// ************************************************************************

procedure ParseHexColor( XWinHex: string);
   begin
      if( Length( XWinHex) <> 7) then begin
         Usage( 'Error!  Unix hex representation must be 6 characters long!');
      end;

      Red:=   HexStrToWord32( copy( XWinHex, 2, 2));
      Green:= HexStrToWord32( copy( XWinHex, 4, 2));
      Blue:=  HexStrToWord32( copy( XWinHex, 6, 2));
   end; // ParseHexColor


// ************************************************************************
// * SkipLeadingSpaces() - increments 'i' to point to the first non white
// *                       space character in S.
// ************************************************************************

procedure SkipLeadingSpaces( S: string; var i: integer);
   var
      C:       char;
      Found:   boolean;
   begin
      // Make sure 'i' is a valid index.
      if( (i <= 0) or (i > Length( S))) then begin
         exit;
      end;

      // Find the beginning of the word
      Found:= false;
      while( (not Found) and (i <= length( S))) do begin
         c:= S[ i];
         if( (C = ' ') or (C = chr( 9))) then begin
            inc( i);
         end else begin
            Found:= true;
         end; // if
      end; // for
   end; // SkipLeadingSpaces


// ************************************************************************
// * GetWord() - Given a string and the current index into it, returns a
// *             word.
// ************************************************************************

function GetWord( S: string; var i: integer): string;
   var
      iStart:  integer;
      C:       char;
      Found:   boolean;
   begin
      // Make sure 'i' is a valid index.
      if( (i <= 0) or (i > Length( S))) then begin
         result:= '';
         exit;
      end;

      SkipLeadingSpaces( S, i);
      iStart:= i;
      
      // Find the end of the word
      Found:= false;
      while( (not found) and (i <= length( S))) do begin
         c:= S[ i];
         if( (C = ' ') or (C = chr( 9))) then begin
            Found:= true;
         end else begin
            inc( i);
         end; // if
      end; // for
      
      result:= copy( S, iStart, i - iStart);
   end; // GetWord()
   

// ************************************************************************
// * LookupInRGBtxt() - Looks up the named color in rgb.txt
// ************************************************************************

procedure LookupInRGBtxt( ColorName: string);
   var
      F:     text;
      Found: boolean;
      Line:  string;
      i:     integer;
      R:     string;
      G:     string;
      B:     string;
      N:     string;
      code:  integer;
   begin
      assign( F, FileName);
      reset( F);
      Found:= false;
      
      while( (not found) and (not eof( F))) do begin
         readln( F, Line);
         i:= 1;
         R:= GetWord( Line, i);
         G:= GetWord( Line, i);
         B:= GetWord( Line, i);
         SkipLeadingSpaces( Line, i);
         N:= copy( Line, i, Length( Line) - i + 1);
         Found:= (ColorName = N);
      end;
      
      if( Found) then begin
         Val( R, Red, Code);
         Val( G, Green, Code);
         Val( B, Blue, Code);
      end else begin
         Usage( 'Error!  Invalid Unix color name.');
      end;
   end; // LookupInRGBtxt();
   

// ************************************************************************
// * main()
// ************************************************************************

begin
   if( ParamCount <> 1) then begin
      Usage('Error!  Wrong number of command line parameters');
   end;

   if( ParamStr( 1)[ 1] = '#') then begin
      ParseHexColor( ParamStr( 1));
   end else begin
      LookupInRGBtxt( ParamStr( 1));
   end;
   writeln( Red + Red * 256, ', ', Green + Green * 256, ', ', 
            Blue + Blue * 256);
end.  // xcolor_to_apple program
