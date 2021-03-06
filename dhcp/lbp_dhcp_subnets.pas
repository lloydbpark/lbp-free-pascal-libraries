{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

<brief description of the file.  for exampl: Definition of common types>

Adds a subnet information cache for Kent State's IPdb Subnets.

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

unit lbp_dhcp_subnets;

// Reads Subnet information from IPdb and stores it in a tree
// for quick lookup of the containing subnet for an IP.
// In the background, this unit rereads the subnets every few
// minutes.
// I also added the TimeStamp cron to this unit because I didn't have
// any other good place to put it.

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}      // Non-sized Strings are ANSI strings
//{$RANGECHECKS OFF}     // The HostToNet function works with int32
                       // instead of word32 and so generates rangechecks
                       // with my word32 IP Addresses.  Ignoring the
                       // errors works fine.

interface
uses
   lbp_types,        // word32, etc
   lbp_utils,
   IPdb2_Tables,
   IPdb2_Trees,
   lbp_mysql_db,
   dns_dhcp_subnet_tree,
   lbp_dhcp_server_ini,
   lbp_cron,
   lbp_log,
   lbp_threads,
   baseunix;


// *************************************************************************


// *************************************************************************

function FindContainingSubnet( SearchIP: word32): tSubnetTreeNode;


// *************************************************************************

implementation

// *************************************************************************

type
   tSubnetThread = class( tKentWaitThread)
      public
         Busy:     boolean;
         procedure ProcessOnce(); override;
      end; // tSubnetThread


// *************************************************************************

type
   tSubnetCron = class( tCronJob)
      public
         procedure DoEvent(); override;
      end; // tSubnetCron


// *************************************************************************

type
   tTimeStampCron = class( tCronJob)
      public
         procedure DoEvent(); override;
      end;


// ************************************************************************

var
   IPdb2Conn:          MySQLdbConnection;
   Subnets:            IPRangesTable;
   SubnetTree:         tSubnetTree;
   PreviousSubnetTree: tSubnetTree;
   CritSect:           tRTLCriticalSection;
   TimeStampCron:      tTimeStampCron;
   SubnetCron:         tSubnetCron;
   SubnetThread:       tSubnetThread;

// =========================================================================
// = Global procedures
// =========================================================================
// *************************************************************************
// * FindContainingSubnet() - Returns the tSubnetInfo which contains
// *************************************************************************

function FindContainingSubnet( SearchIP: word32): tSubnetTreeNode;
   begin
      EnterCriticalSection( CritSect);
      result:= SubnetTree.RFind( SearchIP);
      LeaveCriticalSection( CritSect);

      if( result = nil) then begin
         raise KentException.Create(
            'Unable to find the containing subnet for ' +
            IPWord32ToString( SearchIP));
      end;
   end; // FindContainingSubnet()


// *************************************************************************
// * AttemptConnection() - Attempt to open a new connection to IPdb2
// *************************************************************************

function AttemptConnection(): boolean;
   begin
      result:= IPdb2Conn.IsOpen;
      if( not result) then begin
         try
            IPdb2Conn.Open();
            result:= true;
         except
            on KentException do begin
               Log( LOG_WARNING,
                  'Failed to reopen the IPRanges table connection to IPdb2!');
            end;
         end; // try/except
      end; // if not result;
   end; // AttemptConnection()


// *************************************************************************
// * NodeIDsToIPs() - Convert the server NodeIDs of each subnet record in
// *                  SubnetTree to IPs instead of IDs
// *************************************************************************

procedure NodeIDsToIPs( SubnetTree: tSubnetTree;
                        ServerTree: tFullNodeInfoTree;
                        NodeInfo:   FullNodeQuery);
   var
      Server:  tFullNodeInfoTreeNode;
      Subnet:  tSubnetTreeNode;
      i:       integer;
   begin
      Subnet:= tSubnetTreeNode( SubnetTree.GetFirst());
      while( Subnet <> nil) do with Subnet do begin

         // Transfer DNS to ClientDNS if needed
         if( Length( ClientDNS) < 1) then begin
            SetLength( ClientDNS, Length( DNS));
            for i:= 0 to High( DNS) do begin
               ClientDNS[ i]:= DNS[ i];
            end;
         end;

         // Lookup ClientDNS records
         for i:= 0 to High( ClientDNS) do begin
            Server:= ServerTree.Lookup( ClientDNS[ i], NodeInfo);
            ClientDNS[ i]:= Server.CurrentIP;
         end;

         // Lookup WINSserver records
         for i:= 0 to High( WINSserver) do begin
            Server:= ServerTree.Lookup( WINSserver[ i], NodeInfo);
            WINSserver[ i]:= Server.CurrentIP;
         end;

         // Recursive call to process child subnets
         if( Subnet.ChildSubnets <> nil) then begin
            NodeIDsToIPs( Subnet.ChildSubnets, ServerTree, NodeInfo);
         end;

         Subnet:= tSubnetTreeNode( SubnetTree.GetNext());
      end; // while
   end; // NodeIDsToIPs()


// -------------------------------------------------------------------------

