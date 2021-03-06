{* ***************************************************************************

    Copyright (c) 2020 by Lloyd B. Park

    ipdb2_home_import_csv - This is a one-shot program to import a spreadsheet
    of IP address information into a database.  IPdb2 is an old project
    written in Java whe Java was fairly new.  It provides a GUI to manage
    IP addresses and output DNS/DHCP configuration files.  I'm now using it
    at home.

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

program ipdb2_home_import_csv;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_sql_db,  // SQL Exceptions
   ipdb2_home_config,
   ipdb2_tables,
   lbp_ip_utils,
   lbp_input_file,
   lbp_csv;

var
   Csv:              tCsv;
   Cells:            tCsvCellArray;
   NodeInfo:         NodeInfoTable;
   Aliases:          AliasesTable;
   AllIP:            AllIPTable;
   ParkHomeDomainID: word64 = 5;
   la_parkDomainID:  word64 = 3; 
   DeptID:           word64 = 1;
   EcUnknownID:      word64 = 1;
   EcPrinterID:      word64 = 18;
   EcVMServerID:     word64 = 16;
   EcVMDesktopID:    word64 = 15;
   EcTabletID:       word64 = 14;
   EcPhoneID:        word64 = 13;
   EcDesktopID:      word64 = 11;
   EcLaptopID:       word64 = 12;
   EcIOTID:          word64 = 19;
   EcNetworkID:      word64 = 20;
   EcServerID:       word64 = 22;


// ************************************************************************
// * GetEquipCategory() - Given the string returns the ID number
// ************************************************************************

function GetEquipCategory( EC: string): word64;
   begin
      if( EC = 'Printer') then result:= ecPrinterID else
      if( EC = 'VM Server') then result:= ecVMServerID else
      if( EC = 'VM Desktop') then result:= ecVMDesktopID else
      if( EC = 'Tablet') then result:= ecTabletID else
      if( EC = 'Phone') then result:= ecPhoneID else
      if( EC = 'Desktop') then result:= ecDesktopID else
      if( EC = 'Laptop') then result:= ecLaptopID else
      if( EC = 'IOT') then result:= ecIOTID else
      if( EC = 'Network') then result:= ecNetworkID else
      if( EC = 'Server') then result:= ecServerID else
      result:= EcUnknownID;
   end; // GetEquipCategory()


// ************************************************************************
// * AddLaParkNode() - Add the passed Cells as NodeInfo records to the 
// *                   la-park.org domain
// ************************************************************************

procedure AddLaParkNode( Cells: tCsvCellArray);
   begin
      if( Cells[ 0] = '2') then exit;
      if( Cells[ 0] = '3') then exit;
      if( Cells[ 8] = 'in storage') then exit;
      if( Cells[ 8] = 'retired') then exit;
      NodeInfo.Clear();
      NodeInfo.Name.SetValue( Cells[ 1]);
      NodeInfo.HomeIP.SetValue( Cells[ 2]);
      NodeInfo.CurrentIP.SetValue( Cells[ 2]);
      NodeInfo.NIC.SetValue( Cells[ 3]);
      NodeInfo.SwitchPortID.SetValue( GetEquipCategory( Cells[ 9]));      
      NodeInfo.Notes.SetValue( Cells[ 10]);
      NodeInfo.Flags.SetValue( 5);
      NodeInfo.DeptID.SetValue( DeptID);
      NodeInfo.DomainID.SetValue( la_parkDomainID);
      try
         NodeInfo.Insert;
      except   
         on e: SqlDbException do begin
            write( NodeInfo.CurrentIP.GetValue, '  ', NodeInfo.Name.GetValue, '');
            writeln( e.Message);
         end;
      end; // try/except
//      writeln( NodeInfo.GetSQLInsert);
   end; // AddLaParkNode()

// ************************************************************************
// * AddParkHome() - Add an Alias record in park.home pointing to the 
// *                 current la-park.org record in NodeInfo.
// ************************************************************************

procedure AddParkHome();
   var
      Proceed: boolean = false;
   begin
      if( NodeInfo.SwitchPortID.OrigValue = 18) then Proceed:= true;
      if( NodeInfo.SwitchPortID.OrigValue = 16) then Proceed:= true;
      if( NodeInfo.SwitchPortID.OrigValue = 19) then Proceed:= true;
      if( NodeInfo.SwitchPortID.OrigValue = 20) then Proceed:= true;
      if( NodeInfo.SwitchPortID.OrigValue = 22) then Proceed:= true;
      if( not Proceed) then exit;

      Aliases.Clear;
      Aliases.Name.SetValue( NodeInfo.Name.GetValue);  
      Aliases.DomainID.SetValue( ParkHomeDomainID);
      Aliases.NodeID.SetValue( NodeInfo.ID.GetValue);
      Aliases.Notes.SetValue( NodeInfo.Notes.GetValue);
      Aliases.Flags.SetValue( 1);
      try
         Aliases.Insert();
      except
         on e:SqlDbException do begin
            write( NodeInfo.Name.GetValue, '');
            writeln( e.Message);
         end;
      end; // try/except
   end; // AddParkHome()


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'ipdb2_home_import_csv is a one-shot program to import IP address information');
      InsertUsage( '         from a CSV file into the IPdb2 database I am implementing at home for');
      InsertUsage( '         my work/home testbed.');
      InsertUsage();
      InsertUsage( 'You must pass the input file name through the -f parameter or pipe the file to');
      InsertUsage( '         this program.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   ipdb2_home_import_csv [options]');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      SetInputFileParam( true, true, false, true);
      InsertUsage();
      ParseParams();
   end;



// ************************************************************************
// * Initialize
// ************************************************************************

procedure Initialize();
   begin
      InitArgvParser();
      NodeInfo:= NodeInfoTable.Create();
      Aliases:=  AliasesTable.Create();
      AllIP:=    AllIPTable.Create();

      Csv:= tCsv.Create( InputFile);
      Csv.ParseHeader;
   end; // Initialize()


// ************************************************************************
// * Finalize
// ************************************************************************

procedure Finalize();
   begin
      Csv.Destroy;
      AllIP.Destroy;
      Aliases.Destroy;
      NodeInfo.Destroy;
   end; // Finalize()


// ************************************************************************
// * main()
// ************************************************************************

begin
   Initialize();

   // Initial import to la-park.org from the CSV file
   Cells:= Csv.ParseRow;
   while( Length( Cells) > 0) do begin
//      AddLaParkNode( Cells);
      Cells:= Csv.ParseRow;
   end;

   // Now duplicate many of the names in park.home
   NodeInfo.Query();
   while( NodeInfo.Next) do begin
      AddParkHome();
   end;

   Finalize();
end. // ipdb2_home_import_csv program
