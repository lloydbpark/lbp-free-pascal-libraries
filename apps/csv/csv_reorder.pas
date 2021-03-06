{* ***************************************************************************

Copyright (c) 2019 by Lloyd B. Park

Outputs only the passed list of header fields of the input CSV file in the
same order as the passed header.

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

program csv_reorder;

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
      InsertUsage( 'csv_reorder reads a CSV file and outputs it out again with only the columns');
      InsertUsage( '         specified in the --order parameter and in the order they are');
      InsertUsage( '         specified.  New empty columns can also be added if the --allow-new');
      InsertUsage( '         command line option is used.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_reorder [--header] [-f <input file name>] [-o <output file name>]');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      InsertParam( ['h','header'], true, '', 'The comma separated list of column names'); 
      InsertParam( ['a', 'allow-new'], false, '', 'Allow new header fields to be created.  The');
      InsertUsage( '                                 associated new field''s value in each row');
      InsertUsage( '                                 will be empty.');
      InsertUsage();

      ParseParams();  // parse the command line
   end; // InitArgvParser();


// ************************************************************************
// * main()
// ************************************************************************

var
   NewHeader:     string;
   AllowNew:      boolean;
   ReorderFilter: tCsvReorderFilter;
begin
   InitArgvParser();
   
   NewHeader:= GetParam( 'header');
   AllowNew:=  ParamSet( 'allow-new');
   ReorderFilter:= tCsvReorderFilter.Create( NewHeader, AllowNew);
   
   CsvFilterQueue.Queue:= CsvInputFilter;
   CsvFilterQueue.Queue:= ReorderFilter;
   CsvFilterQueue.Queue:= CsvOutputFilter;
   CsvFilterQueue.Go();

   // Cleanup happens automatically in the  lbp_csv_filters unit.
end.  // csv_reorder program
