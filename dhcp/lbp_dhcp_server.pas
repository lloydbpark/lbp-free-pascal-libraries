{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

An ipv4 DHCP server whose host configuration is in Kent State's old IPdb

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

program lbp_dhcp_server;

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   cthreads,       // Thread driver: must be first in uses clause!
   lbp_run_once,
   lbp_keep_running,
   lbp_cron,
   lbp_dhcp_subnets,
   lbp_dhcp_ipdb2_lookup;


// *************************************************************************
// * Main()
// *************************************************************************

var
   KR:  tKeepRunningCron;
begin
   KR:= tKeepRunningCron.Create();
   KR.Destroy;

   StartCron( true);
end. // lbp_dhcp_server
