{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Adds to numbers - for educational purposes

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

program addition;

// ************************************************************************
// *  main()
// ************************************************************************

var
   B: double;
   C: double;
   A: double;
begin

   write('Enter one number this number will be added to anther number latter: ');
   readln( B);

   write('Enter anther number to be added to the first: ');
   readln( C);

   A:= (C+B);

   writeln('Here is the answer', A:4:1);
end. // program additon
