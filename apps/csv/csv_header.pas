{* ***************************************************************************

Copyright (c) 2019 by Lloyd B. Park

Outputs a .csv file's Header using new lines as separators between field names

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

program csv_heaser;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_parse_helper,
   lbp_csv,
   lbp_generic_containers,
   lbp_input_file,
   lbp_output_file,
   sysutils;  // EIntOverflow


// ************************************************************************

type
   tSpreadsheetColumnLabel = class( tobject)
      private
         FieldCountTest:  array [1..6] of integer;
         MyValue:         string;
         MyValueLength:   integer;
         MyHeaderIndex:   integer;
         MaxHeaderIndex:  integer;
{$WARNING I'm adding Index numbers in the verticle view in addition to the existing column view.}
         MyIndexString:   string;
         MyIndexStrLen:   integer;
         FirstChr:        char;
         LastChr:         char;
         Lowest:          integer;  // Debuging only
      public
         constructor Create( HeaderLength: integer);
         function    Increment(): string; // return the next label;
      private
         procedure   IncrementDigit( DigitIndex: integer);
         function    GetLabelDigits( FieldCount: integer): integer;
      public
         property   Value:    string read MyValue;
         property   IndexStr: string read MyIndexString;
   end; // tSpreadsheetColumnLabel() class



// ========================================================================
// = tSpreadsheetColumnLabel class
// ========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tSpreadsheetColumnLabel.Create( HeaderLength: integer);
   var
      Temp: string;
   begin
      FieldCountTest[ 1]:= 26;
      FieldCountTest[ 2]:= 702;
      FieldCountTest[ 3]:= 18278;
      FieldCountTest[ 4]:= 475254;
      FieldCountTest[ 5]:= 12356630;
      FieldCountTest[ 6]:= 321272406;
      MyValue:=            '              '; // Bigger than we will ever need.
      MyHeaderIndex:=      -1;
      MaxHeaderIndex:=     HeaderLength - 1;
      FirstChr:=           'A';
      LastChr:=            'Z';
      MyValueLength:=      GetLabelDigits( HeaderLength);
      Lowest:=             MyValueLength;
      SetLength( MyValue, MyValueLength + 2);
      MyIndexString:=      '';
      Temp:= MaxHeaderIndex.ToString;
      MyIndexStrLen:=      Length( Temp);
   end; // Create()


// *************************************************************************
// * Increment - Return the next SpreadSheetCoumnLabel
// *************************************************************************

function tSpreadsheetColumnLabel.Increment(): string;
   var
      L: integer;
   begin
      Inc( MyHeaderIndex);
      MyIndexString:= MyHeaderIndex.ToString;
      L:= MyIndexString.Length;
      while( L < MyIndexStrLen) do begin
         MyIndexString:= ' ' + MyIndexString;
         inc( L);
      end; 
      MyIndexString:= MyIndexString + '  ';


      If( MyHeaderIndex > MaxHeaderIndex) then begin
         raise EIntOverflow.Create( 'Attempt to Increment the spreadsheet column label beyond its maximum value');
      end;
      IncrementDigit( MyValueLength); // The rightmost digit
      result:= MyValue; 
   end; // Increment();


// *************************************************************************
// * IncrementDigit() - Internal function to increment each digit of
// *                    MyValue as needed
// *************************************************************************

procedure tSpreadsheetColumnLabel.IncrementDigit( DigitIndex: integer);
   var
      NewIndex: integer;
      V:        char;
   begin
      V:= MyValue[ DigitIndex];
      if( V = ' ') then begin
         MyValue[ DigitIndex]:= FirstChr;
      end else if( V = LastChr) then begin
         MyValue[ DigitIndex]:= FirstChr;
         NewIndex:= DigitIndex - 1;
         if( NewIndex < 1) then raise EIntOverflow.Create( 'The column index value overflowed');
         if( NewIndex < Lowest) then begin
            Lowest:= NewIndex;
            writeln( 'First use of digit ', Length( MyValue) - Lowest + 1, ' at i = ', MyHeaderIndex);
         end;
         IncrementDigit( NewIndex);
      end else begin
         MyValue[ DigitIndex]:= Chr( ord( V) + 1);
      end;
   end; // IncrementDigital()


// ************************************************************************
// * GetLabelDigits() - Returns the number of digits needed to display final
// *                    header's column labels. 
// ************************************************************************

function tSpreadsheetColumnLabel.GetLabelDigits( FieldCount: integer): integer;
   var
      iFCT:   integer; // index to FieldCountTest;
      MFCT:   integer;  // Maximum FCT
   begin
      result:= 1; // It will allways take at least one digit.
      iFCT:= 1;
      MFCT:= Length( FieldCountTest);
      while( (iFct <= MFct) and (FieldCount > FieldCountTest[ iFCT])) do begin
         inc( iFCT);
         result:= iFCT;
      end;
   end; // GetLabelDigits()



// ========================================================================
// =  Global functions
// ========================================================================

var  // Command line parameter related variables 
   Delimiter:      string;
   HorizontalView: boolean;
   ColumnView:     boolean;
   IndexView:      boolean;
   PrefixView:     boolean;   // Column or Index views
   SortedView:     boolean;
   ColumnError:    string =
      'Column/index and horizontal view may not be specified at the same time!';
   SortedError:    string =
      'Simultaneous sorted and column/index view modes are not supported!';


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'csv_header dumps the first line of a CSV file and outputs it one cell');
      InsertUsage( '         per line.  It will optionally sort the lines.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_header [-s|--sort] [-f <file name>] [-o <output file name>]');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      SetInputFileParam( true, true, false, true);
      SetOutputFileParam( false, true, false, true);
      InsertParam( ['h','horizontal'], false, '', 'Print in the headers horizontally.');
      InsertParam( ['c', 'column'], false, '', 'Prefix the spreadsheet column letter to each row');
      InsertUsage( '                                  in the standard vertical mode.');
      InsertParam( ['i', 'index'], false, '', 'Prefix the CSV field index to each row in the');
      InsertUsage( '                                  standard vertical mode.');
      InsertParam( ['s','sort'], false, '', 'Sort the output.');
      InsertParam( ['d','delimiter'], true, ',', 'The character which separates fields on a line.'); 
      InsertUsage();

      ParseParams();

      HorizontalView:= ParamSet( 'horizontal');
      ColumnView:=     ParamSet( 'column');
      IndexView:=      ParamSet( 'index');
      SortedView:=     ParamSet( 'sort');
      PrefixView:=     (ColumnView or IndexView);

      // Set the delimiter
      if( ParamSet( 'delimiter')) then begin
         Delimiter:= GetParam( 'delimiter');
         if( Length( Delimiter) <> 1) then begin
            raise tCsvException.Create( 'The delimiter must be a singele character!');
         end;
      end else Delimiter:= ',';

      // Check for parameter misuse
      if( (ColumnView or IndexView) and HorizontalView) then begin
         lbp_argv.Usage( true, ColumnError);
      end;
      if( (ColumnView or IndexView) and SortedView) then begin
        lbp_argv.Usage( true, SortedError);
      end;
   end; // InitArgvParser();


// ************************************************************************
// * main()
// ************************************************************************

var
   Csv:                   tCsv;
   Header:                tCsvCellArray;
   FieldName:             string;
   SpreadSheetCoumnLabel: tSpreadsheetColumnLabel;
   Prefix:                string; // Spreadsheet Column Label
begin
   InitArgvParser();

   // Get the header
   Csv:= tCsv.Create( lbp_input_file.InputStream, False);
   Csv.Delimiter:= Delimiter[ 1];
   Csv.ParseHeader();
   if( SortedView) then Header:= Csv.SortedHeader else Header:= Csv.Header;
   Csv.Destroy();
   
   if( HorizontalView) then begin
      // Handle Horizontal view
      writeln( Header.ToCsv);
   end else begin
     
      // Handle vertical view
      if( PrefixView) then begin
         // Handle column view
         SpreadSheetCoumnLabel:= tSpreadsheetColumnLabel.Create( Length( Header));
         for FieldName in Header do begin
            SpreadSheetCoumnLabel.Increment();
            Prefix:= '';
            if( IndexView) then Prefix:= Prefix + SpreadSheetCoumnLabel.IndexStr; 
            if( ColumnView) then Prefix:= Prefix + SpreadSheetCoumnLabel.Value; 
            writeln( Prefix, FieldName);
         end; // for
         SpreadSheetCoumnLabel.Destroy();
      end else begin
         // Handle non-column view
         for FieldName in Header do begin
            writeln( OutputFile, CsvQuote( FieldName));
         end; // for
      end; // else non-column view
   end; // Horizontal else Vertical
end.  // csv_header program
