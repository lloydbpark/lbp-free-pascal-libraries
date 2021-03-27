{* ***************************************************************************

Copyright (c) 2021 by Lloyd B. Park

Converts a Excel .xlsx file to a Comma Separated Value fileOutputs only the passed list of header fields of the input CSV file in the
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

program xlsx_to_csv;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_csv,
   lbp_output_file,
   fpstypes,
   fpspreadsheet,
   xlsxooxml, // Excel 2007 and later.  dot xmlx files
   fpscsv; // Comma Separated Value support for fsspreadsheet


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      SetOutputFileParam( false, true, true, true);
      InsertUsage( '');
      InsertUsage( 'xlsx_to_csv reads an XLSX and outputs it the the first sheet or the one');
      InsertUsage( '         specified on the command line as a CSV file.  By defualt the source');
      InsertUsage( '         is standard input and the result is output to standard output.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   xlsx_to_csv [-s <sheet name>] [-f <input file name>] [-o <output file name>]');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      InsertParam( ['x', 'xls'], true, '', 'The name of the Excel .xlsx file to be converted.');
      InsertParam( ['s', 'sheet'], true, '', 'Specifiy the sheet in the workbook to convert to');
      InsertUsage( '                                 CSV.  By default the first sheet is converted.');
      InsertParam( ['l', 'list'], false, '', 'List the names of the sheets in the input');
      InsertUsage( '                                 workbook instead of converting toCSV.');
      InsertUsage();

      ParseParams();  // parse the command line
   end; // InitArgvParser();


// ************************************************************************
// * OutputSheetNames() - Output all the sheet names in the workbook.
// ************************************************************************

procedure OutputSheetNames( var W: tsWorkbook);
   var
      S:    tsWorkSheet;
      i:    integer;
      iMax: integer;
   begin
      iMax:= W.GetWorksheetCount -1;
      for i:= 0 to iMax do begin
         S:= W.GetWorksheetByIndex( i);
         Writeln( S.Name);
      end;
   end; // OutputSheetNames()


// ************************************************************************
// * Convert()
// ************************************************************************

procedure Convert( W: tsWorkbook);
   begin
      // Change the default sheet if the user asked for a different one
      if( ParamSet( 's')) then begin
         CSVParams.SheetIndex:= W.GetWorksheetIndex( GetParam( 's'));
         if( CSVParams.SheetIndex < 0) then begin
            raise tCsvException.Create( 'The sheet ''%s'' was not found!', 
                     [ GetParam( 's')]);
         end;
      end; // if ParamSet
      CSVParams.Delimiter:= ',';

      W.WriteToStream( OutputStream, sfCSV);
   end; // Convert()


// ************************************************************************
// * main()
// ************************************************************************

var
   W:    tsWorkbook;
begin
   InitArgvParser();

   if( not ParamSet( 'x')) then begin
      Usage( true, 'You must specify the file name of the Excel .xlsx file!');
   end;

   W:= tsWorkbook.Create;
   W.ReadFromFile( GetParam( 'x'));

   if( ParamSet( 'l')) then OutputSheetNames( W) else Convert( W);

   W.Destroy();
end. // xlsx_to_csv program
