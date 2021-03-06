{* ***************************************************************************

    Copyright (c) 2020 by Lloyd B. Park

    ipdb2_dns_dhcp_config_out - Outputs the passed IPdb2 Domain's Nodes and
    Aliases in /etc/hosts format.

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

program ipdb2_hosts_file_out;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   ipdb2_home_config,
   ipdb2_tables,
   ipdb2_flags,
   sysutils;


// ************************************************************************
// * Global Variables
// ************************************************************************
var
   FullNode:    FullNodeQuery;
   FullAlias:   FullAliasQuery;
   Domains:     DomainsTable;
   DomainName:  string;
   DomainID:    string; // The domain ID number as a string

// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'ipdb2_hosts_file_out output''s the passed IPdb2 Domain''s Nodes and ');
      InsertUsage( '         aliases in /etc/hosts format.');
      InsertUsage( 'You must pass domain name as an parameter to the program.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   ipdb2_hosts_file_out [options] <domain-name>');
      InsertUsage( '');
      InsertUsage();
      ParseParams();
   end;


// ************************************************************************
// * Initialize() - setup variables and the argv system
// ************************************************************************

procedure Initialize();
   begin
      InitArgvParser();

      If( Length( UnnamedParams) <> 1) then raise lbp_exception.Create( 'You must enter the DNS domain you wish to output as a command line parameter!');
      DomainName:= UnnamedParams[ 0];

      Domains:=   DomainsTable.Create();
      FullNode:=  FullNodeQuery.Create();
      FullAlias:= FullAliasQuery.Create();     
   end; // Initialize()


// ************************************************************************
// * Finalize() - Clean up after ourselves
// ************************************************************************

procedure Finalize();
   begin
      Domains.Destroy;
      FullAlias.Destroy;
      FullNode.Destroy;
   end; // Finalize()


// ************************************************************************
// * main()
// ************************************************************************

begin
   Initialize;

   Domains.Query( 'where Name = "' + DomainName + '"');
   if( not Domains.Next) then raise lbp_exception.Create( 'The domain "' + DomainName + '" was not found in IPdb2!');
   DomainID:= Domains.ID.GetSQLValue;

   FullNode.Query( 'and NodeInfo.DomainID = ' + DomainID + ' order by CurrentIP');
   while( FullNode.Next) do begin
      writeln( FullNode.CurrentIP.GetValue, '   ', FullNode.FullName);
   end;

   FullAlias.Query( 'and Aliases.DomainID = ' + DomainID + ' order by CurrentIP');
   while( FullAlias.Next) do begin
      writeln( FullAlias.CurrentIP.GetValue, '   ', FullAlias.FullName);
   end;

   Finalize;
end.  // ipdb2_hosts_file_out program
