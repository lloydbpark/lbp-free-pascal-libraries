{* ***************************************************************************

    Copyright (c) 2020 by Lloyd B. Park

    ipdb2_dns_dhcp_config_classes adds DNS/DHCP configuration output procedures
    to the IPdb2 table classes.

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

unit ipdb2_dns_dhcp_config_classes;

interface

{$include lbp_standard_modes.inc}
//{$V-}    //Added by LP because it says so below
//{$R-}    //Range checking off
//{$S-}    //Stack checking off
//{$I-}    //I/O checking off
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   lbp_argv,
   lbp_types,     // lbp_exception
   lbp_testbed,
   lbp_xdg_basedir,
   lbp_generic_containers,
   ipdb2_home_config, // Set/save/retrieve db connection settings.
   lbp_ini_files,
   lbp_sql_db,   // SQLCriticalException
   ipdb2_tables,
   ipdb2_flags,
   lbp_ip_utils,  // MAC and IP coversion between words and strings
   lbp_ip_network,  // Manipulate CIDRs
   lbp_unix_time,  // Gets the current time.  Used for generating SOA Serial Numbers
   sysutils;     // Exceptions, DirectoryExists, mkdir, etc


// ************************************************************************
// * tSimpleNode class - Hold a subset of Node information.
// *                     Used by tNodeDictionary.
// ************************************************************************
type
   tSimpleNode = class
      FullName: string;
      IPString: string;
      IPWord32: word32;
   end;  // tSimpleNode Class


// ************************************************************************
// * tDynInfo class - Used to hold the state information about DHCP Dynamic
// * ranges which need output
// ************************************************************************
type
   tDynInfo = class
      public
         InDynRange:  boolean;
         DynStart:     string;
         DynEnd:       string;
         procedure DhcpdConfOut( var DhcpdConf: text);
   end; // tDynInfo class
   

// ************************************************************************
// * tNodeDictionary - A simple dictionary to hold Node information which 
// *                   is often looked up by Node ID such as DNS servers.
// ************************************************************************
type
   tNodeDictionarySub = specialize tgDictionary< word64, tSimpleNode>;
   tNodeDictionary = class( tNodeDictionarySub)
      public
         function FindNodeInfo( ID: Word64): tSimpleNode; virtual;
      end; // tNodeDictionary class


// *************************************************************************
// * tDdiFullNodeQuery - An IPdb2 FullNodeQuery that can output itself to
// *                      DNS and DHCP configuration files
// *************************************************************************
type
   tDdiFullNodeQuery = class( IPdb2_tables.FullNodeQuery)
      public
         procedure DhcpdConfOut( var DhcpdConf: text; DynInfo: tDynInfo);
         procedure FwdZoneOut( var Zone: text);
         procedure RevZoneOut( var Zone: text);
      end; // tDdiFullNodeQuery class


// *************************************************************************
// * tDdiFullAliasQuery - An IPdb2 FullAliasQuery that can output itself to
// *                      DNS configuration files
// *************************************************************************
type
   tDdiFullAliasQuery = class( FullAliasQuery)
      public
         procedure FwdZoneOut( var Zone: text);
         procedure RevZoneOut( var Zone: text);
      end; // tDdiFullAliasQuery class


// *************************************************************************
// * tDdiDomainsTable - An IPdb2 DomainsTable that can output itself to
// *                     DNS configuration files
// *************************************************************************
type
   tDdiDomainsTable = class( DomainsTable)
      public
         Zone:   Text;
         SoaSerial:   string;  // The serial numbers to use for the zone
         procedure DnsConfOut( var DnsConf: text); // Output a record
         procedure OutputConfigs( var DnsConf: text);
      end; // tDdiDomainsTable class


// *************************************************************************
// * tDdiIpRangesTable - An IPdb2 IpRangesTable that can output itself to
// *                     DNS and DHCP configuration files
// *************************************************************************
type
   tDdiIpRangesTable = class( IpRangesTable)
      public
         DynInfo:         tDynInfo;  // current dyanic DHCP range info
         NetInfo:         tNetworkInfo; // Get network prefix
         ForwardNet:      string;  // The network portion of a /8, /16, or /32 network
         ReverseNet:      string;
         Zone:            Text; // Reverse zone file
         SoaSerial:       string;  // The serial numbers to use for the zone
         NodeStartIpStr:  string;
         NodeEndIpStr:    string;

         procedure DhcpdConfOut( var DhcpdConf: text);
         procedure DnsConfOut( var DnsConf: text);
         procedure OutputConfigs( var DhcpdConf, DnsConf: text);
      end; // tDdiIpRangesTable class


// ************************************************************************
// * Global variables
// ************************************************************************
var
   NodeDict:            tNodeDictionary;
   FullNode:            tDdiFullNodeQuery;
   FullAlias:           tDdiFullAliasQuery;
   Domains:             tDdiDomainsTable;
   IPRanges:            tDdiIpRangesTable;
   NamedConf:           Text;
   DhcpdConf:           Text;


// ************************************************************************
// * Global Functions
// ************************************************************************

procedure MarkDone();
procedure MoveFiles(); // Move files from WorkingFolder to production locations
procedure MoveFilesAndRestartServices();

// *************************************************************************

implementation

// *************************************************************************
// * Internal global variables
// *************************************************************************
var
   WorkingFolder:       string;  // The name of the working folder
//   StaticFolder:        string;  // The name of the folder where static include data is stored.
   dhcpd_conf:          string;
   named_conf:          string;
   dns_folder:          string;
   dhcp_folder:         string;
   dhcp_max_lease_secs: string;
   dhcp_def_lease_secs: string;
   dhcp_def_domain:     string;
   dns_contact:         string;
   dns_refresh:         string;
   dns_retry:           string;
   dns_expire:          string;
   dns_min_ttl:         string;
   dns_def_ttl:         string;

// =========================================================================
// = Global Functions
// =========================================================================
// *************************************************************************
// * ClearStaleFiles() - Delete all the files in the WorkingFolder.
// *************************************************************************

procedure ClearStaleFiles();
   var
      SearchRec:  tSearchRec;
      FileName:   string;
   begin
      if( FindFirst( WorkingFolder + '*', 0, SearchRec) = 0) then begin
         repeat
            FileName:= WorkingFolder + SearchRec.Name;
            if( not DeleteFile( FileName)) then begin
               raise lbp_exception.Create( 'Unable to delete the file %s ', [FileName]);
            end;
         until( FindNext( SearchRec) <> 0);
         FindClose( SearchRec);
      end; // If we found any files
   end; // ClearStaleFiles()


// *************************************************************************
// * MarkDone() - Creates a nearly empty file named done.txt in the
// *              WorkingFolder
// *************************************************************************

procedure MarkDone();

   var
      DoneFileName: string = 'done.txt';
      DoneFile:     text;
   begin
      assign( DoneFile, WorkingFolder + DoneFileName);
      rewrite( DoneFile);
      writeln( DoneFile, 'The DNS/DHCP configuration output has completed.');
      close( DoneFile);
   end; // MarkDone()


// *************************************************************************
// * MoveFiles() - Move the files from the WorkingFolder to the production
// *               location.
// *************************************************************************

procedure MoveFiles();
   var
      SearchRec:  tSearchRec;
      FileName:   string;
   begin
      if( FindFirst( WorkingFolder + '*', 0, SearchRec) = 0) then begin
         repeat
            FileName:= WorkingFolder + SearchRec.Name;
            if( pos( 'db.', SearchRec.Name) = 1) then begin
               if( not RenameFile( FileName, dns_folder + SearchRec.Name)) then begin
                  raise lbp_exception.Create( 'Unable to move ' + SearchRec.Name + '!');
               end;
            end else if( pos( 'named', SearchRec.Name) = 1) then begin
               if( not RenameFile( WorkingFolder + SearchRec.Name, dns_folder + SearchRec.Name)) then begin
                  raise lbp_exception.Create( 'Unable to move ' + SearchRec.Name + '!');
               end;
            end else if( pos( 'dhcpd', SearchRec.Name) = 1) then begin
               if( not RenameFile( WorkingFolder + SearchRec.Name, dhcp_folder + SearchRec.Name)) then begin
                  raise lbp_exception.Create( 'Unable to move ' + SearchRec.Name + '!');
               end;
            end
   
         until( FindNext( SearchRec) <> 0);
         FindClose( SearchRec);
      end; // If we found any files
   end; // ClearStaleFiles()



// =========================================================================
// = tDynInfo class - Used to hold the state information about DHCP Dynamic
// = ranges which need output
// =========================================================================
// ************************************************************************
// * DhcpdConfOut( var DhcpdConf: text
// ************************************************************************

procedure tDynInfo.DhcpdConfOut( var DhcpdConf: text);
   begin
      InDynRange:= false;
      writeln( DhcpdConf, '   range ', DynStart, ' ', DynEnd, ';');
      writeln( DhcpdConf);
   end; // DhcpdConfOut()


// =========================================================================
// = tNodeDictionary - A simple dictionary to hold Node information which 
// =                   is often looked up by Node ID such as DNS servers.
// =========================================================================
// ************************************************************************
// * FindNodeInfo() - Returns the tSimpleNode associated with the passed ID
// ************************************************************************

function tNodeDictionary.FindNodeInfo( ID: Word64): tSimpleNode;
   var
      SimpleNode: tSimpleNode;
   begin
      result:= nil;
      if( ID = 0) then exit;

      // Try to get it from NodeDict
      if( Find( ID)) then begin
         result:= Value;
      end else begin

         // Try to look it up in FullNode and add it to NodeDict
         FullNode.NodeID.SetValue( ID);
         FullNode.Query( ' and NodeInfo.ID = ' + FullNode.NodeID.GetSqlValue);
         if( FullNode.Next) then begin
            SimpleNode:= tSimpleNode.Create();
            SimpleNode.FullName:= FullNode.FullName;
            SimpleNode.IPString:= FullNode.CurrentIP.GetValue;
            SimpleNode.IPWord32:= FullNode.CurrentIP.OrigValue;

            Add( FullNode.NodeID.OrigValue, SimpleNode);
            result:= SimpleNode;
         end; // If found in FullNode
      end; // else try FullNode lookup
   end; // FindNodeInfo()


// =========================================================================
// = tDdiFullNodeQuery class
// =========================================================================
// ************************************************************************
// *  DhcpdConfOut() - Output the record's DHCPD configuration 
// ************************************************************************

procedure tDdiFullNodeQuery.DhcpdConfOut( var DhcpdConf: text; DynInfo: tDynInfo);
    var
      IsDyn:      boolean;
   begin
      IsDyn:= Flags.GetBit( ipdb2_flags.IsDynamic);
      if( IsDyn) then begin
         DynInfo.DynEnd:= CurrentIP.GetValue;
         if( not DynInfo.InDynRange) then begin
            DynInfo.InDynRange:= true;
            DynInfo.DynStart:= DynInfo.DynEnd;
         end;
      end else begin
         // If a dynamic range was in progress, the output it.
         if( DynInfo.InDynRange) then DynInfo.DhcpdConfOut( DhcpdConf);

         // Output the Node's DHCP information
         writeln( DhcpdConf, '   host ', Name.GetValue, ' {');
         writeln( DhcpdConf, '      hardware ethernet ', 
                              MacWord64ToString( NIC.OrigValue, ':', 2), ';');
         writeln( DhcpdConf, '      fixed-address ', CurrentIP.GetValue, ';');
         writeln( DhcpdConf, '      option host-name "', Name.GetValue, '";');
         writeln( DhcpdConf, '      option domain-name "', DomainName.GetValue, '";');
         writeln( DhcpdConf, '   } # ', FullName);
         writeln( DhcpdConf);
      end;
   end; // DhcpdConfOut()


// ************************************************************************
// *  FwdZoneOut() - Output the record's forward zone configuration 
// ************************************************************************

procedure tDdiFullNodeQuery.FwdZoneOut( var Zone: text);
   var
      ShortName:  string;
   begin
      ShortName:= Name.OrigValue;
      if( Length( ShortName) = 0) then ShortName:= '@';
      writeln( Zone, ShortName, '  IN  A  ', CurrentIP.GetValue);
   end; // FwdZoneOut()

   
// ************************************************************************
// *  RevZoneOut() - Output the record's reverse zone configuration 
// ************************************************************************

procedure tDdiFullNodeQuery.RevZoneOut( var Zone: text);
   var
      RightOctet:    word32;
      RightOctetStr: string;
   begin
      RightOctet:= CurrentIP.OrigValue mod 256;
      Str( RightOctet, RightOctetStr);
      writeln( Zone, RightOctetStr, '  IN PTR  ', FullName, '.');
   end; // RevZoneOut()

   

// =========================================================================
// = tDdiFullAliasQuery class
// =========================================================================
// ************************************************************************
// *  FwdZoneOut() - Output the record's forward zone configuration 
// ************************************************************************

procedure tDdiFullAliasQuery.FwdZoneOut( var Zone: text);
   var
      ShortName:  string;
   begin
      ShortName:= AliasName.OrigValue;
      if( Length( ShortName) = 0) then ShortName:= '@';
      if( AliasFlags.GetBit( OutputARecord)) then begin
         writeln( Zone, ShortName, '  IN  A  ', CurrentIP.GetValue);
      end else begin
         writeln( Zone, ShortName, '  IN  CNAME  ', FullNodeName, '.');
      end;
   end; // FwdZoneOut()



// ************************************************************************
// *  RevZoneOut() - Output the record's reverse zone configuration 
// ************************************************************************

procedure tDdiFullAliasQuery.RevZoneOut( var Zone: text);
   var
      RightOctet:    word32;
      RightOctetStr: string;
   begin
      if( AliasFlags.GetBit( OutputARecord)) then begin
         RightOctet:= CurrentIP.OrigValue mod 256;
         Str( RightOctet, RightOctetStr);
         writeln( Zone, RightOctetStr, '  IN PTR  ', FullName, '.');
      end;
   end; // RevZoneOut()



// =========================================================================
// = tDdiDomainsTable class
// =========================================================================
// ************************************************************************
// *  DnsConfOut() - Output the record's DNS configuration 
// ************************************************************************

procedure tDdiDomainsTable.DnsConfOut( var DnsConf: text);
   var
      SimpleNode:      tSimpleNode;
   begin
      // Open the reverse zone file
      assign( Zone, WorkingFolder + 'db.' + Name.OrigValue);
      rewrite( Zone);

      writeln( DnsConf, 'zone "', Name.OrigValue, '" {');
      writeln( DnsConf, '   type master;');
      writeln( DnsConf, '   file "db.', Name.OrigValue, '";');
      writeln( DnsConf, '};');
      writeln( DnsConf);

      writeln( Zone, '$TTL ', dns_def_ttl);
      SimpleNode:= NodeDict.FindNodeInfo( DNS1.OrigValue);
      writeln( Zone, Name.OrigValue, '. IN SOA ', SimpleNode.FullName,
               '. ', dns_contact, ' (');
      writeln( Zone, '   ', SoaSerial, '  ; serial number');
      writeln( Zone, '   ', dns_refresh, '      ; refresh');
      writeln( Zone, '   ', dns_retry, '       ; retry');
      writeln( Zone, '   ', dns_expire, '   ; expire');
      writeln( Zone, '   ', dns_min_ttl, ' )     ; minimum TTL');
      writeln( Zone);

      writeln( Zone, '; ****************');
      writeln( Zone, '; * IPRange NS');
      writeln( Zone, '; ****************');
      if( DNS1.OrigValue <> 0) then begin
         SimpleNode:= NodeDict.FindNodeInfo( DNS1.OrigValue);
         writeln( Zone, '@  IN  NS  ', SimpleNode.FullName, '.');
      end;
      if( DNS2.OrigValue <> 0) then begin
         SimpleNode:= NodeDict.FindNodeInfo( DNS2.OrigValue);
         writeln( Zone, '@  IN  NS  ', SimpleNode.FullName, '.');
      end;
      if( DNS3.OrigValue <> 0) then begin
         SimpleNode:= NodeDict.FindNodeInfo( DNS3.OrigValue);
         writeln( Zone, '@  IN  NS  ', SimpleNode.FullName, '.');
      end;
      writeln( Zone);

      writeln( Zone, '; ****************');
      writeln( Zone, '; * NodeInfo A');
      writeln( Zone, '; ****************');
      FullNode.Query( ' and Domains.ID =  ' + ID.GetSQLValue +
                      ' order by NodeInfo.Name');
      while( FullNode.Next) do begin
         FullNode.FwdZoneOut( Zone);
      end;
      writeln( Zone);

      writeln( Zone, '; ****************');
      writeln( Zone, '; * Aliases PTR or CNAME');
      writeln( Zone, '; ****************');
      FullAlias.Query( ' and Aliases.DomainID =  ' + ID.GetSQLValue + 
                      ' order by Aliases.Name');
      while( FullAlias.Next) do begin
         FullAlias.FwdZoneOut( Zone);
      end;
      close( Zone);
   end; // DnsConfOut()


// ************************************************************************
// *  OutputConfigs() - Iterate through the table and output all DNS
// *                    configuration information. 
// ************************************************************************

procedure tDdiDomainsTable.OutputConfigs( var DnsConf: text);
   begin
      // Build the SoaSerial
      CurrentTime.Now; // Set the Current Time from the system clock.
      Str( (CurrentTime.Epoch div 60), SoaSerial);

      Query();
      while( Next) do begin
         if( Flags.GetBit( OutputDns)) then begin
            DnsConfOut( DnsConf);
         end;
      end; // while       
   end; // OutputConfigs()



// =========================================================================
// = tDdiIpRangesTable class
// =========================================================================
// ************************************************************************
// *  DhcpdConfOut() - Output the record's DHCPD configuration 
// ************************************************************************

procedure tDdiIpRangesTable.DhcpdConfOut( var DhcpdConf: text);
   var
      DNS:             string = '';
      SimpleNode:      tSimpleNode;
      NodeStartIp:     word32;
      NodeEndIp:       word32;
   begin
      // Build the list of DNS servers
      SimpleNode:= NodeDict.FindNodeInfo( ClientDNS1.OrigValue);
      if( SimpleNode = nil) then raise SQLdbException.Create( 'A Subnet doesn''t have DNS servers set!');
      DNS:= SimpleNode.IPString;
      SimpleNode:= NodeDict.FindNodeInfo( ClientDNS2.OrigValue);
      if( SimpleNode <> nil) then DNS:= DNS + ', ' + SimpleNode.IPString;
      SimpleNode:= NodeDict.FindNodeInfo( ClientDNS3.OrigValue);
      if( SimpleNode <> nil) then DNS:= DNS + ', ' + SimpleNode.IPString;
      DNS:= DNS + ';';
      
      // Output the shared/common network configuration.
      writeln( DhcpdConf, 'subnet ', StartIP.GetValue(), ' netmask ',
               NetMask.GetValue, ' {');
      writeln( DhcpdConf, '   default-lease-time ', dhcp_def_lease_secs, ';');
      writeln( DhcpdConf, '   max-lease-time ', dhcp_max_lease_secs, ';');
      writeln( DhcpdConf, '   option broadcast-address ', EndIp.GetValue, ';');
      writeln( DhcpdConf, '   option subnet-mask ', NetMask.GetValue, ';');
      writeln( DhcpdConf, '   option routers ', Gateway.GetValue, ';');
      writeln( DhcpdConf, '   option domain-name-servers ', DNS);
      writeln( DhcpdConf, '   option domain-name "', dhcp_def_domain, '";'); 
      writeln( DhcpdConf);

      // Reset our Dynamic DHCP Range state object
      DynInfo.InDynRange:= false;

      // Step through each FullNode in the DHCP Subnet
      NodeStartIp:=  IPRanges.StartIP.OrigValue + 1;
      NodeEndIp:=    IPRanges.EndIP.OrigValue - 1;
      Str( NodeStartIp, NodeStartIpStr);
      Str( NodeEndIp, NodeEndIpStr);
      FullNode.Query( ' and CurrentIP >= ' + NodeStartIpStr + ' and CurrentIP <= ' +
                      NodeEndIpStr + ' order by NodeInfo.CurrentIP');
      while( FullNode.Next) do begin
          FullNode.DhcpdConfOut( DhcpdConf, DynInfo);
      end;

      // If a dynamic range was in progress, the output it.
      if( DynInfo.InDynRange) then DynInfo.DhcpdConfOut( DhcpdConf);

      writeln( DhcpdConf, '} # End of subnet ', IpRanges.StartIP.GetValue, 
               ' ', IpRanges.EndIP.GetValue);
   end; // DhcpdConfOut()


// ************************************************************************
// *  DnsConfOut() - Output the record's DNS configuration 
// ************************************************************************

procedure tDdiIpRangesTable.DnsConfOut( var DnsConf: text);
   var
      SimpleNode:  tSimpleNode;
   begin
      // Open the reverse zone file
      assign( Zone, WorkingFolder + 'db.' + ForwardNet);
      rewrite( Zone);

      writeln( DnsConf, 'zone "', ReverseNet, '.in-addr.arpa" {');
      writeln( DnsConf, '   type master;');
      writeln( DnsConf, '   file "db.', ForwardNet, '";');
      writeln( DnsConf, '};');
      writeln( DnsConf);

      writeln( Zone, '$TTL ', dns_def_ttl);
      SimpleNode:= NodeDict.FindNodeInfo( DNS1.OrigValue);
      writeln( Zone, ReverseNet, '.in-addr.arpa. IN SOA ', SimpleNode.FullName,
               '. ', dns_contact, ' (');
      writeln( Zone, '   ', SoaSerial, '  ; serial number');
      writeln( Zone, '   ', dns_refresh, '      ; refresh');
      writeln( Zone, '   ', dns_retry, '       ; retry');
      writeln( Zone, '   ', dns_expire, '   ; expire');
      writeln( Zone, '   ', dns_min_ttl, ' )     ; minimum TTL');
      writeln( Zone);

      writeln( Zone, '; ****************');
      writeln( Zone, '; * IPRange NS');
      writeln( Zone, '; ****************');
      if( DNS1.OrigValue <> 0) then begin
         SimpleNode:= NodeDict.FindNodeInfo( DNS1.OrigValue);
         writeln( Zone, '@  IN  NS  ', SimpleNode.FullName, '.');
      end;
      if( DNS2.OrigValue <> 0) then begin
         SimpleNode:= NodeDict.FindNodeInfo( DNS2.OrigValue);
         writeln( Zone, '@  IN  NS  ', SimpleNode.FullName, '.');
      end;
      if( DNS3.OrigValue <> 0) then begin
         SimpleNode:= NodeDict.FindNodeInfo( DNS3.OrigValue);
         writeln( Zone, '@  IN  NS  ', SimpleNode.FullName, '.');
      end;
      writeln( Zone);

      writeln( Zone, '; ****************');
      writeln( Zone, '; * NodeInfo PTR');
      writeln( Zone, '; ****************');
      FullNode.Query( ' and CurrentIP > ' + StartIP.GetSQLValue + 
                      ' and CurrentIP < ' + EndIP.GetSQLValue +
                      ' order by NodeInfo.CurrentIP');
      while( FullNode.Next) do begin
         FullNode.RevZoneOut( Zone);
      end;
      writeln( Zone);

      writeln( Zone, '; ****************');
      writeln( Zone, '; * Aliases PTR or CNAME');
      writeln( Zone, '; ****************');
      FullAlias.Query( ' and CurrentIP > ' + StartIP.GetSQLValue + 
                      ' and CurrentIP < ' + EndIP.GetSQLValue +
                      ' order by NodeInfo.CurrentIP');
      while( FullAlias.Next) do begin
         FullAlias.RevZoneOut( Zone);
      end;
      close( Zone);
   end; // DnsConfOut()

   
// ************************************************************************
// *  OutputConfigs() - Iterate through the table and output all DNS and
// *                    DHCP configuration information. 
// ************************************************************************

procedure tDdiIpRangesTable.OutputConfigs( var DhcpdConf, DnsConf: text);
   var
      Slash0Str:   string;
      Slash32Str:  string;
      iCount:      integer;
      i:           integer;
      IpAddrStr:   string;
   begin
      // setup instance variables used by output routines
      DynInfo:= tDynInfo.Create;
      NetInfo:= tNetworkInfo.Create;
      
      // Build the SoaSerial
      CurrentTime.Now; // Set the Current Time from the system clock.
      Str( (CurrentTime.Epoch div 60), SoaSerial);

      Str( Slash[  0], Slash0Str);
      Str( Slash[ 32], Slash32Str);

      // Query for all the subnets except those with an impossible netmask
      Query( 'where NetMask != ' + Slash0Str + 
                     ' and NetMask != ' + Slash32Str + 
                     ' Order by NetMask, StartIP');
      while( Next) do begin
         if( Flags.GetBit( OutputDhcp)) then DhcpdConfOut( DhcpdConf);

         if( Flags.GetBit( OutputDns)) then begin

            // Test to makesure its a /8, /16, or /24, the only allowed size for DNS
            NetInfo.IpAddr:= StartIP.OrigValue;
            NetInfo.NetMask:= NetMask.OrigValue;
            if( (NetInfo.Prefix mod 8) <> 0) then begin
               raise SQLdbException.Create( '%s/%d is not a vaid DNS reverse zone.  The prefix must be 8, 16, or 24!', [NetInfo.IpAddrStr, NetInfo.Prefix]);
            end;

            // Construct the Forward and Reverse Net strings
            iCount:= NetInfo.Prefix div 8;
            IpAddrStr:= NetInfo.IpAddrStr;
            i:= 0;
            while( iCount > 0) do begin
               inc( i); // move to the first character or the next character past a dot
               while( IpAddrStr[ i] <> '.') do inc( i);
               dec( iCount);
            end;
            ForwardNet:= Copy( IpAddrStr, 1, i - 1);
            ReverseNet:= ReverseDottedOrder( ForwardNet);

            DnsConfOut( DnsConf);
         end;
      end; // For each range

      // Cleanup instance variables
      NetInfo.Destroy;
      DynInfo.Destroy;
   end; // OutputConfigs();


// =========================================================================
// = Global functions
// =========================================================================

var
   ini_file_name: string;
   ini_file:      IniFileObj;
   ini_section:   string;


// *************************************************************************
// * MoveFilesAndRestartServices() - Closes files, Moves the DNS/DHCP files 
// *       from the working folder to the production locations.  Then it
// *       restarts the DNS and DHCP services.  Finally it Destory()s 
// *       instance's of classess to properly free memory, etc.
// *************************************************************************

procedure MoveFilesAndRestartServices();
   begin
      Close( NamedConf);
      Close( DhcpdConf);

      MarkDone;
      MoveFiles;

      // Restart the DHCP and DNS servers.
      ExecuteProcess( '/bin/systemctl', ['restart', 'bind9']);
      ExecuteProcess( '/bin/systemctl', ['restart', 'isc-dhcp-server']);

      IPRanges.Destroy;
      Domains.Destroy;
      FullAlias.Destroy;
      FullNode.Destroy;

      NodeDict.RemoveAll( True);
      NodeDict.Destroy;
   end; // MoveFilesAndRestartServices()


// ************************************************************************
// * BuildFolder() - takes an array of strings representing a parent folder
// *    and the child folders which make up the path.  Each subfolder is
// *    created if it doesn't exist.  The single string representing the 
// *    complete path is returned.
// ************************************************************************

function BuildFolder( A: array of string): string;
   var
      SubFolder: string;
   begin
      result:= '';
      for SubFolder in A do begin
         result:= result + SubFolder + DirectorySeparator;
         if( not DirectoryExists( result)) then mkdir( result);
      end;
   end; // BuildFolder()


// *************************************************************************
// * ReadIni() - Set the ini_file_name, read the file and set the global
// *             variables.
// *************************************************************************

procedure ReadIni();
   var
      ini_folder:  string;
      F:           text;
   begin
      // Set the ini_file_name and create the containing folders as needed.
      ini_folder:= lbp_xdg_basedir.ConfigFolder + DirectorySeparator + 'lbp';
      CheckFolder( ini_folder);
      ini_folder:= ini_folder + DirectorySeparator + 'ipdb2-home';
      CheckFolder( ini_folder);
      ini_file_name:= ini_folder + DirectorySeparator + 'ipdb2-dns-dhcp-config.ini';

      // Create a new ini file with empty values if needed.
      if( not FileExists( ini_file_name)) then begin
         if( lbp_types.show_init) then begin
            writeln( '   ReadIni(): No configuration file found.  Creating a new one.');
         end;
         assign( F, ini_file_name);
         rewrite( F);
         writeln( F, '[main]');
         writeln( F, 'dhcpd-conf=dhcpd.conf');
         writeln( F, 'named-conf=named.conf.local');
         writeln( F, 'dns-folder=/etc/bind/');
         writeln( F, 'dhcp-folder=/etc/dhcp/');
         writeln( F, 'dhcp-max-lease-secs=900');
         writeln( F, 'dhcp-def-lease-secs=900');
         writeln( F, 'dhcp-def-domain=junk.org');
         writeln( F, 'dns-contact=junk.gmail.com');
         writeln( F, 'dns-refresh=1200');
         writeln( F, 'dns-retry=300');
         writeln( F, 'dns-expire=2419200');
         writeln( F, 'dns-min-ttl=300');
         writeln( F, 'dns-def-ttl=600');
         writeln( F, '[testbed]');
         writeln( F, 'dhcpd-conf=dhcpd.conf');
         writeln( F, 'named-conf=named.conf.local');
         writeln( F, 'dns-folder=/etc/bind/');
         writeln( F, 'dhcp-folder=/etc/dhcp/');
         writeln( F, 'dhcp-max-lease-secs=900');
         writeln( F, 'dhcp-def-lease-secs=900');
         writeln( F, 'dhcp-def-domain=junk.org');
         writeln( F, 'dns-contact=junk.gmail.com');
         writeln( F, 'dns-refresh=1200');
         writeln( F, 'dns-retry=300');
         writeln( F, 'dns-expire=2419200');
         writeln( F, 'dns-min-ttl=300');
         writeln( F, 'dns-def-ttl=600');
         close( F);
      end;


      // Now we can finally read the ini file
      if( lbp_testbed.Testbed) then ini_section:= 'testbed' else ini_section:= 'main';
      ini_file:=            iniFileObj.Open( ini_file_name, true);
      dhcpd_conf:=          ini_file.ReadVariable( ini_section, 'dhcpd-conf');
      named_conf:=          ini_file.ReadVariable( ini_section, 'named-conf');
      dns_folder:=          ini_file.ReadVariable( ini_section, 'dns-folder');
      dhcp_folder:=         ini_file.ReadVariable( ini_section, 'dhcp-folder');
      dhcp_max_lease_secs:= ini_file.ReadVariable( ini_section, 'dhcp-max-lease-secs');
      dhcp_def_lease_secs:= ini_file.ReadVariable( ini_section, 'dhcp-def-lease-secs');
      dhcp_def_domain:=     ini_file.ReadVariable( ini_section, 'dhcp-def-domain');
      dns_contact:=         ini_file.ReadVariable( ini_section, 'dns-contact');
      dns_refresh:=         ini_file.ReadVariable( ini_section, 'dns-refresh');
      dns_retry:=           ini_file.ReadVariable( ini_section, 'dns-retry');
      dns_expire:=          ini_file.ReadVariable( ini_section, 'dns-expire');
      dns_min_ttl:=         ini_file.ReadVariable( ini_section, 'dns-min-ttl');
      dns_def_ttl:=         ini_file.ReadVariable( ini_section, 'dns-def-ttl');
   end; // ReadIni()


// *************************************************************************
// * ParseArgV() - Parse the command line parameters and initialize variables
// *               which require command line variables.
// *************************************************************************

procedure ParseArgv();
   begin
      if( lbp_types.show_init) then writeln( 'ipdb2_dns_dhcp_config_classes.ParseArgv(): begin');
      
      ReadIni();

      ParseHelper( 'dhcpd-conf', dhcpd_conf);
      ParseHelper( 'named-conf', named_conf);
      ParseHelper( 'dns-folder', dns_folder);
      ParseHelper( 'dhcp-folder', dhcp_folder);
      ParseHelper( 'dhcp-max-lease-secs', dhcp_max_lease_secs);
      ParseHelper( 'dhcp-def-lease-secs', dhcp_def_lease_secs);
      ParseHelper( 'dhcp-def-domain', dhcp_def_domain);
      ParseHelper( 'dns-contact', dns_contact);
      ParseHelper( 'dns-refresh', dns_refresh);
      ParseHelper( 'dns-retry', dns_retry);
      ParseHelper( 'dns-expire', dns_expire);
      ParseHelper( 'dns-min-ttl', dns_min_ttl);
      ParseHelper( 'dns-def-ttl', dns_def_ttl);

      // Test for missing variables
      if( (Length( dhcpd_conf) = 0) or
          (Length( named_conf) = 0) or
          (Length( dns_folder) = 0) or
          (Length( dhcp_folder) = 0) or
          (Length( dhcp_max_lease_secs) = 0) or
          (Length( dhcp_def_lease_secs) = 0) or
          (Length( dhcp_def_domain) = 0)) then begin
         raise SQLdbCriticalException.Create( 'Some ipdb2-home SQL settings are empty!  Please try again with all parameters set.');
      end;

      if( ParamSet( 'ipdb2-dns-dhcp-config-save')) then begin
         ini_file.SetVariable( ini_section, 'dhcpd-conf', dhcpd_conf);
         ini_file.SetVariable( ini_section, 'named-conf', named_conf);
         ini_file.SetVariable( ini_section, 'dns-folder', dns_folder);
         ini_file.SetVariable( ini_section, 'dhcp-folder', dhcp_folder);
         ini_file.SetVariable( ini_section, 'dhcp-max-lease-secs', dhcp_max_lease_secs);
         ini_file.SetVariable( ini_section, 'dhcp-def-lease-secs', dhcp_def_lease_secs);
         ini_file.SetVariable( ini_section, 'dhcp-def-domain', dhcp_def_domain);
         ini_file.SetVariable( ini_section, 'dns-contact', dns_contact);
         ini_file.SetVariable( ini_section, 'dns-refresh', dns_refresh);
         ini_file.SetVariable( ini_section, 'dns-retry', dns_retry);
         ini_file.SetVariable( ini_section, 'dns-expire', dns_expire);
         ini_file.SetVariable( ini_section, 'dns-min-ttl', dns_min_ttl);
         ini_file.SetVariable( ini_section, 'dns-def-ttl', dns_def_ttl);
         ini_file.write();
      end; 
      ini_file.close();
      // writeln( 'dns_contact =     ', dns_contact);
      // writeln( 'dhcp_def_domain = ', dhcp_def_domain);

      // Set our static and working folders
//      StaticFolder:=  lbp_xdg_basedir.CacheFolder;
//      StaticFolder:=  BuildFolder(  [ StaticFolder, 'lbp', 'ipdb2_dns_dhcp_config_out', 'static']);
      WorkingFolder:= lbp_xdg_basedir.CacheFolder;
      WorkingFolder:= BuildFolder(  [ WorkingFolder, 'lbp', 'ipdb2_dns_dhcp_config_out', 'working']);
      dhcpd_conf:= WorkingFolder + dhcpd_conf;
      named_conf:= WorkingFolder + named_conf;

      // Now that the command line and INI variables are read, we can create the 
      //   global tables
      NodeDict:=   tNodeDictionary.Create( tNodeDictionary.tCompareFunction( @CompareWord64s));
      FullNode:=   tDdiFullNodeQuery.Create();
      FullAlias:=  tDdiFullAliasQuery.Create();
      Domains:=    tDdiDomainsTable.Create();
      IPRanges:=   tDdiIPRangesTable.Create();

      ClearStaleFiles; // Start with an empty working folder

      // Opent the DHCPd configuration file and output the global portion
      Assign( DhcpdConf, dhcpd_conf);
      rewrite( DhcpdConf);
      writeln( DhcpdConf, 'ddns-update-style none;');
      writeln( DhcpdConf, 'authoritative;');
      writeln( DhcpdConf);

      // Open the Named configuration file and output the global portion
      Assign( NamedConf, named_conf);
      rewrite( NamedConf);
      writeln( NamedConf, '//');
      writeln( NamedConf, '// Do any local configuration here');
      writeln( NamedConf, '//');
      writeln( NamedConf);
      writeln( NamedConf, 'include "rndc.include";');
      writeln( NamedConf);
      writeln( NamedConf, 'logging {');
      writeln( NamedConf, '   channel queries_log {');
      writeln( NamedConf, '      syslog;');
      writeln( NamedConf, '      severity info;');
      writeln( NamedConf, '   };');
      writeln( NamedConf, '   category default { default_syslog; default_debug; };');
      writeln( NamedConf, '   category unmatched { null; };');
      writeln( NamedConf, '};');
      writeln( NamedConf);

      // writeln( 'dns_contact =     ', dns_contact);
      // writeln( 'dhcp_def_domain = ', dhcp_def_domain);
      if( lbp_types.show_init) then writeln( 'ipdb2_dns_dhcp_config_classes.initialization:  end');
      if( lbp_types.show_init) then writeln( 'ipdb2_dns_dhcp_config_classes.ParseArgv(): end');
   end; // ParseArgV


// *************************************************************************
// * Initialization - Setup the command line parameters and global variables
// *************************************************************************

initialization
   begin
      if( lbp_types.show_init) then writeln( 'ipdb2_dns_dhcp_config_classes.initialization:  begin');
      // Add Usage messages
      AddUsage( '   ========== IP Database DNS/DHCP Config Output Parameters ==========');
      AddParam( ['named-conf'], true, '', 'The DNS configuration file name.');
      AddParam( ['dns-folder'], true, '', 'The DNS configuration file folder with trailing');
      AddUsage( '                                 slash.');
      AddParam( ['dhcpd-conf'], true, '', 'The DHCPD configuration file name.');
      AddParam( ['dhcp-folder'], true, '', 'The DHCP configuration file folder with trailing');
      AddUsage( '                                 slash.');
      AddParam( ['dhcp-max-lease-secs'], true, '', 'The maximum lease time offered to hosts via DHCP.');
      AddParam( ['dhcp-def-lease-secs'], true, '', 'The default lease time offered to hosts via DHCP.');
      AddParam( ['dhcp-def-domain'], true, '', 'The default domain name given to hosts via DHCP.');
      AddParam( ['dns-contact'], False, '', 'The email address of the DNS Admin with a dot');
      AddUsage( '                                 instead of asterisk');
      AddParam( ['dns-refresh'], False, '', 'How many seconds until the zone information');
      AddUsage( '                                 should be refreshed.');
      AddParam( ['dns-retry'], False, '', 'How many seconds until the client should retry.');
      AddParam( ['dns-expire'], False, '', 'How many seconds until the data on');
      AddUsage( '                                 secondary servers is invalid.');
      AddParam( ['dns-min-ttl'], False, '', 'The Minimu time-to-live in seconds.');
      AddParam( ['dns-def-ttl'], False, '', 'The default time-to-live for a record');
      AddParam( ['ipdb2-dns-dhcp-config-save'], False, '', 'Save youor changes to the ipdb2-dns-dhcp-config');
      AddUsage( '                                 settings INI file.');
      AddUsage( '   --testbed                   Set/retrieve the testbed version of these');
      AddUsage( '                                 settings');
      AddUsage( '');
      AddPostParseProcedure( @ParseArgv);
   end; // initialization


// *************************************************************************

end. // ipdb2_dns_dhcp_config_classes
