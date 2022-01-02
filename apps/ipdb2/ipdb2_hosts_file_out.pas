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
   lbp_generic_containers,
   sysutils;


// ************************************************************************
// * Global Variables
// ************************************************************************
var
   PrefixLines: tStringList;
   HeaderLine:    string = '# ************************************************************************';
   HeaderLabel:   string = '# * IPdb2 Home hosts';
   HostsFileName: string;
   FullNode:      FullNodeQuery;
   FullAlias:     FullAliasQuery;
   Domains:       DomainsTable;


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
      PrefixLines:=  tStringList.Create();

      Domains:=      DomainsTable.Create();
      FullNode:=     FullNodeQuery.Create();
      FullAlias:=    FullAliasQuery.Create();     

{$ifdef WINDOWS}
      HostsFileName:= 'c:\windows\system32\drivers\etc\hosts';
{$else WINDOWS}
      HostsFileName:= '/etc/hosts';
{$endif WINDOWS}
   end; // Initialize()


// ************************************************************************
// * Finalize() - Clean up after ourselves
// ************************************************************************

procedure Finalize();
   begin
      Domains.Destroy;
      FullAlias.Destroy;
      FullNode.Destroy;

      PrefixLines.RemoveAll( False);
      PrefixLines.Destroy;
   end; // Finalize()


// ************************************************************************
// * ReadPrefix() - Read and store the host file in PrefixLines., Stop at 
// * the end of the file or at the first occurance of HeaderLine.Name
// ************************************************************************

procedure ReadPrefix();
   var
      Hosts: text;
      Line:  string = '';
      Done:  boolean = false;
   begin
      Assign( Hosts, HostsFileName);
      Reset( Hosts);

      while( (not Done) and (not EOF( Hosts))) do begin
         ReadLn( Hosts, Line);
         Done:= (Line = HeaderLine);
         if( not Done) then PrefixLines.Queue:= Line;
      end;

      Close( Hosts);
   end; // ReadPrifix()


// ************************************************************************
// * WritePrefix() - Write PrefixLines to the passed Hosts file
// ************************************************************************

procedure WritePrefix( var Hosts: Text);
   var 
      Line: string;
   begin
      for Line in PrefixLines do begin
         Writeln( Hosts, Line);
      end;  
      writeln( Hosts, HeaderLine);
      Writeln( Hosts, HeaderLabel);
   end; // WritePrefix()


// ************************************************************************
// * WriteDomain() - Write the hosts in a single passed domain to 
// *  the Hosts file (Or OUTPUT if the user doesn't have write permissions)
// ************************************************************************

procedure WriteDomain( DomainID: string; var HostsFile: Text);
   begin
      FullNode.Query( 'and NodeInfo.DomainID = ' + DomainID + ' order by CurrentIP');
      while( FullNode.Next) do begin
         writeln( HostsFile, FullNode.CurrentIP.GetValue, '   ', FullNode.FullName);
      end;

      FullAlias.Query( 'and Aliases.DomainID = ' + DomainID + ' order by CurrentIP');
      while( FullAlias.Next) do begin
         writeln( HostsFile, FullAlias.CurrentIP.GetValue, '   ', FullAlias.FullName);
      end;
   end; // WriteDomain()


// ************************************************************************
// * OutputHosts()
// ************************************************************************

procedure OutputHosts();
   var
      HostsFile:  text;
      Opened:     boolean = false;
      DomainID:   string;
   begin
      ReadPrefix();

      // Attempt to re-open the hosts file in write mode
      try
         Assign( HostsFile, HostsFileName);
         Rewrite( HostsFile);
         Opened:= true;
      except
      end;

      if( Opened) then WritePrefix( HostsFile) else WritePrefix( OUTPUT);

      Domains.Query();
      while( Domains.Next) do begin
         DomainID:= Domains.ID.GetValue;
         if( Opened) then begin
            WriteDomain( DomainID, HostsFile);
         end else begin
            WriteDomain( DomainID, OUTPUT);
         end;
      end;

      if( Opened) then Close( HostsFile);
   end; // OutputHosts()


// ************************************************************************
// * main()
// ************************************************************************

begin
   Initialize;

   OutputHosts();

   Finalize;
end.  // ipdb2_hosts_file_out program
