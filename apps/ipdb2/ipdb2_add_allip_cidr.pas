{* ***************************************************************************

    Copyright (c) 2020 by Lloyd B. Park

    ipdb2_add_allip_cidr - Fills the IPdb2 AllIP table with every host IP
    in the passed CIDR.

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

program ipdb2_add_allip_cidr;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   ipdb2_home_config,
   ipdb2_tables,
   lbp_ip_network, 
   sysutils;


// ************************************************************************
// * Global Variables
// ************************************************************************
var
   AllIP:     AllIPTable;
   DoInsert:  Boolean = false;   // See Main() at the bottom of this file
   Cidr:      string;


// ************************************************************************
// * AddRange() - Add dynamic records to IPdb2
// ************************************************************************

procedure AddRange( Cidr: string);
   var
      i:        word32;
      StartIP:  word32;
      EndIP:    word32;
      NetInfo:  tNetworkInfo;
   begin
      NetInfo:= tNetworkInfo.Create();
      NetInfo.Cidr:= Cidr;
      StartIp:= NetInfo.NetNum + 1;
      EndIp:=   NetInfo.Broadcast - 1;

      for i:= StartIP to EndIP do begin
         AllIP.ID.SetValue( 0);
         AllIP.IP.SetValue( i);
         writeln( 'Adding ', AllIP.IP.Getvalue);
         try
            if DoInsert then AllIP.Insert();
         except
            On E: Exception do begin
               writeln( '   ', E.Message);
            end;
         end; // try/except
      end; // for

      NetInfo.Destroy;
   end; // AddRange()


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'ipdb2_add_allip_cidr adds all the available host IPs in a CIDR to the');
      InsertUsage( '         AllIP table in IPdb2.  This allows the Gui to show available');
      InsertUsage( '         IPs in a range.');
      InsertUsage( 'You must pass a CIDR as a parameter to this program.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   ipdb2_add_allip_cidr [options] <CIDR>');
      InsertUsage( '');
      InsertUsage();
      ParseParams();
   end;


// ************************************************************************
// * main()
// ************************************************************************

begin
   DoInsert:= true;
   InitArgvParser;
   
   if( Length( UnnamedParams) = 0) then raise lbp_exception.Create( 'You must enter at least one CIDR as a parameter on the command line!');

   AllIP:= AllIPTable.Create();
   
   for Cidr in UnnamedParams do AddRange( Cidr);

   AllIP.Destroy();
end. // add_edge_allipend; // ipdb2_add_allip_cidr program
