{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

primes - calculates the primes between 1 and 100,000

This is a simple example program using a generic double linked list. I wrote
it to show my young daughter a simple program and just how fast a modern
computer is.


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

program primes;

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_types,
   lbp_generic_containers;


type
   tIntegerList = specialize tgDoubleLinkedList< integer>;

var
   PrimeList: tIntegerList;
   i:    integer;
   iMax: integer;
   P:    integer;

// ************************************************************************
// * Divisible
// ************************************************************************

function Divisible( TestValue: integer): boolean;
   var
      Divisor: integer;
   begin
      for Divisor in PrimeList do begin
//         writeln( Divisor);
         if( (TestValue mod Divisor) = 0) then begin
            result:= true;
            exit;
         end; 
      end;
      result:= false;
   end; // Divisible()


// ************************************************************************
// * main()
// ************************************************************************

begin
   PrimeList:= tIntegerList.Create();
   i:= 3;
   iMax:= 100000;
   while( i < imax) do begin
      if( not Divisible( i)) then PrimeList.AddTail( i);
      inc( i, 2);
   end;

   PrimeList.AddHead( 2);
   PrimeList.AddHead( 1);
   for P in PrimeList do writeln( P);

   PrimeList.RemoveAll();
   PrimeList.Destroy();
end. // primes program
