{* ***************************************************************************

    Copyright (c) 2020 by Lloyd B. Park

    ipdb2_dns_dhcp_config_out - Outputs the ISC DHCP and BIND9 configuration 
    files to the user's XDG cache folder under the lbp\ipdb2\dns-dhcp-config
    folder.

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

program ipdb2_dns_dhcp_config_out;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   ipdb2_dns_dhcp_config_classes,
   sysutils;


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'ipdb2_dns_dhcp_config_out output''s the ISC Bind and DHCP configuration from');
      InsertUsage( '         the IPdb2 database.');
      InsertUsage();
      InsertUsage( 'You must pass the input file name through the -f parameter or pipe the file to');
      InsertUsage( '         this program.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   ipdb2_dns_dhcp_config_out [options]');
      InsertUsage( '');
      InsertUsage();
      ParseParams();
   end;


// ************************************************************************
// * main()
// ************************************************************************

begin
   InitArgvParser();
   
   Domains.OutputConfigs( NamedConf);
   IpRanges.OutputConfigs( DhcpdConf, NamedConf);
   MoveFilesAndRestartServices;
end. // ipdb2_dns_dhcp_config_out program
