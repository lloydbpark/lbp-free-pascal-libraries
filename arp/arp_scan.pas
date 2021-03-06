{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

attempts to ARP a list of IPs periodicaly. 

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

program arp_scan;

// ************************************************************************
{$include lbp_standard_modes.inc}


var
   ARParray: array of tARPInfo;  // A list of all the IPs which need scanned.
   ScanQ:   DoubleLinkedList;  // A list of IPs which are enqueued to be scanned at a certain time.
   RetryInterval:  Word32; // 500 milliseconds.
   ArpInterval:    word32; // 10 milliseconds (100 arps per second 
   
      
   
{  Every X milliseconds
   EndIndex:= Length( ARParray) - 1;
   CurrentIndex:= 0;
   Done:= false;
   While( not (Done and ScanQ.Empty)) do begin
      Found:= false;
      if( not ScanQ.Empty) do begin
         A:= ScanQ.Dequeue;
         if( (A.NextRetry <= Now) and (A.Tries > 0) and (A.MAC = 0)) then begin
            Decr( A.Tries);
            A.NextRetry:= Now + RetryInterval;
            ScanQ.Enqueue( A);
            Found:= true;
            SendARP( A);
         end;
      end;
   
      if( not Found) then begin
         A:= ARPArray[ CurrentIndex];
         Decr( A.Tries);
         A.NextRetry:= Now + RetryInterval;
         ScanQ.Enqueue( A);
         Inc( CurrentIndex);
         SendARP( A);
      end;
      WaitFor( ArpInterval);
   end; // while we are not done processing
   
   // Allow the last ARP response time to return
   WaitFor( RetryInterval - ARPInterval)
}            
   {$WARNING process the results}

end.  arp_scan;