procedure NodeIDsToIPs( SubnetTree: tSubnetTree);
   var
      ServerTree: tFullNodeInfoTree;
      NodeInfo:   FullNodeQuery;
      TempServer: tFullNodeInfoTreeNode;
   begin
      ServerTree:= tFullNodeInfoTree.Create();
      NodeInfo:=   FullNodeQuery.Create(
                          IPdb2Conn, ipdb2_tables.DefaultDatabase);
      try
          NodeIDsToIPs( SubnetTree, ServerTree, NodeInfo);

      finally
         // Get rid of our ServerTree
         TempServer:= tFullNodeInfoTreeNode( ServerTree.GetFirst());
         while( TempServer <> nil) do begin
            TempServer.Destroy();
            TempServer:= tFullNodeInfoTreeNode( ServerTree.GetNext());
         end;
         ServerTree.Destroy();
         NodeInfo.Destroy();
      end; // try/finally
   end; // NodeIDsToIPs()


// ========================================================================
// = tSubnetThread
// ========================================================================
// ************************************************************************
// * ProcessOnce() - reread IPdb2 for subnet info and store the results in
// *                 SubnetTree.
// ************************************************************************

procedure tSubnetThread.ProcessOnce();
   var
      NewSubnetTree: tSubnetTree;
   begin
      Busy:= true;

      try
         AttemptConnection();
         NewSubnetTree:= tSubnetTree.Create( Subnets);
         NodeIDsToIPs( NewSubnetTree);
      except
         on KentException do begin
            Log( LOG_DEBUG, 'Error reading subnet information from IPdb2!');
            Ipdb2Conn.Close();
            Busy:= false;
            exit;
         end;
      end; // try/except

      // Rotate the trees
      if( PreviousSubnetTree <> nil) then begin
         PreviousSubnetTree.Destroy();
      end;
      PreviousSubnetTree:= SubnetTree;

      EnterCriticalSection( CritSect);
      SubnetTree:= NewSubnetTree;
      LeaveCriticalSection( CritSect);

      Log( LOG_DEBUG, 'Updated subnet information from IPdb2');

      Busy:= false;
   end; // ProcessOnce()


// ========================================================================
// = tSubnetCron
// ========================================================================
// ************************************************************************
// * DoEvent() - reread IPdb2 for subnet info and store the results in
// *             SubnetTree.
// ************************************************************************

procedure tSubnetCron.DoEvent();
   begin
      if( SubnetThread.Busy) then begin
         Log( LOG_DEBUG,
              'Update subnet information thread has been running too long!');
         fpkill( fpGetPID(), SIGHUP);
      end else begin
         SubnetThread.Resume();
      end;
   end; // DoEvent()



// ========================================================================
// = TimeStampCron
// ========================================================================
// *************************************************************************
// * DoEvent()
// *************************************************************************

procedure tTimeStampCron.DoEvent();
   begin
      if( LogTimeStamp) then begin
         Log( LOG_DEBUG, '*** Timestamp ***');
      end;
   end; // DoEvent()



// =========================================================================
// = Initialization and finalization
// =========================================================================
// *************************************************************************
// * Create our hidden Subnets and SubnetTree objects
// *************************************************************************

initialization
   begin
      if( Debug_Unit_Initialization) then begin
         writeln( 'Initialization of lbp_dhcp_subnets started.');
      end;
      IPdb2Conn:= ipdb2_tables.GetADefaultconnection();
      Subnets:= IPRangesTable.Create( IPdb2Conn, ipdb2_tables.DefaultDatabase);
      PreviousSubnetTree:= nil;
      SubnetTree:= tSubnetTree.Create( Subnets);
      NodeIDsToIPs( SubnetTree);
      InitCriticalSection( CritSect);
      SubnetThread:= tSubnetThread.Create( 'Update Subnet Tree');
      SubnetThread.Busy:= false;
      SubnetCron:= tSubnetCron.Create( 0, RereadSubnetsPeriod);
      TimeStampCron:= tTimeStampCron.Create( 0, 1);
      if( Debug_Unit_Initialization) then begin
         writeln( 'Initialization of lbp_dhcp_subnets ended.');
      end;
   end;


// *************************************************************************
// * finalization - Clean up Subnets and SubnetTree
// *************************************************************************

finalization
   begin
      if( Debug_Unit_Initialization) then begin
         writeln( 'Finalization of lbp_dhcp_subnets started.');
      end;
      TimeStampCron.Destroy();
      SubnetCron.Destroy();
      SubnetThread.Terminate();
      SubnetThread.Resume();
      SubnetThread.WaitFor();
      SubnetThread.Destroy();
      Subnets.Destroy();
      IPdb2Conn.Destroy();
      if( PreviousSubnetTree <> nil) then begin
         PreviousSubnetTree.Destroy();
      end;
      SubnetTree.Destroy();
      DoneCriticalSection( CritSect);
      if( Debug_Unit_Initialization) then begin
         writeln( 'Finalization of lbp_dhcp_subnets started.');
      end;
   end;


// *************************************************************************

end. // lbp_dhcp_subnets unit
