{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

test lbp_cron

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

program TestCron;

{$include lbp_standard_modes.inc}

uses
   cthreads,  // Enables threading.  Must be first in uses clause.
   dateutils,
   sysutils,
   lbp_current_time,
   lbp_Cron,
//   lbp_unix_cron,
//   lbp_dhcp_buffer,
   lbp_Log;
//   lbp_utils,  // Only for testing the IP conversion routines...
//   lbp_Signal_Handlers;

type
   TwoCron = class( tCronJob)
      public
         procedure DoEvent(); override;
      end;
   TenCron = class( tCronJob)
      public
         procedure DoEvent(); override;
      end;
   tStopCronJob = class( tCronJob)
      public
         procedure DoEvent(); override;
      end;


procedure TwoCron.DoEvent();
   begin
      Log( LOG_DEBUG, 'Every two seconds job triggered.');
   end;

procedure TenCron.DoEvent();
   var
      i: integer;
   begin
      Log( LOG_DEBUG, 'One shot ten second job triggered.');
      i:= 1;
//      while( not Terminated) do begin
//         writeln( 'TenCron.DoEvent():  ', i);
         inc( i);
//      end;
   end;
procedure tStopCronJob.DoEvent();
   begin
      StopCron;
   end;

var
   Every2Secs:    tCronJob;
   In10Secs:      tCronJob;
   StopCronJob:   tCronJob;

begin
   Every2Secs:= TwoCron.Create( 0, 2);
   In10Secs:=   TenCron.Create( IncMillisecond( CurrentTime.TimeOfDay, 10 * 1000), 0);
   StopCronJob:= tStopCronJob.Create( 0, 15);

   LogLevel:= LOG_DEBUG;
   Log( LOG_DEBUG, 'Starting CRON test');
   Log( LOG_DEBUG, '   Test will end in 15 seconds.');
   StartCron();

//   Log( LOG_DEBUG, '   Before Every2Sec.Destroy.');
   Every2Secs.Destroy();
//   Log( LOG_DEBUG, '   Before In10Secs.Destroy.');
   In10Secs.Destroy();
//   Log( LOG_DEBUG, '   Before StopCronJob.Destroy.');
   StopCronJob.Destroy();

   Log( LOG_DEBUG, 'CRON test finished!');
end.
