{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Sends periodic DHCP requests - part of the test client program

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

unit lbp_dhcp_client_cron;

// Contains the cron jobs which send the initial DHCP requests every few
// seconds and schedules the end of the test. 
// 
// To use this unit, you must add this line to your program:
//     CronThread:= tCronThread.Create( DHCPSocket);
//   (DHCPSocket is created and initilized in the lbp_dhcp_client_ini unit.)
// Poll CronThread.Done inside the main loop
// Call CronThread.WaitFor after exiting the main loop just to be sure.
// Display the results
// Call CronThread.Destroy();

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

{$WARNING We may want to change this.}
{$define FPC_LINK_STATIC}

uses
   lbp_dhcp_buffer,
   lbp_dhcp_fields,
   lbp_dhcp_socket,
   lbp_current_time,
   lbp_dhcp_client_ini,
   lbp_cron,
   lbp_types,
   lbp_ip_utils,
   lbp_log,
   sysutils,            // Exception
   dateutils,
   classes;             // tThread


// *************************************************************************
// * tSendCron - Cron job which sends DHCP requests
// *************************************************************************

type
   tSendCron = class( tCronJob)
      private
         MyBuffer:  tDHCPBuffer;
         MySocket:  tDHCPSocket;
      public
         constructor   Create( DHCPSocket: tDHCPSocket; iEventTime: tDateTime; iInterval: integer);
         destructor    Destroy(); override;
         procedure DoEvent(); override;
      end;


// *************************************************************************
// * tTimeoutCron - Cron job which stops the send/recieve loop
// *************************************************************************

type
   tTimeoutCron = class( tCronJob)
      public
         procedure DoEvent(); override;
      end;


// *************************************************************************
// * tTimeStampCron - A cron job which just logs a timestamp once per second
// *************************************************************************

type
   tTimeStampCron = class( tCronJob)
      public
         procedure DoEvent(); override;
      end;


// *************************************************************************
// * tCronThread - A thread which executes our cron jobs.
// *************************************************************************

type
   tCronThread = class( tThread)
      public
         
         SendCron:         tSendCron;
         TimeoutCron:      tTimeoutCron;
         TimeStampCron:    tTimeStampCron;
         Done:             boolean;
         constructor       Create( DHCPSocket: tDHCPSocket);
         destructor        Destroy(); override;
         procedure         Execute(); override;
      end; // tCronThread

// *************************************************************************

var
   CronThread:    tCronThread; 


// *************************************************************************

implementation

// *************************************************************************

// =========================================================================
// = tCronThread
// =========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCronThread.Create( DHCPSocket: tDHCPSocket);
   var
      StopTime:       tDateTime;
   begin
      Done:= false;
      SendCron:= tSendCron.Create( DHCPSocket, 0, QueryPeriod);        // Every 2 seconds
      TimeStampCron:= tTimeStampCron.Create( 0, 1);
      StopTime:= IncMillisecond( CurrentTime.TimeOfDay, TimeOut * 1000);
      TimeoutCron:= tTimeoutCron.Create( StopTime, 0);
      inherited Create( false);
   end; // Create()


// *************************************************************************
// * Destroy() - destructor
// *************************************************************************
destructor tCronThread.Destroy();
   begin
      SendCron.Destroy();
      TimeoutCron.Destroy();
      TimeStampCron.Destroy();
      inherited Destroy();
   end;  // Destroy()


// *************************************************************************
// * Execute() - Run the cron jobs
// *************************************************************************

procedure tCronThread.Execute();
   begin
      try
         SendCron.DoEvent();
         StartCron();
      except 
         on E: Exception do begin
            Log( LOG_DEBUG, E.Message);
         end; 
      end; // try/except
      Terminate();  // Not really needed.
      Done:= true;
   end; // Execute



// =========================================================================
// = tSendCron
// =========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tSendCron.Create( DHCPSocket: tDHCPSocket; iEventTime: tDateTime; iInterval: integer);
   begin
      MySocket:= DHCPSocket;
      MyBuffer:= tDHCPBuffer.Create();
      MyBuffer.RawMode:= true;
      inherited Create( iEventTime, iInterval);
   end; // Create()


// *************************************************************************
// * Destroy() - destructor
// *************************************************************************

destructor tSendCron.Destroy();
   begin
      MyBuffer.Destroy();
      inherited Destroy();
   end; // Destroy()


// *************************************************************************
// * DoEvent() - Send DHCP packets out our interfaces.
// *************************************************************************

procedure tSendCron.DoEvent();
   var
      S:  tServerInfo;
   begin
      if( QueryCount <= 0) then begin
         Interval:= 0;
         exit;
      end;
      dec( QueryCount);

      // Clear the sent request flag for every server
      S:= tServerInfo( ServerTree.GetFirst);
      while( S <> nil) do begin
         S.SentReq:= false;
         S:= tServerInfo( ServerTree.GetNext);
      end;

      with MyBuffer do begin
         EthHdr.SrcMAC.StrValue:= MACWord64ToString( InterfaceInfo.MAC);
         EthHdr.DstMAC.StrValue:= 'ffff.ffff.ffff';
         IPHdr.SrcIP.StrValue:= '0.0.0.0';
         IPHdr.DstIP.StrValue:= '255.255.255.255';
         IPHdr.IPLength.Value:= 32;
         UDPHdr.SrcPort.Value:= DHCPClientPortNumber;
         UDPHdr.DstPort.Value:= DHCPServerPortNumber;

         OpCode.Value:= BootRequestOp;
         HardwareType.Value:= EthernetHWType;
         HardwareAddressLength.Value:= EthernetHWLength;
         Hops.Value:= 0;
         TransactionID.Value:= 1875432;
         SecondsElapsed.Value:= 0;
         Flags.Value:= 0;
         ClientSuppliedIPAddr.Value:= 0;
         ClientIPAddr.Value:= 0;
         ServerIPAddr.Value:= 0;
         GatewayIPAddr.Value:= 0;
         ClientHardwareAddress.StrValue:= MACWord64ToString( InterfaceInfo.MAC);
         ServerName.SetStrValue( '');
         BootFile.SetStrValue( '');
         MajicCookie.Clear();
         AddBaseFields;

         DHCPOpCode.Value:= dhcpDiscover;
         ClientIdentifier.StrValue:= MACWord64ToString( InterfaceInfo.MAC);
         HostName.SetStrValue( 'lbp_dhcp_test');
         VendorClass.SetStrValue( 'lbp_dhcp_test');
         ParameterRequestList.Value[ 0]:= 1;
         ParameterRequestList.Value[ 1]:= 15;
         ParameterRequestList.Value[ 2]:= 3;
         ParameterRequestList.Value[ 3]:= 6;
         ParameterRequestList.Value[ 4]:= 44;
         ParameterRequestList.Value[ 5]:= 46;
         ParameterRequestList.Value[ 6]:= 47;
         ParameterRequestList.Value[ 7]:= 32;
         ParameterRequestList.Value[ 8]:= 33;
         DataEnd.Clear;

         Fields.Enqueue( DHCPOpCode);
         Fields.Enqueue( ClientIdentifier);
         Fields.Enqueue( HostName);
         Fields.Enqueue( VendorClass);
         Fields.Enqueue( ParameterRequestList);
         Fields.Enqueue( DataEnd);
      end;

      MyBuffer.Encode;
      MySocket.WritePacket( MyBuffer);
      MyBuffer.LogFullPacket();
      Log( LOG_DEBUG, '------');
   end; // DoEvent()


// =========================================================================
// = tTimeoutCron
// =========================================================================
// *************************************************************************
// * DoEvent() - Stop the program
// *************************************************************************

procedure tTimeoutCron.DoEvent();
   begin
      StopCron;
   end; // DoEvent()


// =========================================================================
// = tTimeStampCron
// =========================================================================
// *************************************************************************
// * DoEvent() - Display a timestamp once per second
// *************************************************************************

procedure tTimeStampCron.DoEvent();
   begin
      Log( LOG_DEBUG, 'TimeStampCron triggered.');
   end; // DoEvent()


// ************************************************************************

end. // lbp_dhcp_client_cron unit
