{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

a simple way of figuring out how big a variable is

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

program SizeOfVars;

{$include lbp_standard_modes.inc}

uses
   baseunix,
   ctypes;
var
   TestSet: set of char;

begin

   writeln( '------- Some general tests ------');
   writeln( 'Size of byte       = ', SizeOf( byte));
   writeln( 'Size of shortint   = ', SizeOf( shortint));
   writeln( 'Size of smallint   = ', SizeOf( smallint));
   writeln( 'Size of integer    = ', SizeOf( integer), ' - Max = ', High( integer));
   writeln( 'Size of word       = ', SizeOf( word), ' - Max = ', High( word));
   writeln( 'Size of longint    = ', SizeOf( longint), ' - Max = ', High( longint));
   writeln( 'Size of cardinal   = ', SizeOf( cardinal), ' - Max = ', High( cardinal));
   writeln( 'Size of int64      = ', SizeOf( int64), ' - Max = ', High( int64));
   writeln( 'Size of qword      = ', SizeOf( qword), ' - Max = ', High( qword));
   writeln( 'Size of a set      = ', SizeOf( TestSet));
   writeln( 'Size of a real     = ', SizeOf( Real));
   writeln( 'Size of a double   = ', SizeOf( Double));
   writeln( 'Size of a pointer  = ', SizeOf( Pointer));
   writeln;
   writeln( '------ ctypes unit sizes ------');
   writeln( 'Size of cint8      = ', SizeOf( cint8));
   writeln( 'Size of cuint8     = ', SizeOf( cuint8));
   writeln( 'Size of cint16     = ', SizeOf( cint16));
   writeln( 'Size of cuint16    = ', SizeOf( cuint16));
   writeln( 'Size of cint32     = ', SizeOf( cint32));
   writeln( 'Size of cuint32    = ', SizeOf( cuint32));
   writeln( 'Size of cint64     = ', SizeOf( cint64));
   writeln( 'Size of cuint64    = ', SizeOf( cuint64));
   writeln( '------');
   writeln( 'Size of cchar      = ', SizeOf( cchar));
   writeln( 'Size of cuchar     = ', SizeOf( cuchar));
   writeln( 'Size of cshort     = ', SizeOf( cshort));
   writeln( 'Size of cushort    = ', SizeOf( cushort));
   writeln( 'Size of cint       = ', SizeOf( cint));
   writeln( 'Size of cuint      = ', SizeOf( cuint));
   writeln( 'Size of clong      = ', SizeOf( clong));
   writeln( 'Size of culong     = ', SizeOf( culong));
//   writeln( 'Size of clonglong  = ', SizeOf( clonglong));
//   writeln( 'Size of culonglong = ', SizeOf( culonglong));
   writeln;
//   writeln( '------ cron type ------');
//   writeln( 'Size of localtime_tm = ', SizeOf( localtime_tm));
//   writeln( 'Size of tFDSet       = ', SizeOf( tFDSet));
//   writeln( 'Size of tFDSet[0]    = ', SizeOf( tFDSet[0]));
//   writeln( 'Length of tFDSet     = ', Length( tFDSet));

   writeln;
//   writeln( 'SIGTERM = ', SIGTERM);
//   writeln( 'SIGHUP  = ', SIGHUP);
//   writeln( 'Size of a sigset_t        = ', SizeOf( sigset_t));
//   writeln( 'FD_MAXFDSET               = ', FD_MAXFDSET);
//   writeln( 'BITSINWORD                = ', BITSINWORD);
//   writeln( 'wordsinsigset             = ', wordsinsigset);
//   writeln( 'wordsinfdset              = ', wordsinfdset);
//   writeln( 'ln2bitsinword             = ', ln2bitsinword);
//   writeln( 'ln2bitmask                = ', ln2bitmask);
//   writeln( 'Size of a SignalActionRec = ', SizeOf( SignalActionRec));
//   writeln( 'Size of SmartProcedure    = ', SizeOf( SmartProcedure));
//   Log( LOG_DEBUG, 'End of SizeOfVars program');
//   writeln( FPC_VERSION, '.', FPC_RELEASE, '.', FPC_PATCH);
end.
