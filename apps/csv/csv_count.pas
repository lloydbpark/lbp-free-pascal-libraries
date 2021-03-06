{* ***************************************************************************

Copyright (c) 2019 by Lloyd B. Park

Output's the number of rows in a .csv file.

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

program csv_count;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_csv,
   lbp_parse_helper,
   lbp_generic_containers,
   lbp_input_file;

var
   Csv:                tCsv;


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'csv_count reads a CSV file and returns the number of rows found excluding the');
      InsertUsage( '      header.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_grep [-f <input file name>] [-d <delimiter character>');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      SetInputFileParam( true, true, false, true);
      InsertParam( ['d', 'id','input-delimiter'], true, ',', 'The character which separates fields on a line.'); 
      InsertUsage();
      ParseParams();
   end; // InitArgvParser();


// ************************************************************************
// * main()
// ************************************************************************

var
   Row:      tCsvCellArray;
   RowCount: integer = 0;
   c:    char;
begin
   InitArgvParser();

   // Open input CSV
   Csv:= tCsv.Create( lbp_input_file.InputStream, False);

   // Skip the header
   Csv.ParseHeader();
 
   // Process the input CSV
   repeat
      Row:= Csv.ParseRow();
      C:= Csv.PeekChr();
      if(Length( Row) > 0) then inc( RowCount);
   until( C = EOFchr);

   writeln( RowCount);
   Csv.Destroy;

end.  // csv_count program
