{* ***************************************************************************

Copyright (c) 2019 by Lloyd B. Park

Filter the lines in a .csv file using regular expressions.

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

program csv_grep;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_csv,
   lbp_csv_filter,
   lbp_csv_io_filters;
   // lbp_parse_helper,
   // lbp_generic_containers,
   // lbp_input_file,
   // lbp_output_file,
   // regexpr;  // Regular expressions


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'csv_grep reads a CSV file and performs a grep on each field specified by the');
      InsertUsage( '      --headers parameter.  If the grep matches on any field the row is output');
      InsertUsage( '      If no fields are specified all fields are searched.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_grep [--header <header1,header2,...>] [-f <input file name>] [-o <output file name>] <regular expression>');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      InsertParam( ['g','grep-fields'], true, '', 'The comma separated list of header fields to be searched'); 
      InsertParam( ['i', 'ignore-case'], false, '', 'Perform a case insensitive search.');
      InsertParam( ['v', 'invert-match'], false, '', 'Output rows that do not match the pattern.');
      InsertUsage();

      ParseParams();
   end; // InitArgvParser();


// ************************************************************************
// * main()
// ************************************************************************

var
   GrepFields:   string;
   IgnoreCase:   boolean;
   InvertMatch:  boolean;
   GrepFilter:   tCsvGrepFilter;
   RegExpr:      string;
begin
   InitArgvParser();
   
   GrepFields:= GetParam( 'grep-fields');
   IgnoreCase:=  ParamSet( 'i');
   InvertMatch:= ParamSet( 'v');
   // Get the regular expression from the command line
   if( Length( UnnamedParams) <> 1) then begin
      lbp_argv.Usage( true, 'You must enter one and only one regular expression on the command line!');
   end;
   RegExpr:= UnnamedParams[ 0];
   GrepFilter:= tCsvGrepFilter.Create( GrepFields, RegExpr, InvertMatch, IgnoreCase);
   
   CsvFilterQueue.Queue:= CsvInputFilter;
   CsvFilterQueue.Queue:= GrepFilter;
   CsvFilterQueue.Queue:= CsvOutputFilter;
   CsvFilterQueue.Go();

   // Cleanup happens automatically in the  lbp_csv_filters unit.
end.  // csv_grep program
