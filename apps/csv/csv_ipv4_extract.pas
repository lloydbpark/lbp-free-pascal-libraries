{* ***************************************************************************

Copyright (c) 2019 by Lloyd B. Park

Some CSV files include other data in the same field as the IPv4 address.  This 
program takes the required single header/column name where the fields containing 
embedded IPv4 addresses are located and either replaces each field with just the
address or stores the address in a new column whose names is specified by the 
user.

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

program csv_ipv4_extract;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_csv,
   lbp_csv_filter,
   lbp_csv_io_filters;


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'Some CSV files include other data in the same field as the IPv4 address.  This');
      InsertUsage( 'program takes the required single header/column name where the fields containing');
      InsertUsage( 'embedded IPv4 addresses are located and either replaces each field with just the');
      InsertUsage( 'address or stores the address in a new column whose names is specified by the');
      InsertUsage( 'user.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_ipv4_extract [--header <header name>] [<new ipv4 header name>]'); 
      InsertUsage( '                    [-f <input file name>] [-o <output file name>]');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      InsertParam( ['h','header'], true, '',      'The single column name which contains the');
      InsertUsage( '                                 input fields'); 
      InsertUsage();

      ParseParams();  // parse the command line
   end; // InitArgvParser();


// ************************************************************************
// * main()
// ************************************************************************

var
   OldHeader:         string;
   NewHeader:         string = '';
   L:                 integer;  // Length of UnnamedParams
   ExtractIPv4Filter: tCsvExtractIPv4Filter;
begin
   // Handle the command line arguments
   InitArgvParser();
   if( not ParamSet( 'header')) then begin
      Usage( true, 'The ''-h'' or ''--header'' parameter is required!');
   end;
   OldHeader:= GetParam( 'header');
   L:= Length( UnnamedParams);
   if( L > 1) then begin
      Usage( True, 'Unknown parameter ''' + UnnamedParams[ 1] + 
             ''' on the command line!');
   end;
   if( L = 1) then NewHeader:= UnnamedParams[ 0];

   ExtractIPv4Filter:= tCsvExtractIPv4Filter.Create( OldHeader, NewHeader);
   
   CsvFilterQueue.Queue:= CsvInputFilter;
   CsvFilterQueue.Queue:= ExtractIPv4Filter;
   CsvFilterQueue.Queue:= CsvOutputFilter;
   CsvFilterQueue.Go();

   // Cleanup happens automatically in the  lbp_csv_filters unit.
end.  // csv_ipv4_extract program
