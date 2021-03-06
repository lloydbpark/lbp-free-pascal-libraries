{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

<brief description of the file.  for exampl: Definition of common types>

defines the base class for an ipv4 DHCP server

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

unit lbp_dhcp_base_server;

// Contains the basic logic for a dhcp server.
// A child of tLookupThread class should be implemented by an actual server
// and it's static InitializeThreads function should be called an
// initialization section of unit where it is defined.

interface


{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   lbp_types,
   lbp_log,
   lbp_lists,
   lbp_threads,
   lbp_dhcp_server_ini,
   lbp_dhcp_buffer,
   lbp_dhcp_socket,
   lbp_dhcp_fields,
   baseunix,           // fpKill() - for aborting the application
   sysutils;           // Exceptions


// *************************************************************************

type
   DHCPException = class( KentException);


   // Raise in a tLookupThread to terminate the program
   DHCPCriticalException = class( DHCPException);


// *************************************************************************

type
   tRecieverThread = class( tKentProducerConsumerThread)
      public
         DHCPSocket: tDHCPSocket;
         Constructor Create( InterfaceName: string);
         Destructor  Destroy(); override;
         function  ProcessOneElement( InputElement: tClass): tClass; override;
         class procedure InitializeThreads(); virtual;
      end;


// *************************************************************************

type
   tLookupThread = class( tKentProducerConsumerThread)
      public
         DHCPBuffer: tDHCPBuffer;
         Constructor Create( iName: string);
         Destructor  Destroy(); override;
         function    ProcessOneElement( InputElement: tClass): tClass;
                                                                    override;
         procedure   SendRequestAcknowledge();
         procedure   SendInformAcknowledge();
         procedure   SendNegativeAcknowledge( ErrorStr: string);
         procedure   ProcessDiscover();
         procedure   ProcessRequest();
         procedure   ProcessRelease();
         procedure   ProcessInform();
         procedure   ProcessDecline();
         procedure   ProcessBootP();

         procedure   UpdateOffer();   virtual abstract;
         procedure   UpdateAccept();  virtual abstract;
         procedure   UpdateDecline(); virtual abstract;
         procedure   UpdateInform();  virtual abstract;
         procedure   UpdateRelease(); virtual abstract;
         procedure   Lookup();        virtual abstract;
         function    CheckRequest():  boolean; virtual abstract;
         procedure   TransferData();  virtual abstract;

         class procedure InitializeThreads(); virtual abstract;

         procedure Send();          virtual;
      end;


// *************************************************************************

implementation

// *************************************************************************

var
   AllBuffers:   DoubleLinkedList;
   ReadyBufferQ: tKentClassList;
   BusyBufferQ:  tKentClassList;

   MainThreads:   DoubleLinkedList;  // The DHCP Reciever and Lookup threads
   RecieverThrdQ: tKentClassList;
   LookupThrdQ:   tKentClassList;



// ========================================================================
// = tRecieverThread
// ========================================================================
// *************************************************************************
// * Constructor
// *************************************************************************

constructor tRecieverThread.Create( InterfaceName: string);
   begin
      DHCPSocket:= tDHCPSocket.Create( InterfaceName, DHCPServerPortNumber);
      DHCPSocket.IsOpen:= true;
      DHCPSocket.SetSocketTimeout( 1, 0); // 1 second timeouts on reads

      MainThreads.Enqueue( Self);
      Name:= 'DHCP Reciever';
      inherited Create( ReadyBufferQ, BusyBufferQ, LookupThrdQ, RecieverThrdQ);
      if( DebugThread) then begin
         Log( LOG_DEBUG, 'Reciever thread %d for %s created.',
                         [ID, DHCPSocket.EthInterface]);
      end;
   end; // Create();


// *************************************************************************
// * Destructor
// *************************************************************************

destructor tRecieverThread.Destroy();
   begin
      DHCPSocket.IsOpen:= false;
      DHCPSocket.Destroy();
      if( DebugThread) then begin
         Log( LOG_DEBUG, 'Reciever thread %d destroyed.', [ID]);
      end;
      inherited Destroy();
   end; // Destroy();


// *************************************************************************
// * ProcessOneElement() - Process the element
// *************************************************************************

function tRecieverThread.ProcessOneElement( InputElement: tClass): tClass;
   var
      Buffer: tDHCPBuffer;
      Done:   boolean;
   begin
      Done:= false;
      Buffer:= tDHCPBuffer( InputElement);
      repeat
         try
            // Clear the lease because we don't want the lookup functions
            // to calculate the lease based on what some other client set
            // in a previous packet.
            Buffer.DHCPLease.Clear();
            Buffer.ParameterRequestList.Clear();

            DHCPSocket.ReadPacket( Buffer);
            Buffer.ServerIP:= DHCPSocket.MyIP;
            Done:= true;
            inc( Buffer.PacketID);
            Buffer.Decode();
            if( DebugServerInput) then begin
               Buffer.LogFullPacket();
            end;
         except
            on Exception do begin
               if( Terminated) then begin
                  result:=InputElement;
                  Terminate();
                  exit;
               end;
            end;
         end; // try/except
      until Done;
      result:= InputElement;

      Log( LOG_DEBUG, 'Reciever thread %d (%s) processing a packet',
                      [ID, DHCPSocket.EthInterface]);
   end; // ProcessOneElement()


// *************************************************************************
// * InitializeThreads() - Static function which initializes the receiver
//                         threads.
// *************************************************************************

procedure tRecieverThread.InitializeThreads();
   var
      iStart:  integer;
      iEnd:    integer;
      IFName:  string;
      L:       integer;
   begin
      L:= Length( Interfaces);
      if( L = 0) then begin
         raise KentException.Create( 'Invalid interface setting in INI file!');
      end;

      iStart:= 1;
      iEnd:=   1;
      for iEnd:= 1 to L do begin
         if( Interfaces[ iEnd] = ' ') then begin
            if( iStart = iEnd) then begin
               inc( iStart);
            end else begin
               IFName:= copy( Interfaces, iStart, iEnd - iStart);
               tRecieverThread.Create( IFName);
               iStart:= iEnd;
            end;
         end;
      end;
      IFName:= copy( Interfaces, iStart, L - iStart + 1);
      tRecieverThread.Create( IFName);
   end;


// ========================================================================
// = tLookupThread
// ========================================================================
// *************************************************************************
// * Constructor
// *************************************************************************

constructor tLookupThread.Create( iName: string);
   begin
      inherited Create( BusyBufferQ, ReadyBufferQ, RecieverThrdQ, LookupThrdQ);

      MainThreads.Enqueue( Self);

      Name:= iName;
      if( DebugThread) then begin
         Log( LOG_DEBUG, 'Thread %s [%d] created', [Name, ID]);
      end;
   end; // Create();


// *************************************************************************
// * Destructor
// *************************************************************************

destructor tLookupThread.Destroy();
   begin
      if( DebugThread) then begin
         Log( LOG_DEBUG, 'Thread %s [%d] destroyed', [Name, ID]);
      end;
      inherited Destroy();
   end; // Destroy();


// *************************************************************************
// * ProcessOneElement() - Process the element
// *************************************************************************

function tLookupThread.ProcessOneElement( InputElement: tClass): tClass;
   begin
      DHCPBuffer:= tDHCPBuffer( InputElement);

      try
         case DHCPBuffer.DHCPOpCode.Value of
            dhcpDiscover: begin
                     ProcessDiscover();
                  end;
            dhcpRequest: begin
                     ProcessRequest();
                  end;
            dhcpRelease: begin
                     ProcessRelease();
                  end;
            dhcpInform: begin
                     ProcessInform();
                  end;
            dhcpDecline: begin
                     ProcessDecline();
                  end;
            bootpRequest: begin
                     ProcessBootP();
                  end;
         end; // case

      except
         on E: DHCPCriticalException do begin
            Log( LOG_CRIT, E.Message);
            fpKill( fpGetPID(), SIGHUP);
         end;
         on E: Exception do begin
            Log( LOG_WARNING, E.message);
         end;
      end; // try/except

      result:= InputElement;
   end; // ProcessOneElement()


// *************************************************************************
// * SendRequestAcknowledge()
// *************************************************************************

procedure tLookupThread.SendRequestAcknowledge();
   begin
      if( DebugServerOutput) then begin
         Log( LOG_DEBUG,
         '%s thread [%d] sending an Acknowledge', [ Name, ID]);
      end;

      TransferData();

      // Now form the DHCP Ack and send it.
      with DHCPBuffer do begin
         OpCode.Value:= BootReplyOp;
         AddBaseFields();

         // Add the DHCP Opetion
         DHCPOpCode.Value:= dhcpAck;
         Fields.Enqueue( DHCPOpCode);

         Fields.Enqueue( ServerID);
         Fields.Enqueue( DHCPLease);

         AddOptions();
         Fields.Enqueue( DataEnd);

         Encode();
         if( DebugServerOutput) then begin
            LogFullPacket();
         end;
      end;

      Send();
   end; // SendRequestAcknowledge()


// *************************************************************************
// * SendInformAcknowledge() - Just Like SendRequestAck except
// *                           ClientIPAddr is set to zero and no lease is
// *                           sent.
// *************************************************************************

procedure tLookupThread.SendInformAcknowledge();
   begin
      if( DebugServerOutput) then begin
         Log( LOG_DEBUG,
         '%s thread [%d] sending an Inform Acknowledge', [ Name, ID]);
      end;

      TransferData();

      // Now form the DHCP Ack and send it.
      with DHCPBuffer do begin
         OpCode.Value:= BootReplyOp;
         ClientIPAddr.Value:= 0;
         AddBaseFields();

         // Add the DHCP Opetion
         DHCPOpCode.Value:= dhcpAck;
         Fields.Enqueue( DHCPOpCode);

         Fields.Enqueue( ServerID);

         AddOptions();
         Fields.Enqueue( DataEnd);

         Encode();
         if( DebugServerOutput) then begin
            LogFullPacket();
         end;
      end;

      Send();
   end; // SendInformAcknowledge()


// *************************************************************************
// * SendNegativeAcknowledge()
// *************************************************************************

procedure tLookupThread.SendNegativeAcknowledge( ErrorStr: string);
   begin
      if( DebugServerOutput) then begin
         Log( LOG_DEBUG,
         '%s thread [%d] sending a Negative Acknowledge', [ Name, ID]);
      end;

      // Form the DHCP NAck and send it.
      with DHCPBuffer do begin
         OpCode.Value:= BootReplyOp;
         ServerIPAddr.Value:= 0;
         Hops.Value:= 0;
         SecondsElapsed.Value:= 0;
         ClientsuppliedIPaddr.Value:= 0;
         ClientIPaddr.Value:= 0;
         AddBaseFields();

         // Add the DHCP Opetion
         DHCPOpCode.Value:= dhcpNAck;
         Fields.Enqueue( DHCPOpCode);

         Fields.Enqueue( ServerID);

         // Add the Error Message
         ErrorMessage.StrValue:= ErrorStr;
         Fields.Enqueue( ErrorMessage);

         Fields.Enqueue( DataEnd);

         Encode();
         if( DebugServerOutput) then begin
            LogFullPacket();
         end;
      end;

      Send();
   end; // SendNegativeAcknowledge()


// *************************************************************************
// * ProcessDiscover() - Handle a Discover packet.
// *************************************************************************

procedure tLookupThread.ProcessDiscover();
   begin
      if( DebugServerInput) then begin
         Log( LOG_DEBUG,
         '%s thread [%d] processing a DHCP Discover packet', [ Name, ID]);
      end;

      Lookup(); // Throws exception on any error
      TransferData();

      // Now form the DHCP Offer and send it.
      with DHCPBuffer do begin
         OpCode.Value:= BootReplyOp;
         AddBaseFields();

         // Add the DHCP Opetion
         DHCPOpCode.Value:= dhcpOffer;
         Fields.Enqueue( DHCPOpCode);

         Fields.Enqueue( ServerID);
         Fields.Enqueue( DHCPLease);

         AddOptions();
         Fields.Enqueue( DataEnd);

         Encode();
         if( DebugServerOutput) then begin
            LogFullPacket();
         end;
      end;

      UpdateOffer();
      Send();
   end; // ProcessDiscover()


// *************************************************************************
// * ProcessRequest() - Handle a Request packet.
// *************************************************************************

procedure tLookupThread.ProcessRequest();
   begin
      if( DebugServerInput) then begin
         Log( LOG_DEBUG,
         '%s thread [%d] processing a DHCP Request packet', [ Name, ID]);
      end;

      Lookup(); // Throws exception on any error

      // CheckOK raises an exception on any error
      try
         if( CheckRequest()) then begin
            UpdateAccept();
            SendRequestAcknowledge();
         end;
      except
         on E: DHCPException do begin
            SendNegativeAcknowledge( E.Message);
            raise ;
         end;
      end; // try/except
   end; // ProcessRequest()


// *************************************************************************
// * ProcessRelease() - Handle a Release packet.
// *************************************************************************

procedure tLookupThread.ProcessRelease();
   begin
      if( DebugServerInput) then begin
         Log( LOG_DEBUG,
         '%s thread [%d] processing a DHCP Release packet', [ Name, ID]);
      end;
      UpdateRelease();
   end; // ProcessRelease()


// *************************************************************************
// * ProcessInform() - Handle an Inform packet.  The static machine is
// *                   asking for more information about its network.
// *                   This is NOT a lease.
// *************************************************************************

procedure tLookupThread.ProcessInform();
   begin
      if( DebugServerInput) then begin
         Log( LOG_DEBUG,
         '%s thread [%d] processing a DHCP Inform packet', [ Name, ID]);
      end;

      Lookup(); // Throws exception on any error

      // CheckOK raises an exception on any error
      if( CheckRequest()) then begin
         UpdateAccept();
         SendInformAcknowledge();
      end;
   end; // ProcessInform()


// *************************************************************************
// * ProcessDecline() - Handle a Decline packet.
// *************************************************************************

procedure tLookupThread.ProcessDecline();
   begin
      if( DebugServerInput) then begin
         Log( LOG_DEBUG,
         '%s thread [%d] processing a DHCP Decline packet', [ Name, ID]);
      end;
      UpdateDecline();
   end; // ProcessDecline()


// *************************************************************************
// * ProcessBootP() - Handle a bootp packet.
// *************************************************************************

procedure tLookupThread.ProcessBootP();
   begin
      if( DebugServerInput) then begin
         Log( LOG_DEBUG,
         '%s thread [%d] processing a BootP Request packet', [ Name, ID]);
      end;

      Lookup(); // Throws exception on any error
      TransferData();

      // Now form the bootp response and send it.
      with DHCPBuffer do begin
         OpCode.Value:= BootReplyOp;
         AddBaseFields();
         Fields.Enqueue( SubnetMask);
         Fields.Enqueue( Routers);
         Fields.Enqueue( NameServers);
         Fields.Enqueue( HostName);
         Fields.Enqueue( IPDomain);
         Fields.Enqueue( BroadcastAddress);
         Fields.Enqueue( DataEnd);
         Encode();
         if( DebugServerOutput) then begin
            LogFullPacket();
         end;
      end;

      UpdateAccept();

      Send();
   end; // ProcessBootP()


// *************************************************************************
// * Send() - Send our DHCP response to the client
// *************************************************************************

procedure tLookupThread.Send();
   var
      Sock:     tDHCPSocket;
      SendPort: word16;
      SendIP:   word32;
   begin
      Sock:= tDHCPSocket( DHCPBuffer.DHCPSocket);

      // figure out where to send the packet
      if( DHCPBuffer.GatewayIPAddr.Value <> 0) then begin
         SendPort:= DHCPServerPortNumber;
         SendIP:=   DHCPBuffer.GatewayIPAddr.Value;
      end else begin
         SendPort:= DHCPClientPortNumber;
         SendIP:=   DHCPBuffer.GetRemoteIP;
         if( SendIP = 0) then begin
            SendIP:= $ffffffff;
         end;
      end;

      Sock.WritePacket( DHCPBuffer, SendIP, SendPort);
   end; // Send()



// ========================================================================
// = Global procedures
// ========================================================================
// *************************************************************************
// * InitializeMainThreads()
// *************************************************************************

procedure InitializeMainThreads();
   var
      Buffer:     tDHCPBuffer;
      i:          integer;
   begin
      // Create the containers
      AllBuffers:=    DoubleLinkedList.Create();
      ReadyBufferQ:=  tKentClassList.Create();
      BusyBufferQ:=   tKentClassList.Create();
      MainThreads:=   DoubleLinkedList.Create();
      RecieverThrdQ:= tKentClassList.Create();
      LookupThrdQ:=   tKentClassList.Create();

      // Create our DHCP packet buffers
      for i:= 1 to MaxQueueLength do begin
         Buffer:= tDHCPBuffer.Create();
         AllBuffers.Enqueue( Buffer);
         ReadyBufferQ.Enqueue( Buffer);
      end;

      // Start the DHCP packet reciever threads
      tRecieverThread.InitializeThreads();

   end; // InitializeMainThreads()


// *************************************************************************
// * FinalizeMainThreads()
// *************************************************************************

Procedure FinalizeMainThreads();
   var
      Buffer:   tDHCPBuffer;
      Thrd:     tKentProducerConsumerThread;
   begin
      // Wait for main threads to finish and then clean them up.
      while not MainThreads.Empty do begin
         Thrd:= tKentProducerConsumerThread( MainThreads.Dequeue());
         Thrd.Terminate();
         Thrd.Resume();
         Thrd.Waitfor();
//         Sleep( 3000);
         Thrd.Destroy();
      end;
     RecieverThrdQ.RemoveAll();
     LookupThrdQ.RemoveAll();

      // Clean up our Buffers
      ReadyBufferQ.RemoveAll();
      BusyBufferQ.RemoveAll();
      while not AllBuffers.Empty do begin
         Buffer:= tDHCPBuffer( AllBuffers.Dequeue);
         Buffer.Destroy();
      end;

      LookupThrdQ.Destroy();
      RecieverThrdQ.Destroy();
      MainThreads.Destroy();
      BusyBufferQ.Destroy();
      ReadyBufferQ.Destroy();
      AllBuffers.Destroy();
   end;  // FinalizeMainThreads();



// ========================================================================
// = Initialization and Finalization
// ========================================================================
// ************************************************************************

Initialization
   begin
      if( Debug_Unit_Initialization) then begin
         writeln( 'Initialization of lbp_dhcp_base_server started.');
      end;
      InitializeMainThreads();
      if( Debug_Unit_Initialization) then begin
         writeln( 'Initialization of lbp_dhcp_base_server ended.');
      end;
   end;


// ************************************************************************

finalization
   begin
      if( Debug_Unit_Initialization) then begin
         writeln( 'Finalization of lbp_dhcp_base_server started.');
      end;
      FinalizeMainThreads();
      if( Debug_Unit_Initialization) then begin
         writeln( 'Finalization of lbp_dhcp_base_server ended.');
      end;
   end;


// *************************************************************************

end. // lbp_dhcp_server
