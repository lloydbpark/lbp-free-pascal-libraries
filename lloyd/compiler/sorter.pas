{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

A sort routine from an old CS class

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

program Sorter;

uses crt;

var
  data: array[ 0..9] of integer;
  i, j, k: integer;

begin
   clrscr;
   data[ 0]:= 479;
   data[ 1]:= 286;
   data[ 2]:= 578;
   data[ 3]:= 573;
   data[ 4]:= 643;
   data[ 5]:= 960;
   data[ 6]:= 527;
   data[ 7]:= 115;
   data[ 8]:= 750;
   data[ 9]:= 815;

   i:= 0;
   while i < 9 do begin
      j:= i + 1;
      while j <= 9 do begin
         if data[i] > data[j] then begin
            k:= data[i];
            data[i]:= data[j];
            data[j]:= k
         end;
         j:= j + 1
      end;
      i:= i + 1
   end;

   for i:= 0 to 9 do writeln( Data[ i]);

end.
