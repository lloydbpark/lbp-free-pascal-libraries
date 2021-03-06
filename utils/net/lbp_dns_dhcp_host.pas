{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

a mimimal DNS/DHCP host record

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

unit lbp_dns_dhcp_host;

// A siple unit to hold a mimimal DNS/DHCP host record.

interface

{$include lbp_standard_modes.inc}

uses
   lbp_types,
   lbp_utils,
   lbp_ip_utils;


// *************************************************************************

type
   tdns_dhcp_host = class
      private
         MyIPAddr:   word32;
         MyMACAddr:  word64;
         function    GetIPStr(): string;
         procedure   SetIPStr( S: string);
         function    GetMACStr(): string;
         procedure   SetMACStr( S: string);
      public
         Name:     string;
         Domain:   string;
         Comment:  string;
         constructor Create();
         property  IP:    word32  read MyIPAddr  write MyIPAddr;
         property  MAC:   word64  read MyMACAddr write MyMACAddr;
         property  IPStr: string  read GetIPStr  write SetIPStr;
         property  MACStr: string read GetMACStr write SetMACStr;
      end; // tdns_dhcp_host


// *************************************************************************

implementation

// =========================================================================
// = tdns_dhcp_host - Stores mimimal informaton for a host record
// =========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tdns_dhcp_host.Create();
   begin
      IP:= 0;
      MAC:= 0;
      Name:= '';
      Domain:= Name;
      Comment:= Name;
   end; // Create()


// *************************************************************************
// * GetIPStr() - Returns the string representation of IP
// *************************************************************************

function tdns_dhcp_host.GetIPStr(): string;
   begin
      result:= IPWord32ToString( IP);
   end; // GetIPStr()


// *************************************************************************
// * SetIPStr() - Sets the IP from a string
// *************************************************************************

procedure tdns_dhcp_host.SetIPStr( S: string);
   begin
      IP:= IPStringToWord32( S);
   end; // SetIPStr()


// *************************************************************************
// * GetMACStr() - Returns the string representation of MAC
// *************************************************************************

function tdns_dhcp_host.GetMACStr(): string;
   begin
      result:= MACWord64ToString( MAC);
   end; // GetMACStr()


// *************************************************************************
// * SetMACStr() - Sets the MAC from a string
// *************************************************************************

procedure tdns_dhcp_host.SetMACStr( S: string);
   begin
      MAC:= MACStringToWord64( S);
   end; // SetMACStr()


// *************************************************************************

end. // lbp_dns_dhcp_host unit
