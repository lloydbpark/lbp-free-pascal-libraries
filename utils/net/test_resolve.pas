{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Example of how to perform DNS resolves

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

program test_resolv;

{$include lbp_standard_modes.inc}

uses
   sockets, // StrToHostAddr()
   resolve;


var
   HR:  THostResolver;
   IA:  tHostAddr;

   
   
// ************************************************************************
// * main()
// ************************************************************************

begin
   HR:= tHostResolver.Create( nil);
   HR.NameLookup( 'gear.net.kent.edu');
   writeln( HR.AddressAsString);
   HR.ClearData;

   IA:= StrToHostAddr( '131.123.252.42');
   if( HR.AddressLookup( IA)) then begin
      writeln( HR.ResolvedName);
   end else begin
      writeln( 'Address lookup failed!');
   end;
   HR.ClearData;

   HR.Destroy();
end.
