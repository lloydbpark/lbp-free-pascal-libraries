{* ***************************************************************************

Copyright (c) 2019 by Lloyd B. Park

The csv_reformat_embedded_csv program attempt will reformat each cell in a 
column which might itself hold multi-element data in a CSV format.  The
delimiter used in the input data may be a single character value and may be
set with the --cid parameter.  The multi-element data will be re-output using
the output delimiter which may be set with the --cod parameter.  By default
the cid parameter is a comma and the cod is the default new line character(s)

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

program csv_fix_zeros;

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
      InsertUsage( 'The csv_reformat_embedded_csv program attempt will reformat each cell in a');
      InsertUsage( 'column which might itself hold multi-element data in a CSV format.  The');
      InsertUsage( 'delimiter used in the input data may be a single character value and may be');
      InsertUsage( 'set with the --cid parameter.  The multi-element data will be re-output using');
      InsertUsage( 'the output delimiter which may be set with the --cod parameter.  By default');
      InsertUsage( 'the cid parameter is a comma and the cod is the default new line character(s)');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_reformat_embedded_csv -h <field names> [--cid <input delimiter>] [--cod <output delimiter>] [-f <input file name>] [-o <output file name>]');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      InsertParam( ['h','header'], true, '', 'The comma separated list of column names to check'); 
      InsertParam( ['cid'], true, '', 'The input delimiter character for the embedded');
      InsertUsage( '                                 CSV');
      InsertParam( ['cod'], true, '', 'The output delimiter character for the embedded');
      InsertUsage( '                                 CSV');
      InsertUsage();

      ParseParams();  // parse the command line
   end; // InitArgvParser();


// ************************************************************************
// * main()
// ************************************************************************

var
   MyFields:        string;
   ReformatFilter:  tCsvReformatEmbeddedCsvFilter;
begin
   InitArgvParser();
   
   MyFields:= GetParam( 'header');
   ReformatFilter:= tCsvReformatEmbeddedCsvFilter.Create( MyFields);
   
   CsvFilterQueue.Queue:= CsvInputFilter;
   CsvFilterQueue.Queue:= ReformatFilter;
   CsvFilterQueue.Queue:= CsvOutputFilter;
   CsvFilterQueue.Go();

   // Cleanup happens automatically in the  lbp_csv_filters unit.
end.  // csv_fix_zeros program
