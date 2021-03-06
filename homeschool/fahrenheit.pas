{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Celcius to Fahrenheit converter for educational purposes

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


program fahrenheit;

// ************************************************************************
// * CtoF() - Converts Celcius to Fahrenheit
// ************************************************************************

function CtoF( C: double): double;
   begin
      result:= (C * 9 / 5)  + 32 ;
   end; // CtoF() 


// ************************************************************************
// *  main()
// ************************************************************************

var
//   F: double;
   X: double;
begin

   write( 'Enter the temperature in Celcius:  ');
   readln( X);

   writeln( 'The temperature in Celcius is:     ', X:4:1);

//   F:= (C * 9 / 5)  + 32 ;

   writeln( 'The temperature in Fahrenheit is:  ', CtoF( X):4:1);
end. // program fahrenheit
