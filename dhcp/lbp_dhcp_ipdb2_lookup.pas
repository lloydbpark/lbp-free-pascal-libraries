{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Uses the old Kent State IPdb database to lookup DHCP information 

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

unit lbp_dhcp_ipdb2_lookup;

// This unit implements a DHCP tLookupThread which uses IPdb2 to
// perform the lookups.

interface


{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   lbp_types,
   lbp_utils,
   lbp_log,
   lbp_cron,
   lbp_lists,
   lbp_threads,
   lbp_signal_handlers,
   lbp_net_info,   // info about our interfaces
   lbp_net_buffer,
   lbp_net_fields,
   lbp_dhcp_server_ini,
   lbp_dhcp_subnets,
   lbp_dhcp_buffer,
   lbp_dhcp_fields,
   lbp_dhcp_base_server,
   lbp_mysql_db,
   ipdb2_tables,
   ipdb2_trees,       // tIPRanges
   ipdb2_flags,
   lbp_sql_fields,
   lbp_sql_db,
   dns_dhcp_subnet_tree,
   baseunix,          // fpKill() - for aborting the application
   sysutils;          // Exception type


// *************************************************************************

type
   tIPdb2LookupThread = class( tLookupThread)
      public
         FullNode:   FullNodeQuery;
         IPdb2Conn:  MySQLdbConnection;
         AllIP:      AllIPTable;
         SubnetInfo: tSubnetTreeNode;
         Constructor Create( iName: string);
         Destructor  Destroy(); override;

         procedure   UpdateOffer();            override;
         procedure   UpdateAccept();           override;
         procedure   UpdateDecline();          override;
         procedure   UpdateInform();           override;
         procedure   UpdateRelease();          override;
         procedure   Lookup();                 override;
         function    CheckRequest():           boolean; override;
         procedure   TransferData();           override;

         class procedure InitializeThreads();  override;

         function    GetReserved( StartIP: word32; EndIP: word32): word32;
                                                         virtual;
         function    GetRoamIP():              boolean;  virtual;
         procedure   UpdateFromFullNode();     virtual;
         procedure   LookupSubnet();           virtual;
         function    LookupInSubnet():         boolean;  virtual;
         function    LookupNonDynamic():       boolean;  virtual;
         function    LookupDynamic():          boolean;  virtual;
      end; // tIPdb2LookupThread


// *************************************************************************

implementation

var
   LeaseTime: tKentTimeClass;


// ========================================================================
// = tIPdb2LookupThread
// ========================================================================
// *************************************************************************
// * Constructor
// *************************************************************************

constructor tIPdb2LookupThread.Create( iName: string);
   begin
      inherited Create( iName);

      IPdb2Conn:= ipdb2_tables.GetADefaultconnection();
      FullNode:=  FullNodeQuery.Create( IPdb2Conn, ipdb2_tables.DefaultDatabase);
      AllIP:=     AllIPTable.Create( IPdb2Conn,ipdb2_tables.DefaultDatabase);
   end; // Create();


// *************************************************************************
// * Destructor
// *************************************************************************

destructor tIPdb2LookupThread.Destroy();
   begin
      AllIP.Destroy();
      FullNode.Destroy();
      IPdb2Conn.Destroy();
      inherited Destroy();
   end; // Destroy();


// *************************************************************************
// * UpdateFromFullNode() - Use the FullNode table to update NodeInfo
// *************************************************************************

procedure tIPdb2LookupThread.UpdateFromFullNode();
   var
      Query:     String;
      Fld:       dbField;
      FoundOne:  boolean;
   begin
      Query:= 'update NodeInfo set ';

      // Now add any changed fields (columns)
      FoundOne:= false;
      Fld:= dbField( FullNode.Fields.GetFirst());
      while( Fld <> nil) do begin
         if( Fld.HasChanged()) then begin
            if( FoundOne) then begin
               Query:= Query + ', ';
            end else begin
               FoundOne:= true;
            end;

            Query:= Query + Fld.GetSQLName + ' = ' + Fld.GetSQLValue();
         end; // if the field has changed
         Fld:= dbField( FullNode.Fields.GetNext());
      end; // while
      Query:= Query + ' where ID = ' + FullNode.ID.GetSQLValue();

      if( FoundOne) then begin
         FullNode.SQLExecute( Query);
      end;
   end; // UpdateFromFullNode()


// *************************************************************************
// * UpdateOffer() - Update NodeInfo record when the client accepts the
// *                  lease.
// *************************************************************************

procedure tIPdb2LookupThread.UpdateOffer();
   begin
      // Set our Lease time to 30 seconds from now.
      LeaseTime.TimeOfDay:= fpTime() + 30;
      FullNode.LastDHCP.SetValue( LeaseTime.Str);
      UpdateFromFullNode();
   end; // UpdateOffer()


// *************************************************************************
// * UpdateAccept() - Update NodeInfo record when the client accepts the
// *                  lease.
// *************************************************************************

procedure tIPdb2LookupThread.UpdateAccept();
   begin
      // Set our Lease Expire time.
      LeaseTime.TimeOfDay:= fpTime() + int32( DHCPBuffer.DHCPLease.Value);
      FullNode.LastDHCP.SetValue( LeaseTime.Str);
      UpdateFromFullNode();
      {$WARNING  Add NodeInfo_History() update here}
   end; // UpdateAccept()


// *************************************************************************
// * UpdateDecline() - Update NodeInfo record when a client declines the
// *                   lease.
// *************************************************************************

procedure tIPdb2LookupThread.UpdateDecline();
   begin
      raise DHCPException.Create( 'UpdateDecline() code goes here!');
      {$ERROR Fix this using the Java version as a model}
   end; // UpdateDecline()


// *************************************************************************
// * UpdateInform() - Update NodeInfo record when a static IP client
// *                  requests information about its network.
// *************************************************************************

procedure tIPdb2LookupThread.UpdateInform();
   begin
      // Set our Lease Expire time.
      LeaseTime.TimeOfDay:= fpTime() + StdLease;
      FullNode.LastDHCP.SetValue( LeaseTime.Str);
      UpdateFromFullNode();
   end; // UpdateInform()


// *************************************************************************
// * UpdateRelease() - Update NodeInfo record when client releases a lease
// *************************************************************************

procedure tIPdb2LookupThread.UpdateRelease();
   begin
      // Set our Lease expire time to now.
      LeaseTime.TimeOfDay:= fpTime();
      FullNode.LastDHCP.SetValue( LeaseTime.Str);

      // Move it back to home if it is roaming.
      FullNode.CurrentIP.SetValue( FullNode.HomeIP.NewValue);

      UpdateFromFullNode();
      {$WARNING  Add NodeInfo_History() update here}
   end; // UpdateRelease()


// *************************************************************************
// * LookupInSubnet() - Lookup IPdb2 NodeInfo record by MAC where the
// *                    CurrentIP is in the requesting subnet.  Returns true
// *                    if a record is found.
// *************************************************************************

function tIPdb2LookupThread.LookupInSubnet(): boolean;
   var
      QueryStr:   string;
      StartIPStr: string;
      EndIPStr:   string;
      DynamicStr: string;
   begin
      FullNode.CurrentIP.SetValue( SubnetInfo.Range.StartIP);
      StartIPStr:= FullNode.CurrentIP.GetSQLValue();
      FullNode.CurrentIP.SetValue( SubnetInfo.Range.EndIP);
      EndIPStr:= FullNode.CurrentIP.GetSQLValue();
      FullNode.Flags.SetValue( IsDynamic);
      DynamicStr:= FullNode.Flags.GetSQLValue();

      QueryStr:= ' and NIC = NICToLong( ''' +
                 DHCPBuffer.ClientHardwareAddress.StrValue +
                 ''') and CurrentIP >= ' + StartIPStr +
                 ' and CurrentIP <= ' + EndIPStr +
                 ' order by NodeInfo.Flags & ' + DynamicStr;
      FullNode.Query( QueryStr);
      if( FullNode.Next()) then begin
         if( LogLookupProgress) then begin
            Log( LOG_DEBUG, '%s thread [%d] found a registered IP',
                 [ Name, ID])
         end;
         result:= true;
      end else begin
         if( LogLookupProgress) then begin
            Log( LOG_DEBUG,
                 '%s thread [%d] failed to find a registered IP in the subnet',
                 [ Name, ID])
         end;
         result:= false;
      end;
   end; // LookupInSubnet()


// *************************************************************************
// * GetReserved() - Given an IP range, returns the number of IP
// *                 addresses reserved for network devices.
// *************************************************************************

function tIPdb2LookupThread.GetReserved( StartIP: word32; EndIP: word32):
                                                                     word32;
   var
      S: word32;
   begin
      S:= EndIP - StartIP;
      if( S < 255)      then result:= 2
      else if( S <= 255) then result:= 30
      else if( S <= 511) then result:= 55
      else if( S <= 1023) then result:= 105
      else if( S <= 2047) then result:= 205
      else if( S <= 4095) then result:= 256
      else if( S <= 8191) then result:= 512
      else if( S <= 16383) then result:= 1024
      else if( S <= 32767) then result:= 2048
      else if( S <= 65535) then result:= 4096
      else result:= S div 10;
   end; // GetReserved()


// *************************************************************************
// * GetRoamIP() - Sets FullNode.CurrentIP to an available Roaming IP if
// *               possible.
// *************************************************************************

function tIPdb2LookupThread.GetRoamIP(): boolean;
   var
      Reserved: word32;
      StartIP:  word32;
      EndIP:    word32;
   begin
      StartIP:= SubnetInfo.Range.StartIP;
      EndIP:=   SubnetInfo.Range.EndIP;
      Reserved:= GetReserved( StartIP, EndIP);

      AllIP.FindAvailableIP( StartIP + 1, EndIP - Reserved, 1, true);
      if( AllIP.Next()) then begin
         FullNode.CurrentIP.SetValue( AllIP.IP.OrigValue);

         if( LogLookupProgress) then begin
            Log( LOG_DEBUG, '%s thread [%d] found a roaming IP',
                 [ Name, ID])
         end;
         result:= true;
      end else begin
         if( LogLookupProgress) then begin
            Log( LOG_DEBUG, '%s thread [%d] failed to find a roaming IP',
                 [ Name, ID])
         end;
         result:= false;
      end;
   end; // GetRoamIP()


// *************************************************************************
// * LookupNonDynamic() - Lookup IPdb2 NodeInfo record by MAC where the
// *                      IsDynamic flag is NOT set.  It then attempts to
// *                      Find a roaming IP address.  Returns true if a
// *                      record is found.
// *************************************************************************

function tIPdb2LookupThread.LookupNonDynamic(): boolean;
   var
      QueryStr:       string;
      IsDynStr:       string;
      AllowedToRoam:  boolean;
   begin
      if( StaticOnly) then begin
         Log( LOG_DEBUG,
              '%s thread [%d]:  StaticOnly flag is set.  ' +
              'Will not attempt roaming lookup', [ Name, ID]);
         result:= false;
         exit;
      end;

      // Convert the IsDynamic integer value to a string
      FullNode.Flags.SetValue( IsDynamic);
      IsDynStr:= FullNode.Flags.GetSQLValue();


      QueryStr:= ' and NIC = NICToLong( ''' +
                 DHCPBuffer.ClientHardwareAddress.StrValue +
                 ''') and ((NodeInfo.Flags & ' + IsDynStr +
                 ') = 0)';
      FullNode.Query( QueryStr);

      if( FullNode.Next) then begin
         if( (FullNode.HomeIP.OrigValue >= SubnetInfo.Range.StartIP) and
             (FullNode.HomeIP.OrigValue <= SubnetInfo.Range.EndIP)) then begin
            FullNode.CurrentIP.SetValue( FullNode.HomeIP.OrigValue);
               Log( LOG_DEBUG,
                  '%s thread [%d] %s is returning to its home subnet.',
                  [ Name, ID, DHCPBuffer.ClientHardwareAddress.StrValue]);
            result:= true;
         end else begin
            AllowedToRoam:=
                  (FullNode.RoamLevel.OrigValue >= SubnetInfo.RoamLevel) and
                  (SubnetInfo.RoamLevel >= 1);
            AllowedToRoam:= AllowedToRoam or FullNode.Flags.GetBit( RoamOverride);

            if( (not AllowedToRoam) and LogLookupProgress) then begin
               Log( LOG_DEBUG,
                  '%s thread [%d] %s is not allowed to roam.',
                  [ Name, ID, DHCPBuffer.ClientHardwareAddress.StrValue])
            end;

            result:=  AllowedToRoam and GetRoamIP();
         end;
      end else begin
         result:= false;
      end;
   end; // LookupNonDynamic()


// *************************************************************************
// * LookupDynamic() - Lookup IPdb2 NodeInfo record by MAC where the
// *                   IsDynamic flag IS set and the HomeIP is in the
// *                   current subnet.  Returns true if a record is found.
// *************************************************************************

function tIPdb2LookupThread.LookupDynamic(): boolean;
   var
      QueryStr:   string;
      StartIPStr: string;
      EndIPStr:   string;
      DynamicStr: string;
   begin
      if( StaticOnly) then begin
         Log( LOG_DEBUG,
              '%s thread [%d]:  StaticOnly flag is set.  ' +
              'Will not attempt dynamic lookup', [ Name, ID]);
         result:= false;
         exit;
      end;

      FullNode.CurrentIP.SetValue( SubnetInfo.Range.StartIP);
      StartIPStr:= FullNode.CurrentIP.GetSQLValue();
      FullNode.CurrentIP.SetValue( SubnetInfo.Range.EndIP);
      EndIPStr:= FullNode.CurrentIP.GetSQLValue();
      FullNode.Flags.SetValue( IsDynamic);
      DynamicStr:= FullNode.Flags.GetSQLValue();

      QueryStr:=  'and ((NodeInfo.Flags & ' + DynamicStr +
                     ') = ' + DynamicStr +
                     ') and HomeIP > ' + StartIPStr +
                     ' and HomeIP < ' + EndIPStr +
                     ' and LastDHCP < Now() limit 1';
      FullNode.Query( QueryStr);
      if( FullNode.Next()) then begin

         // We found a dynamic, so put our MAC in it.
         FullNode.NIC.SetValue( DHCPBuffer.ClientHardwareAddress.StrValue);
         FullNode.CurrentIP.SetValue( FullNode.HomeIP.OrigValue);

         if( LogLookupProgress) then begin
            Log( LOG_DEBUG, '%s thread [%d] found a dynamic IP',
                 [ Name, ID])
         end;
         result:= true;
      end else begin
         if( LogLookupProgress) then begin
            Log( LOG_DEBUG,
                 '%s thread [%d] failed to find a dynamic IP in the subnet',
                 [ Name, ID])
         end;
         result:= false;
      end;
   end; // LookupDynamic()


// *************************************************************************
// * Lookup() - Lookup node info in IPdb2
// *************************************************************************

procedure tIPdb2LookupThread.Lookup();
   begin
      LookupSubnet();

      // Debug code
//       if( DHCPBuffer.ClientHardwareAddress.StrValue <> '000024c386c8') and
//         (  DHCPBuffer.ClientHardwareAddress.StrValue <> '000bdbcb218d') and
//         (  DHCPBuffer.ClientHardwareAddress.StrValue <> '000874e11694') then begin
//          raise DHCPException.Create(
//                'Temporary block:  Only lloyd-arp''s MAC address may be looked up!');
//       end;

      // Take care of the special case of DHCPDiscover
      if( DHCPBuffer.DHCPOpCode.Value = DHCPDiscover) then begin

         // DHCP Discover only
         if( not( LookupInSubnet() or LookupNonDynamic() or
                  LookupDynamic())) then begin
            raise DHCPException.Create(
               DHCPBuffer.ClientHardwareAddress.StrValue +
            ' not registered, or no roaming IP, or no Dynamic IPs were available')
         end;
      end else begin

         // All other DHCP and BootP op codes
         if( not LookupInSubnet()) then begin
            raise DHCPException.Create(
               DHCPBuffer.ClientHardwareAddress.StrValue +
               ' not found in the requesting subnet and BootP must be static');
         end;
      end;  // else all dhcp and bootp op codes

      // Check to make sure we can use the found record
      if( (not IgnoreOutputDHCP) and FullNode.Flags.GetBit( OutputDHCP))
                                                                   then begin
         raise DHCPException.Create(
            DHCPBuffer.ClientHardwareAddress.StrValue +
            '''s IPdb2 record does not have the ''Use DHCP'' flag set!');
      end;

      // Set our bootp flag as needed.
      if( DHCPBuffer.DHCPOpCode.Value = BootPRequest) then begin
         FullNode.Flags.SetBit( UsedBootP, true);
      end else begin
         FullNode.Flags.SetBit( UsedBootP, false);
      end;
   end; // Lookup()


// *************************************************************************
// * CheckRequest() - Check to make sure the requested information is OK.
// *                  There are three return possibilities, true, false, and
// *                  exception.
// *                  True:  The packet is OK and ProcessRequest() will
// *                         send an Acknowledge.
// *                  False: The packet was meant for another server and
// *                         we can ignore it.
// *                  Exception:  The requested information is not right, so
// *                              we will send a Negative Acknowledge.
// *************************************************************************

function tIPdb2LookupThread.CheckRequest(): boolean;
   begin
      with DHCPBuffer do begin

         // Check to make sure the request was meant for us.
         if( ((ServerID.Value <> 0) and (ServerID.Value <> ServerIP)) or
             ((ServerIPAddr.Value <> 0) and (ServerIPAddr.Value <> ServerIP)))
                                                                     then begin
            if( DebugServerIgnore) then begin
               Log( LOG_DEBUG,
                  '%s thread [%d]:  It appears this packet was directed' +
                  ' at another DHCPServer.  Server ID = %s,  Server IP = %s,' +
                  ' My IP = %s', [ Name, Self.ID, ServerID.StrValue,
                  ServerIPAddr.StrValue, IPWord32ToString( ServerIP)]);
            end;
            result:= false;
            exit;
         end; // If packet was not meant for us.

         // check our lease
         if( (not GrantLongLeases) and (DHCPLease.Value > word32( StdLease)))
                                                                  then begin
            raise DHCPException.Create(
               '%s thread [%d]: Requested lease time is too long!',
               [ Name, Self.ID]);
         end;

         // Make sure the requested IP address is OK
         if( (RequestedIPAddr.Value <> FullNode.CurrentIP.NewValue) and
             (ClientSuppliedIPAddr.Value <> FullNode.CurrentIP.NewValue))
                                                                   then begin
            raise DHCPException.Create(
               '%s thread [%d]: Requested IP address is incorrect!',
               [ Name, Self.ID]);
         end;

//       At the momement we can not perform the checks below because we
//          don't know if the values were sent in the packet.
//          // Make sure the Gateway is OK
//          if( Routers.Value[ 0] <> SubnetInfo.Gateway) then begin
//             raise DHCPException.Create(
//             '%s thread [%d]: Requested Gateway (router)' +
//             ' IP address is incorrect!', [ Name, Self.ID]);
//          end;
//
//          // Make sure the NetMask is OK
//          if( SubnetMask.Value <> SubnetInfo.NetMask) then begin
//             raise DHCPException.Create(
//             '%s thread [%d]: Requested netmask is incorrect!',
//             [ Name, Self.ID]);
//          end;
      end; // with DHCPBuffer

      result:= true;
   end; // CheckRequest()


// *************************************************************************
// * InitializeThreads() - Static function which initializes the Lookup
// *                       threads.
// *************************************************************************

procedure tIPdb2LookupThread.InitializeThreads();
   var
      i:          integer;
   begin
      // Start the lookup threads
      for i:= 1 to LookupThreads do begin
         tIPdb2lookupThread.Create( 'IPdb2 Lookup');
      end;
   end; // InitializeThreads()


// *************************************************************************
// * LookupSubnet() - Try to look up the subnet which originated the packet.
// *************************************************************************

procedure tIPdb2LookupThread.LookupSubnet();
   var
      SearchIP: word32;
      IFInfo:   tNetInterfaceInfo;
      NetInfo:  tNetworkInfo;
   begin
      SearchIP:= DHCPBuffer.GatewayIPAddr.Value;
      if( SearchIP = 0) then begin
         SearchIP:= DHCPBuffer.GetLocalIP();
         if( SearchIP = 0) then begin
            // Packet was from a Local broadcast
            IFInfo:= GetNetInterfaceInfo( DHCPBuffer.IFName );
            NetInfo:= tNetworkInfo( IFInfo.IPList.GetFirst());
            SearchIP:= NetInfo.IPAddr;
         end;
      end;

      SubnetInfo:= FindContainingSubnet( SearchIP);

      if( not (IgnoreOutputDHCP or SubnetInfo.OutputDHCP)) then begin
         raise DHCPException.Create(
             'DHCP output is disabled for subnet ' +
             IPWord32ToString( SubnetInfo.Range.StartIP) + ' to ' +
             IPWord32ToString( SubnetInfo.Range.EndIP));
      end;
   end; // LookupSubnet()


// *************************************************************************
// * TransferData() - Copy the NodeInfo data to DHCPBuffer's fields
// *************************************************************************

procedure tIPdb2LookupThread.TransferData();
   var
      i:      integer;
      D:      string;
      L:      integer;
      Lease:  word32;
   begin
      with DHCPBuffer do begin
         ServerID.Value:= ServerIP;
         ServerIPAddr.Value:= ServerIP;
         Hops.Value:= 0;
         SecondsElapsed.Value:= 0;
         ClientSuppliedIPAddr.Value:= 0;

         // If the full name is the domain name, then split the domain name.
         if( Length( FullNode.Name.NewValue) = 0) then begin
            D:= FullNode.DomainName.NewValue;
            L:= Length( D);
            i:= pos( D, '.');
            HostName.StrValue:= copy( D, 1, i - 1);
            IPDomain.StrValue:= copy( D, i + 1, L - 1);
         end else begin
            HostName.StrValue:= FullNode.Name.NewValue;
            IPDomain.Strvalue:= FullNode.DomainName.NewValue;
         end;
         ClientIPAddr.Value:= FullNode.CurrentIP.NewValue;
         SubnetMask.Value:= SubnetInfo.NetMask;
         Routers.Value[ 0]:= SubnetInfo.Gateway;
         for i:= 0 to high( SubnetInfo.ClientDNS) do begin
            NameServers.Value[ i]:= word32( SubnetInfo.ClientDNS[ i]);
         end;
         BroadcastAddress.Value:= SubnetInfo.Range.EndIP;

         // Handle WINS servers
         if( Length( SubnetInfo.WinsServer) = 0) then begin
            WINSServers.Clear();
            WINSScope.Clear();
            NetBIOSNode.Clear();
         end else begin
            for i:= 0 to high( SubnetInfo.WINSServer) do begin
               WINSServers.Value[ i]:= word32( SubnetInfo.WINSServer[ i]);
            end;
         end;

         BootFile.StrValue:= FullNode.BootFile.NewValue;

         // Calculate the lease time
         if( not GrantLongLeases) then begin

            // Roaming or dyanmic?
            if( (FullNode.HomeIP <> FullNode.CurrentIP) or
                FullNode.Flags.GetBit( IsDynamic)) then begin
                Lease:= DynLease;
            end else begin
               // Registered and in our Home subnet.
               Lease:= StdLease;
            end;
            if( Lease < DHCPLease.Value) then begin
               DHCPLease.Value:= Lease;
            end;
         end; // if not GrantLongLeases

         MajicCookie.Clear();
      end; // with DHCPBuffer
   end;  // TransferData();



// ========================================================================
// = Initialization and Finalization
// ========================================================================
// ************************************************************************

Initialization
      if( Debug_Unit_Initialization) then begin
         writeln( 'Initialization of lbp_dhcp_ipdb2_lookup started.');
      end;
      LeaseTime:= tKentTimeClass.Create();
      tIPdb2LookupThread.InitializeThreads();
      if( Debug_Unit_Initialization) then begin
         writeln( 'Initialization of lbp_dhcp_ipdb2_lookup ended.');
      end;
   end;


// ************************************************************************

finalization
   begin
      if( Debug_Unit_Initialization) then begin
         writeln( 'Finalization of lbp_dhcp_ipdb2_lookup started.');
      end;
      LeaseTime.Destroy();
      if( Debug_Unit_Initialization) then begin
         writeln( 'Finalization of lbp_dhcp_ipdb2_lookup ended.');
      end;
   end;


// *************************************************************************

end. // lbp_dhcp_ipdb2_lookup unit
