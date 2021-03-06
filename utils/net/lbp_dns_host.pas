{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

A class to hold DNS information about a host

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

unit lbp_dns_host;


interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   lbp_types,
   lbp_utils,
   lbp_ip_utils,
   lbp_binary_trees,
   Sockets,
   Resolve;



// ************************************************************************
// * tDnsName Class
// ************************************************************************

type
   tDnsName = class
      protected
         MyReverseName: string;
         MyForwardName: string;
      public
         constructor Create( HostName: string);
         procedure   SetName( HostName: string);
         procedure   SetReverseName( RevHostName: string);
         property    Name:        string  read MyForwardName  write SetName;
         property    ReverseName: string  read MyReverseName  write SetReverseName;
      end; // tDnsName class


// ************************************************************************
// * tDnsNameTree class - Hold tDnsNames in alphabetical order
// ************************************************************************

type 
   tDnsNameTree = class( tBalancedBinaryTree)
      public
         constructor  Create( InReverseOrder: boolean = false);
         procedure    Add(           Fqdn: string); virtual;
         function     Find(          Item: tDnsName): tDnsName; virtual;
         function     GetFirst():    tDnsName; override;
         function     GetLast():     tDnsName; override;
         function     GetNext():     tDnsName; override;
         function     GetPrevious(): tDnsName; override;
      end; // tDnsNameTree class


// ************************************************************************
// * tDnsIp Class
// ************************************************************************

type
   tDnsIp = class
      protected
         MyIp:    word32;
         MyIpStr: string;
      public
         constructor Create(    iIp:    string);
         constructor Create(    iIp:    word32);
         procedure   SetIpStr(  iIp:    string);
         procedure   SetIp(     iIp:    word32);
         property    Ip:    word32  read MyIp     write SetIP;
         property    IpStr: string  read MyIpStr  write SetIpStr;
      end; // tDnsIp class


// ************************************************************************
// * tDnsIpTree class - Hold tDnsIps in numerical order
// ************************************************************************

type 
   tDnsIpTree = class( tBalancedBinaryTree)
      public
         constructor  Create();
         procedure    Add(           Ip:   word32); virtual;
         procedure    Add(           Ip:   string); virtual;
         function     Find(          Item: tDnsIp): tDnsIp; virtual;
         function     GetFirst():    tDnsIp; override;
         function     GetLast():     tDnsIp; override;
         function     GetNext():     tDnsIp; override;
         function     GetPrevious(): tDnsIp; override;
      end; // tDnsIpTree class


// *************************************************************************
// * tDNSHost class - Holds names and IP addresses of a single host
// *                  If you create the class by passing an IP address or
// *                  FQDN to Create() the DNS lookups are automatically 
// *                  called.
// *************************************************************************
type
   tDnsHost = class
      protected
         IpTree:    tDnsIpTree;
         FqdnTree:  tDnsNameTree;
      public
         constructor Create( IpOrFqdn: string = '');
         destructor  Destroy(); override;
         function  Ip:    word32;  // Returns the first IP in IpTree
         function  IpStr: string;  // Returns the first IP in IpTree
         function  Fqdn:  string;  // Returns the first FQDN in NameTree
         procedure Add( iIp:      word32); virtual;
         procedure Add( IpOrFqdn: string); virtual;
         function  FirstIp:    tDnsIp;
         function  NextIp:     tDnsIp;
         function  FirstFqdn:  tDnsName;
         function  NextFqdn:   tDnsName;
         procedure LookupFqdns();
         procedure LookupIPs();
         procedure Resolve(); // Trys to use DNS to find the most FQDNs and IPs
         procedure Dump(); // Debug procedure which prints the contents of tDnsHost
      end; // tDnsHost


// *************************************************************************

implementation


// =========================================================================
// = tDnsName class - Holds a single FQDN
// =========================================================================
// ************************************************************************
// * Create()
// ************************************************************************

constructor tDnsName.Create( HostName: string);
   begin
      SetName( HostName);
   end; // Create()


// ************************************************************************
// * SetName()
// ************************************************************************

procedure tDnsName.SetName( HostName: string);
   begin
      MyForwardName:= HostName;       
      MyReverseName:= ReverseDottedOrder( HostName);
   end; // SetName()


// ************************************************************************
// * SetReverseName()
// ************************************************************************

procedure tDnsName.SetReverseName( RevHostName: string);
   begin
      MyForwardName:= ReverseDottedOrder( RevHostName);       
      MyReverseName:= RevHostName;
   end; // SetName()



// =========================================================================
// = tDnsNameTree class - holds tDnsName records in alphabetcial order
// =========================================================================
// *************************************************************************
// * CompareByReverseName() - global function used only by trees of tDnsName
// *************************************************************************

function CompareByReverseName(  N1: tDnsName; N2: tDnsName): int8;
   begin
      if( N1.ReverseName > N2.ReverseName) then begin
         result:= 1;
      end else if( N1.ReverseName < N2.ReverseName) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareByReverseName()


// *************************************************************************
// * CompareByName() - global function used only by trees of tDnsName
// *************************************************************************

function CompareByName(  N1: tDnsName; N2: tDnsName): int8;
   begin
      if( N1.Name > N2.Name) then begin
         result:= 1;
      end else if( N1.Name < N2.Name) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareByName()


// *************************************************************************
// * Constructor()
// *************************************************************************

constructor tDnsNameTree.Create( InReverseOrder: boolean = false);
   begin
      if( InReverseOrder) then begin
         inherited Create( tCompareProcedure( @CompareByReverseName), false);
      end else begin
         inherited Create( tCompareProcedure( @CompareByName), false);
      end;
   end; // Create();


// *************************************************************************
// * Add() - Don't even try to add duplicates
// *************************************************************************

procedure tDnsNameTree.Add( Fqdn: string);
   var
      Temp: tDnsName;
   begin
      Temp:= tDnsName.Create( Fqdn);
      if( Find( Temp) = nil) then inherited Add( Temp) else Temp.Destroy;
   end; // Add()


// *************************************************************************
// * Find() - Return the proper type
// *************************************************************************

function tDnsNameTree.Find( Item: tDnsName): tDnsName;
   begin
      result:= tDnsName( inherited Find( Item)); 
   end; // Find()


// *************************************************************************
// * GetFirst() - Return the proper type
// *************************************************************************

function tDnsNameTree.GetFirst(): tDnsName;
   begin
      result:= tDnsName( inherited GetFirst); 
   end; // GetFirst()


// *************************************************************************
// * GetLast() - Return the proper type
// *************************************************************************

function tDnsNameTree.GetLast(): tDnsName;
   begin
      result:= tDnsName( inherited GetLast); 
   end; // GetLast()


// *************************************************************************
// * GetNext() - Return the proper type
// *************************************************************************

function tDnsNameTree.GetNext(): tDnsName;
   begin
      result:= tDnsName( inherited GetNext); 
   end; // GetNext()


// *************************************************************************
// * GetPrevious() - Return the proper type
// *************************************************************************

function tDnsNameTree.GetPrevious(): tDnsName;
   begin
      result:= tDnsName( inherited GetPrevious); 
   end; // GetPrevious()



// =========================================================================
// = tDnsIp - Stores an IP address in a class
// =========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tDnsIp.Create( iIp: string);
   begin
      SetIpStr( iIp);
   end; // Create()


// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tDnsIp.Create( iIp: word32);
   begin
      SetIp( iIp);
   end; // Create()


// *************************************************************************
// * SetIpStr() - Sets the IP address from a string representation
// *************************************************************************

procedure tDnsIp.SetIpStr( iIp: string);
   begin
      MyIp:= IpStringToWord32( iIp);
      MyIpStr:= iIp;
   end; // SetIpStr()


// *************************************************************************
// * SetIp() - Sets the IP address from a string representation
// *************************************************************************

procedure tDnsIp.SetIp( iIp: word32);
   begin
      MyIp:= iIp;
      MyIpStr:= IpWord32ToString( iIp);
   end; // SetIp()



// =========================================================================
// = tDnsIpTree class - holds tDnsIp records in alphabetcial order
// =========================================================================
// *************************************************************************
// * CompareByIp() - global function used only by trees of tDnsIp
// *************************************************************************

function CompareByIp(  I1: tDnsIp; I2: tDnsIp): int8;
   begin
      if( I1.Ip > I2.Ip) then begin
         result:= 1;
      end else if( I1.Ip < I2.Ip) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareByIp()


// *************************************************************************
// * Constructor()
// *************************************************************************

constructor tDnsIpTree.Create();
   begin
      inherited Create( tCompareProcedure( @CompareByIp), false);
   end; // Create();


// *************************************************************************
// * Add() - Don't even try to add duplicates
// *************************************************************************

procedure tDnsIpTree.Add( Ip: word32);
   var
      Temp: tDnsIp;
   begin
      Temp:= tDnsIp.Create( Ip);
      if( Find( Temp) = nil) then inherited Add( Temp) else Temp.Destroy;
   end; // Add()


// *************************************************************************
// * Add() - Don't even try to add duplicates
// *************************************************************************

procedure tDnsIpTree.Add( Ip: string);
   var
      Temp: tDnsIp;
   begin
      Temp:= tDnsIp.Create( Ip);
      if( Find( Temp) = nil) then inherited Add( Temp) else Temp.Destroy;
   end; // Add()


// *************************************************************************
// * Find() - Return the proper type
// *************************************************************************

function tDnsIpTree.Find( Item: tDnsIp): tDnsIp;
   begin
      result:= tDnsIp( inherited Find( Item)); 
   end; // Find()


// *************************************************************************
// * GetFirst() - Return the proper type
// *************************************************************************

function tDnsIpTree.GetFirst(): tDnsIp;
   begin
      result:= tDnsIp( inherited GetFirst); 
   end; // GetFirst()


// *************************************************************************
// * GetLast() - Return the proper type
// *************************************************************************

function tDnsIpTree.GetLast(): tDnsIp;
   begin
      result:= tDnsIp( inherited GetLast); 
   end; // GetLast()


// *************************************************************************
// * GetNext() - Return the proper type
// *************************************************************************

function tDnsIpTree.GetNext(): tDnsIp;
   begin
      result:= tDnsIp( inherited GetNext); 
   end; // GetNext()


// *************************************************************************
// * GetPrevious() - Return the proper type
// *************************************************************************

function tDnsIpTree.GetPrevious(): tDnsIp;
   begin
      result:= tDnsIp( inherited GetPrevious); 
   end; // GetPrevious()



// =========================================================================
// = tDnsHost - Stores FQDNs and Names associated with a host
// =========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tDnsHost.Create( IpOrFqdn: string = '');
   begin
      IpTree:=   tDnsIpTree.Create;
      FqdnTree:= tDnsNameTree.Create;
      if( IpOrFqdn <> '') then begin
         Add( IpOrFqdn);
         Resolve; 
      end;
   end; // Create()


// *************************************************************************
// * Destroy() - Destructor
// *************************************************************************

destructor tDnsHost.Destroy();
   begin
      IpTree.RemoveAll( true);
      IpTree.Destroy;
      FqdnTree.RemoveAll( true);
      FqdnTree.Destroy;
   end;


// *************************************************************************
// * Ip() - Returns the first IP
// *************************************************************************

function tDnsHost.Ip(): word32;
   begin
      if( IpTree.Empty) then result:= 0 else result:= IpTree.GetFirst.Ip;
   end; // Ip()


// *************************************************************************
// * IpStr() - Returns the first IP
// *************************************************************************

function tDnsHost.IpStr(): string;
   begin
      if( IpTree.Empty) then result:= '' else result:= IpTree.GetFirst.IpStr;
   end; // Ip()


// *************************************************************************
// * Fqdn() - Returns the first FQDN
// *************************************************************************

function tDnsHost.Fqdn(): string;
   begin
      if( FqdnTree.Empty) then result:= '' else result:= FqdnTree.GetFirst.Name;
   end; // Ip()


// *************************************************************************
// * Add() - Add an IP address
// *************************************************************************

procedure tDnsHost.Add( iIp: word32);
   begin
      IpTree.Add( iIp);
   end; //


// *************************************************************************
// * Add() - Add an IP address or a FQDN
// *************************************************************************

procedure tDnsHost.Add( IpOrFqdn: string);
   begin
      if( IpOrFqdn[ 1] in ['0'..'9']) then begin
         Add( IPStringToWord32( IpOrFqdn));
      end else begin
         FqdnTree.Add( IpOrFqdn);
      end;
   end; // Add()


// *************************************************************************
// * FirstIp()
// *************************************************************************

function tDnsHost.FirstIp: tDnsIp;
   begin
      result:= IPTree.GetFirst;
   end; // FirstIp()


// *************************************************************************
// * NextIp()
// *************************************************************************

function tDnsHost.NextIp: tDnsIp;
   begin
      result:= IPTree.GetNext;
   end; // NextIp()


// *************************************************************************
// * FirstFqdn()
// *************************************************************************

function tDnsHost.FirstFqdn(): tDnsName;
   begin
      result:= FqdnTree.GetFirst;
   end; // FirstFqdn()


// *************************************************************************
// * NextFqdn()
// *************************************************************************

function tDnsHost.NextFqdn(): tDnsName;
   begin
      result:= FqdnTree.GetNext;
   end; // NextFqdn()


// *************************************************************************
// * LookupFqdns() - Take our internal list of IPs and lookup any associated
// *                 names
// *************************************************************************

procedure tDnsHost.LookupFqdns();
   var
      Temp:  tDnsIp;
      HR:    THostResolver;
      i:     integer;
      iMax:  integer;
   begin
      Temp:= FirstIP;
      while( Temp <> nil) do begin
         HR:= THostResolver.Create( nil);
         if( HR.AddressLookup( Temp.IpStr)) then begin
            Add( HR.ResolvedName);

            iMax:= HR.AliasCount - 1;
            for i:= 0 to iMax do begin
               Add( HR.Aliases[ i]);
            end;
         end;
         HR.Destroy;

         Temp:= NextIp;
      end; // while
   end; // LookupFqdns()


// *************************************************************************
// * LookupIps() - Take our internal list of names and lookup any associated
// *               IPs
// *************************************************************************

procedure tDnsHost.LookupIps();
   var
      Temp:  tDnsName;
      HR: tHostResolver;
   begin
      Temp:= FirstFqdn;
      while( Temp <> nil) do begin
         HR:= tHostResolver.Create( nil);
         if( HR.NameLookup( Temp.Name)) then begin
            Add( HostAddrToStr( HR.HostAddress));
         end;
         HR.Destroy;
         Temp:= NextFqdn;
      end; // while
   end; // LookupFqdns()


// *************************************************************************
// * Resolve() - Use DNS to find other names and IPs associated with the host
// *****************4********************************************************

procedure tDnsHost.Resolve();
   begin
      if( IpTree.Empty and FqdnTree.Empty) then begin
         raise lbp_exception.Create( 'This tDNSHost class has no IPs nor DNS names!');
      end;

      if( not FqdnTree.Empty) then begin
         LookupIps;
      end;

      LookupFqdns;
//      LookupIps;
   end; // Resolve();


// *************************************************************************
// * Dump() - Debug code to display the contents of the class
// *************************************************************************

procedure tDnsHost.Dump();
   var
      N: tDnsName;
      I: tDnsIp;
   begin
      I:= IpTree.GetFirst;
      if( I <> nil) then writeln( '------ IP Addresses ------');
      while( I <> nil) do begin
         writeln( '   ', I.IpStr);
         I:= IpTree.GetNext;
      end;

      N:= FqdnTree.GetFirst;
      if( N <> nil) then begin
         writeln( '------ FQDNs ------');
      end;
      while( N <> nil) do begin
         writeln( '   ', N.Name);
         N:= FqdnTree.GetNext;
      end;

      writeln;
   end; // Dump()



// *************************************************************************

end. // lbp_dns_host unit
