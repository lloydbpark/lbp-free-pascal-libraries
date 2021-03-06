{* ***************************************************************************

Copyright (c) 2019 by Lloyd B. Park

Combines multiple .csv files with identical headers into one file.  Its cheif
advantage over a simple text editor is that it check to make sure headers 
match and only outputs the first one

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

program csv_cat;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_csv,
   lbp_parse_helper,
   lbp_generic_containers,
   lbp_output_file,
   sysutils; // FileExists()

var
   SkipNonPrintable:   boolean = false;
   DelimiterIn:        char;
   DelimiterOut:       char;
   FirstHeader:        tCsvCellArray = nil;

// ************************************************************************
// * SetGlobals() - Sets our global variables
// ************************************************************************

procedure SetGlobals();
   var
      Delimiter:    string;
   begin
      // Make sure we passed at least one file name.
      if( Length( UnnamedParams) < 1) then begin
         raise tCsvException.Create( 'You must supply at least one CSV file name');
      end;

      // Set the input delimiter
      if( ParamSet( 'id')) then begin
         Delimiter:= GetParam( 'id');
         if( Length( Delimiter) <> 1) then begin
            raise tCsvException.Create( 'The delimiter must be a singele character!');
         end;
         DelimiterIn:= Delimiter[ 1];
      end else begin
         DelimiterIn:= CsvDelimiter; // the default value in the lbp_csv unit.
      end;

      // Set the output delimiter
      if( ParamSet( 'od')) then begin
         Delimiter:= GetParam( 'od');
         if( Length( Delimiter) <> 1) then begin
            raise tCsvException.Create( 'The delimiter must be a singele character!');
         end;
         DelimiterOut:= Delimiter[ 1];
      end else begin
         DelimiterOut:= DelimiterIn;
      end;

      SkipNonPrintable:= ParamSet( 'skip-non-printable');
   end; // InitGlobals()



// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'csv_cat reads a list of CSV file names and combines them into one file.  The');
      InsertUsage( '      header line of each file must be the same.');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_cat <1st file name> <2nd file name> ...');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      SetOutputFileParam( false, true, false, true);
      InsertParam( ['d', 'id','input-delimiter'], true, ',', 'The character which separates fields on a line.'); 
      InsertParam( ['od','output-delimiter'], true, ',', 'The character which separates fields on a line.'); 
      InsertParam( ['s', 'skip-non-printable'], false, '', 'Try to fix files with some unicode characters.');
      InsertUsage();
      ParseParams();
   end; // InitArgvParser();


// ************************************************************************
// * HeadersMatch() - returns true if the two passed headers have the 
// *                  same fields in the same order.
// ************************************************************************

function HeadersMatch( H1, H2: tCsvCellArray): boolean;
   var
      i:     integer;
      iMax:  integer;
   begin
      result:= true;
      iMax:= Length( H1) - 1;
      
      if( Length( H1) <> Length( H2)) then begin
         result:= false;
         exit;
      end;

      for i:= 0 to iMax do begin
         if( H1[ i] <> H2[ i]) then begin
            result:= false;
            exit;
         end;
      end; 
   end; // HeadersMatch()


// ************************************************************************
// * ProcessCsv() - Main loop to process the file
// ************************************************************************

procedure ProcessCsv( FileName: string);
   var
      Line:  tCsvCellArray;
      CsvIn:  tCsv;
   begin
      if( not FileExists( FileName)) then begin
         raise tCsvException.Create( 'The file ''%s'' does not exist!', [FileName]);
      end; 

      CsvIn:= tCsv.Create( FileName, true);
      CsvIn.SkipNonPrintable:= SkipNonPrintable;
      CsvIn.Delimiter:= DelimiterIn;

      // Check and output the first header
      CsvIn.ParseHeader;
      Line:= CsvIn.Header;
      if( FirstHeader = nil) then begin
         FirstHeader:= Line;
         writeln( OutputFile, Line.ToCsv( DelimiterOut));
      end else begin
         if not HeadersMatch( FirstHeader, Line) then begin
            raise tCsvException.Create( 'The header line of file ''%s'' does not match the one from the first CSV file!', [FileName]);
         end;
      end;

      // Output the rest of the file
      Line:= CsvIn.ParseRow;
      while( CsvIn.PeekChr <> EOFchr) do begin
         writeln( OutputFile, Line.ToCsv( DelimiterOut));
         Line:= CsvIn.ParseRow;
      end;

      CsvIn.Destroy();
   end; // ProcessCsv();


// ************************************************************************
// * main()
// ************************************************************************
var
   FileName: string;
begin
   InitArgvParser();
   SetGlobals();

   for FileName in UnnamedParams do begin
      ProcessCsv( FileName);
   end;
end.  // csv_cat program
