{* ***************************************************************************

Copyright (c) 2021 by Lloyd B. Park

Takes a single two digit hexidecimal value and outputs the associated ANSI 
caracter.  I wrote this very simple program because I needed to remove some
spurious RS ASCII control caracters from some CSV files. I used this bash 
command line to strip out the RS characters:
   cat my-data.csv | tr -d `hex_to_chr 1e`

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

program hex_to_chr;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   strutils;

type 
   tCharSet = set of char;


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'Takes a single two digit hexidecimal value and outputs the associated ANSI');
      InsertUsage( 'caracter.  I wrote this very simple program because I needed to remove some');
      InsertUsage( 'spurious RS ASCII control caracters from some CSV files. I used this bash');
      InsertUsage( 'command line to strip out the RS characters:');
      InsertUsage();
      InsertUsage( '     cat my-data.csv | tr -d `hex_to_chr 1e`');
      InsertUsage();
      ParseParams();
   end; // InitArgvParser();


// ************************************************************************
// * main()
// ************************************************************************

var
   HexChrs: tCharSet = ['a'..'f', 'A'..'F', '0'..'9'];
   S: string;
   i: integer;
begin
   // Parse the parameters and check for errors
   InitArgvParser();
   if( Length( UnnamedParams) <> 1) then Usage( True, 'You must enter the hex representation of the ASCII character to be output!');
   S:= UnnamedParams[ 0];
   if( Length( S) <> 2) then Usage( True, 'The hexidecimal value must be two characters long!' + LineEnding + 'LinUse a leading zero if needed.');
   for i:= 1 to 2 do begin
      if( not (S[ i]in HexChrs)) then Usage( True, 'The passed parameter must be exactly two hexidecimal characters!');
   end;

   write( chr( Hex2Dec( S)));
end.  // hex_to_chr program
