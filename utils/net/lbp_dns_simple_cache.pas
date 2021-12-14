{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

llbp_dns_simple_cache - Provides class functions to do forward and reverse DNS
with each returning only one result.  It also provides a cached DNS lookup 
system to reduce expensive DNS calls when you expect the same IPs or host names
to be looked up many times.

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

unit lbp_dns_simple_cache;


interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   lbp_types,
   lbp_utils,
   lbp_parse_helper,
   lbp_ip_utils,
   lbp_generic_containers,
   Sockets,
   resolve;


// =========================================================================
// = tDnsTuple class
// =========================================================================

type
   tDnsTuple = class
      public
         Name:    string;
         IpW32:    word32;
         constructor Create( NameOrIp: string);
         constructor Create( iIpW32: word32);
         constructor Create();
      private
         function  GetIpStr(): string;
         procedure SetIpStr( IpStr: string);
      public
         property  IpStr: string read GetIpStr write SetIpStr;
      end; // tDnsTuple class



// =========================================================================
// = tDnsTuple container classes
// =========================================================================

type 
   tDnsTupleTree = specialize tgAvlTree< tDnsTuple>;
   tDnsTupleList = specialize tgDoubleLinkedList< tDnsTuple>;


// =========================================================================
// = tDnsTupleTree class
// =========================================================================

type 
   tDnsSimpleCache = class
      private
         ByNameTree:      tDnsTupleTree;
         ByNameNfTree:    tDnsTupleTree; // Not found
         ByIpAddrTree:    tDnsTupleTree;
         ByIpAddrNfTree:  tDnsTupleTree; // Not found
         TestTuple:       tDnsTuple;
         TupleList:       tDnsTupleList;
         HostResolver:    tHostResolver;
      public
         constructor Create();
         destructor  Destroy(); override;
         function    Lookup( NameOrIp: string): string;
         function    ForwardLookup( Name: string): word32;
         function    ReverseLookup( IpW32: word32): string;
      private
         procedure   DumpTree( Tree: tDnsTupleTree);
      end; // tDnsSimpleCache class



// *************************************************************************

implementation

// ========================================================================
// = Global Functions - Compare functions for tDnsTupleTree();
// ========================================================================
// *************************************************************************
// * CompareByName()
// *************************************************************************

function CompareByName(  T1: tDnsTuple;  T2: tDnsTuple):  integer;
   begin
      if( T1.Name > T2.Name) then begin
         result:= 1;
      end else if( T1.Name < T2.Name) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareByName()


// *************************************************************************
// * CompareByIp
// *************************************************************************
function CompareByIp( T1: tDnsTuple;  T2: tDnsTuple):  integer;
   begin
      if( T1.IpW32 > T2.IpW32) then begin
         result:= 1;
      end else if( T1.IpW32 < T2.IpW32) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareByIp()


// =========================================================================
// = tDnsTuple class
// =========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tDnsTuple.Create( NameOrIp: string);
   begin
      inherited Create();
      Name:= '';
      IpW32:= 0;
      if( Length( NameOrIP) < 0) then exit;
      if( NameOrIp[ 1] in NumChrs) then IpW32:= IPStringToWord32( NameOrIp) 
      else Name:= NameOrIp;
   end; // Create()

// -------------------------------------------------------------------------

constructor tDnsTuple.Create( iIpW32: word32);
   begin
      inherited Create();
      Name:= '';
      IpW32:= iIpW32;
   end; // Create()


// -------------------------------------------------------------------------

constructor tDnsTuple.Create();
   begin
      inherited Create();
      Name:= '';
      IpW32:= 0;
   end; // Create()


// *************************************************************************
// * GetIpStr() - Returns the IP address as a string()
// *************************************************************************

function tDnsTuple.GetIpStr(): string;
   begin
      result:= IPWord32ToString( IpW32);
   end; // GetIpStr()


// *************************************************************************
// * SetIpStr() - Sets the IP address as a string 
// *************************************************************************

procedure tDnsTuple.SetIpStr( IpStr: string);
   begin
      IpW32:= IPStringToWord32( IpStr);
   end; // SetIpStr()



// =========================================================================
// = tDnsSimpleCache class
// =========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tDnsSimpleCache.Create();
   begin
      inherited Create();
      TupleList:=      tDnsTupleList.Create();

      ByNameTree:=     tDnsTupleTree.Create( tDnsTupleTree.tCompareFunction(@CompareByName), false);
      ByNameNfTree:=   tDnsTupleTree.Create( tDnsTupleTree.tCompareFunction(@CompareByName), false);
      ByIpAddrTree:=   tDnsTupleTree.Create( tDnsTupleTree.tCompareFunction(@CompareByIp), false);
      ByIpAddrNfTree:= tDnsTupleTree.Create( tDnsTupleTree.tCompareFunction(@CompareByIp), false);
      TestTuple:=      tDnsTuple.Create();

      ByNameTree.Name:=     'Resolved DNS queries sorted by Host Name';
      ByNameNfTree.Name:=   'Unresolved DNS queries sorted by Host Name';
      ByIpAddrTree.Name:=   'Resolved DNS queries sorted by IP Address';
      ByIpAddrNfTree.Name:= 'Unesolved DNS queries sorted by IP Address';
   end; // Create()


// *************************************************************************
// * Destory() - destructor
// *************************************************************************

destructor tDnsSimpleCache.Destroy();
   begin
      HostResolver.Destroy();
      TestTuple.Destroy();

      DumpTree( ByNameTree);
      DumpTree( ByIpAddrTree);
      DumpTree( ByNameNfTree);
      DumpTree( ByIpAddrNfTree);
      
      ByIpAddrNfTree.RemoveAll( False);
      ByIpAddrNfTree.Destroy();

      ByIpAddrTree.RemoveAll( False);
      ByIpAddrTree.Destroy();

      ByNameNfTree.RemoveAll( False);
      ByNameNfTree.Destroy();

      ByNameTree.RemoveAll( False);
      ByNameTree.Destroy();
       
      TupleList.RemoveAll( True);
      TupleList.Destroy();

      inherited Destroy();
   end; // Destroy()


// *************************************************************************
// * Lookup() - Do a DNS forward or reverse DNS lookup depending on the 
// *            contents of NameOrIp.
// *************************************************************************

function tDnsSimpleCache.Lookup( NameOrIp: string): string;
   var
      IpW32: word32;
   begin
      if( Length( NameOrIP) < 0) then begin
         result:= 'unresolved';
         exit;
      end;

      if( NameOrIp[ 1] in NumChrs) then begin
         IpW32:= IPStringToWord32( NameOrIp);
         result:= ReverseLookup( IpW32);
      end else begin
         IpW32:= ForwardLookup( NameorIp);
         result:= IpWord32ToString( IpW32);
      end;
   end; // Lookup()


// *************************************************************************
// * Lookup() - Do a DNS forward or reverse DNS lookup depending on the 
// *            contents of NameOrIp.
// *************************************************************************

function tDnsSimpleCache.ForwardLookup( Name: string): word32;
   begin
      TestTuple.Name:= Name;
      TestTuple.IpW32:= 0;

      


      result:= 0;
   end; // ForwardLookup()


// *************************************************************************
// * Lookup() - Do a DNS forward or reverse DNS lookup depending on the 
// *            contents of NameOrIp.
// *************************************************************************

function tDnsSimpleCache.ReverseLookup( IpW32: word32): string;
   begin
      result:= 'A host name';
   end; // ReverseLookup()


// *************************************************************************
// * DumpTree() - Dump a tree for debugging purposes
// *************************************************************************

procedure tDnsSimpleCache.DumpTree( Tree: tDnsTupleTree);
   var
      T: tDnsTuple;
   begin
      writeln();
      writeln( '*******************************************************************************');
      writeln( '* ', Tree.Name);
      writeln( '*******************************************************************************');
      for T in Tree do begin
         writeln( '   ', T.IpStr:18, T.Name);         
      end;
      writeln();
      writeln();
   end; // DumpTree()


// *************************************************************************

end. // lbp_dns_resolver unit
