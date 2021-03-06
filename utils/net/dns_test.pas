{* ***************************************************************************

    Copyright (c) 2017 by Lloyd B. Park

    dns_test -  I wanted to find out how the resolve unit handles dns lookups
                 which return multiple answers.  So I setup some test values
                 and ran the query.  When done, this program should be used
                 as an example for handling multiple return values.

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

program dns_test;

{$include lbp_standard_modes.inc}

uses
   lbp_types,
   sockets,
   resolve;  // part of fcl-net


// ************************************************************************
// * ForwardLookup() - Does a reverse lookup of an IP and prints all 
// *                   returned values.
// ************************************************************************

procedure ForwardLookup( HostName: string);
   var
      HR:        THostResolver;
      MaxAddr:   integer;
      i:         integer;
      IpStr:     string;
   begin
      writeln;
      writeln( '*********************************************************');
      writeln( '* Performing a DNS forward lookup of ', HostName);
      writeln( '*********************************************************');
      writeln;

      HR:= THostResolver.Create( nil);
      try
         if( HR.NameLookup( HostName)) then begin
            writeln( 'The single response is ',HostAddrToStr( HR.HostAddress));
            
            // Do we have more results?
            writeln( 'AliasCount   = ', HR.AliasCount);
            writeln( 'AddressCount = ', HR.AddressCount);
            MaxAddr:= HR.AddressCount - 1;
            for i:= 0 to MaxAddr do begin
               IpStr:= HostAddrToStr( HR.Addresses[ i]);
               writeln( 'Addresses[ ', i, '] = ', IpStr);
            end; // for multiple results
         end else begin
            writeln( 'The lookup failed!'); 
         end;
      finally
         writeln;
         flush( Output);
         HR.ClearData;
         HR.Destroy;
      end; // try/finally 
   end;  // ForwardLookup();



// ************************************************************************
// * ReverseLookup() - Does a reverse lookup of an IP and prints all 
// *                   returned values.
// ************************************************************************

procedure ReverseLookup( IpStr: string);
   var
      HR:        THostResolver;
      MaxAlias:  integer;
      i:         integer;
   begin
      writeln;
      writeln( '*********************************************************');
      writeln( '* Performing a DNS reverse lookup of ', IpStr);
      writeln( '*********************************************************');
      writeln;

      HR:= THostResolver.Create( nil);
      try
         if( HR.AddressLookup( IpStr)) then begin
            writeln( 'The single response is ',HR.ResolvedName);
            
            // Do we have more results?
            MaxAlias:= HR.AliasCount - 1;
            for i:= 0 to MaxAlias do begin
               writeln( 'Aliases[ ', i, '] = ', HR.Aliases[ i]);
            end; // for multiple results
         end else begin
            writeln( 'The lookup failed!'); 
         end;
      finally
         writeln;
         flush( Output);
         HR.ClearData;
         HR.Destroy;
      end; // try/finally
   end; // ReverseLookup();



// ************************************************************************
// * main()
// ************************************************************************

begin
   ReverseLookup( '192.168.254.182');
   ForwardLookup( 'dns-test.park.home');

   writeln( '*********************************************************');
   writeln( '* dns_test done');
   writeln( '*********************************************************');
   writeln;
end.  // dns_test

