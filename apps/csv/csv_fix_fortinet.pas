{* ***************************************************************************

Copyright (c) 2019 by Lloyd B. Park

The csv_fix_fortinet program reads a CSV export file from Fortianalyzer and 
converts it into a true CSV file.  For some reason Fortinet decided a CSV file
is some unholy combination of CSV and JSON with unneccessary CSV double quoting
of each cell.

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

program csv_fix_fortinet;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_csv,
   lbp_output_file,
   sysutils; // IntToStr()

// *************************************************************************
// * Global variables
// *************************************************************************

var
   InputFileName:   string;
   OutputDelimiter: char = ',';


// ************************************************************************
// * SplitCell() - Split a FortiCSV cell into its' name/value pair
// ************************************************************************

function SplitCell( Cell: string; var CellName, CellValue: string): boolean;
   var
      i:         integer;
   begin
      CellValue:= '';
      result:= false;
      i:= pos( '=', Cell);
      if( (Length( Cell) = 0) or (i = 0)) then exit;

      CellName:= Copy( Cell, 1, i - 1);
      CellValue:= Copy( Cell, i + 1);
      result:= true;
   end; // SplitCell()


// ************************************************************************
// * HeaderPass() - Reads the files just to create the header 
// ************************************************************************

procedure HeaderPass();
   var
      Csv:       tCsv;
      Row:       tCsvCellArray;
      Header:    tCsvCellArray;
      L:         integer;   
      i:         integer;
      iMax:      integer;
      CellName:  string;
      CellValue: string;
   begin
      Csv:= tCsv.Create( InputFileName, true);    
      Csv.SkipNonPrintable:= true;
      if( ParamSet( 'id')) then Csv.Delimiter:= GetParam( 'id')[ 1];
      
      Row:= Csv.ParseRow();
      L:= Length( Row);
      SetLength( Header, L);

      while( L > 0) do begin
         iMax:= L - 1;
         for i:= 0 to iMax do begin
            if( SplitCell( Row[ i], CellName, CellValue)) then begin
               Header[ i]:= CellName;
            end;
         end; // for each cell
         
         // Get the next one
         Row:= Csv.ParseRow();
         L:= Length( Row);
      end;
      
      // Make sure blank columns have a header
      for i:= 0 to iMax do begin
         if( Length( Header[ i]) = 0) then Header[ i]:= 'unknown_' + IntToStr( i);
      end;

      Writeln( OutputFile, Header.ToCsv(OutputDelimiter));
 
      Csv.Destroy();  
   end; // HeaderPass()


// ************************************************************************
// * DataPass() - Reads the files and outputs the data rows 
// ************************************************************************

procedure DataPass();
   var
      Csv:       tCsv;
      DataCsv:   tCsv;
      Row:       tCsvCellArray;
      L:         integer;   
      i:         integer;
      iMax:      integer;
      CellName:  string;
      CellValue: string;
   begin
      Csv:= tCsv.Create( InputFileName, true);    
      Csv.SkipNonPrintable:= true;
      if( ParamSet( 'id')) then Csv.Delimiter:= GetParam( 'id')[ 1];
      
      Row:= Csv.ParseRow();
      L:= Length( Row);

      while( L > 0) do begin
         iMax:= L - 1;
         for i:= 0 to iMax do begin
            SplitCell( Row[ i], CellName, CellValue);
            DataCsv:= tCsv.Create( CellValue);
            Row[ i]:= DataCsv.ParseCell();
            DataCsv.Destroy();
         end; // for each cell
         
         Writeln( OutputFile, Row.ToCsv(OutputDelimiter));
 
         // Get the next one
         Row:= Csv.ParseRow();
         L:= Length( Row);
      end;

      Csv.Destroy();  
   end; // DataPass()


// *************************************************************************
// * ParseArgV() - Sets variables based on the command line parameters.
// *************************************************************************

procedure ParseArgv();
   begin
      if( not ParamSet( 'input-file')) then begin
         Usage( true, 'An input file name is required!');
         // Never returns because an exception will be thrown in Useage()
      end;
      InputFileName:= GetParam( 'input-file');

      if( ParamSet( 'od')) then OutputDelimiter:= GetParam( 'od')[ 1];
   end; // ParseArgv()

// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      SetOutputFileParam( false, true, false, true);

      InsertUsage( '');
      InsertUsage( 'The csv_fix_fortinet program reads a CSV export file from Fortianalyzer and');
      InsertUsage( 'converts it into a true CSV file.  For some reason Fortinet decided a CSV file');
      InsertUsage( 'is some unholy combination of CSV and JSON with unneccessary CSV double quoting');
      InsertUsage( 'of each cell.  While the parameters allow it, an input pipe is not allowed');
      InsertUsage( 'because the input must be read twice!');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_fix_fortinet [-f <input file name>] [-o <output file name>]');
      InsertUsage( '');
      InsertUsage();

      InsertUsage( '   ========== Program Options ==========');
      AddParam( ['d', 'id','input-delimiter'], true, ',', 'The character which separates fields on a line.'); 
      AddParam( ['od','output-delimiter'], true, ',', 'The character which separates fields on a line.'); 
      AddUsage( '                                 right are stripped off and each row thereafter');
      AddUsage( '                                 is trimmed to that size.  Use --no-auto-trip');
      AddUsage( '                                 to turn off this feature.');
      AddParam( ['f','input-file'], true, '', 'The required input forticsv file.');
      AddUsage();

      AddPostParseProcedure( @ParseArgv);
      ParseParams();  // parse the command line
   end; // InitArgvParser();


// ************************************************************************
// * main()
// ************************************************************************

begin
   InitArgvParser();
   
   HeaderPass();
   DataPass();

   // Cleanup happens automatically in the  lbp_csv_filters unit.
end.  // csv_fix_fortinet;
