{* ***************************************************************************

Copyright (c) 2021 by Lloyd B. Park

Comapares to CSV files and outputs a CSV of the differences

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

program csv_diff;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_csv,
   lbp_csv_filter,
   lbp_output_file,
   sysutils;

// ************************************************************************

type
   tCompareFunction = function( const S1: string; S2: string): int8;

// ************************************************************************
// * Global variables
// ************************************************************************

var
   Csv1:             tCsv;
   Csv2:             tCsv;
   OutputHeader:     tCsvCellArray;
   OutputHeaderLen:  integer; // 
   Lookup1:          array of integer;
   Lookup2:          array of integer;
   LookupM:          integer;   // The max index of Lookup1 and Lookup2
   CompareUnique:    tCompareFunction;  // The function used to compare the unique fields
   OnlyCommonRows:   boolean = false;


// ************************************************************************
//* CompareInt32() - Compares two Int32 values
// ************************************************************************

function CompareInt32(   S1: string; s2: string): int8;
   var
      N1: int32;
      N2: int32;
   begin
      N1:= longint.Parse( S1);
      N2:= longint.Parse( S2);
      if( N1 > N2) then begin
         result:= 1;
      end else if( N1 < N2) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareInt32()


// ************************************************************************
//* CompareInt64() - Compares two Int64 values
// ************************************************************************

function CompareInt64( S1: string; S2: string): int8;
   var
      N1: int64;
      N2: int64;
   begin
      N1:= int64.Parse( S1);
      N2:= int64.Parse( S2);
      if( N1 > N2) then begin
         result:= 1;
      end else if( N1 < N2) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareInt64()


// ************************************************************************
//* CompareWord32() - Compares two Word32 values
// ************************************************************************

function CompareWord32(  S1: string; S2: string): int8;
   var
      N1: word32;
      N2: word32;
   begin
      N1:= cardinal.Parse( S1);
      N2:= Cardinal.Parse( S2);
      if( N1 > N2) then begin
         result:= 1;
      end else if( N1 < N2) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareWord32()


// ************************************************************************
//* CompareWord64() - Compares two Word64 values
// ************************************************************************

function CompareWord64(  S1: string; S2: string): int8;
   var
      N1: word64;
      N2: word64;
   begin
      N1:= qword.Parse( S1);
      N2:= qword.Parse( S2);
      if( N1 > N2) then begin
         result:= 1;
      end else if( N1 < N2) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareWord64()


// ************************************************************************
//* CompareString() - Compares two strings
// ************************************************************************

function CompareString(  S1: string; S2: String): int8;
   begin
      if( S1 > S2) then begin
         result:= 1;
      end else if( S1 < S2) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareString()


// ************************************************************************
// * DumpGlobals() - print the global variables
// ************************************************************************

procedure DumpGlobals();
   var
      I:  integer;
   begin
      Writeln( 'OutputHeader   = ', OutputHeader.ToCsv);
      writeln( 'OnlyCommonRows = ', OnlyCommonRows);
      write(   'Lookup1        = ' );
      for I in Lookup1 do write( I, '  ');
      writeln();
      write(   'Lookup2        = ' );
      for I in Lookup2 do write( I, '  ');
      writeln();
      writeln(   'LookupM        = ', LookupM );

   end; // DumpGlobals()


// ************************************************************************
// * CompareRows() - compare two CSV rows and output the diff it if they 
// *                 don't match.  Assumes the Unique field is the same.
// ************************************************************************

procedure CompareRows( R1, R2: tCsvCellArray);
    var
       i:       integer; // outer loop index
       j:       integer; // source index
       k:       integer; // destination index
       OutRow:  tCsvCellArray;
   begin
      for i:= 1 to LookupM do begin
         if( R1[ Lookup1[i]] <> R2[ Lookup2[ i]]) then begin
            SetLength( OutRow, OutputHeaderLen);
            k:= 0;
            for j:= 0 to LookupM do begin
               OutRow[ k]:= R1[ Lookup1[ j]];
               Inc( K);
            end; 
            for j:= 1 to LookupM do begin
               OutRow[ k]:= R2[ Lookup2[ j]];
               Inc( K);
            end; 
            writeln( OutputFile, OutRow.ToCsv);
            exit;
         end;
      end;
   end; // compareRows()


// ************************************************************************
// * CompareFile() - compare two CSV files.  Returns true if they are equal
// ************************************************************************

procedure CompareFiles( C1, C2: tCsv);
   var
      R1,   R2:    tCsvCellArray;
      L1,   L2:    integer;  // The length of each row
      Empty1:      tCsvCellArray;
      Empty2:      tCsvCellArray;
      i:           integer; // for loop
      iMax:        integer; // for loop

   // ---------------------------------------------------------------------
   // - NextR1()
   // ---------------------------------------------------------------------
   procedure NextR1();
      begin
         if( not OnlyCommonRows) then begin
            // Output the addition of R1 as a difference
            Empty2[ 0]:= R1[ Lookup1[ 0]];
            CompareRows( R1, Empty2);
         end;
         R1:= C1.ParseRow;
         L1:= Length( R1);
      end; // NextR1()
   // ---------------------------------------------------------------------

   // ---------------------------------------------------------------------
   // - NextR2()
   // ---------------------------------------------------------------------
   procedure NextR2();
      begin
         if( not OnlyCommonRows) then begin
            // Output the addition of R1 as a difference
            Empty1[ 0]:= R2[ Lookup2[ 0]];
            CompareRows( Empty1, R2);
         end;
         R2:= C2.ParseRow;
         L2:= Length( R2);
      end; // NextR2()

   // ---------------------------------------------------------------------

   begin
      writeln( OutputFile, OutputHeader.ToCsv);
            
      // Step through each file until one of them is at end-of-file
      // The length of the Row array is zero if we are at the end-of-file
      R1:= C1.ParseRow;
      R2:= C2.ParseRow;
      L1:= Length( R1);
      L2:= Length( R2);

      // Create the empty tCsvCellArrays if needed
      if( not OnlyCommonRows) then begin
         SetLength( Empty1, L1);
         iMax:= L1 - 1;
         for i:= 1 to iMax do Empty1[ i]:= '';
         SetLength( Empty2, L2);
         iMax:= L2 - 1;
         for i:= 1 to iMax do Empty2[ i]:= '';
      end;

      while( (L1 <> 0) and (L2 <> 0)) do begin
         case CompareUnique( R1[ Lookup1[ 0]], R2[ Lookup2[ 0]]) of
            0: begin
               CompareRows( R1, R2);
               // Move both files to their next row
               R1:= C1.ParseRow;
               R2:= C2.ParseRow;
               L1:= Length( R1);
               L2:= Length( R2);
            end;
            1: NextR2;
            -1: NextR1
         else; 
         end; // case
      end; // while both files have rows available
     
     // If we are pinting out rows without a match in the other file
     //    then continue reading a file when the other file is finished
     if( not OnlyCommonRows) then begin
        while( L1 <> 0) do NextR1;
        while( L2 <> 0) do NextR2;
     end; 
   end; // compareFiles()


// ************************************************************************
// * InitVars() - Read parameters and initialize variables.
// ************************************************************************

procedure InitVars();
   var
      UniqueField:   string;  // The unqique (ID) field name
      LIH:           integer; // Number of the input header field names
      i:             integer;
      S:             string;  // temporary string
      Header:        tCsvCellArray;
      CsvH:          tCsv; // used parsing the header
      IFN:           integer; // Input file number
      FieldName:     string;
      HL1:           integer; // The Lenght of the header in Csv1
      HL2:           integer; // The Lenght of the header in Csv2
   begin
      // Get the Header values supplied by the user
      if( not ParamSet( 'h')) then begin
         raise tCsvException.Create( 'You must enter a list of header fields to be compared.');
      end;
      CsvH:= tCsv.Create( GetParam( 'h'));
      LIH:= CsvH.ParseHeader;
      Header:= CsvH.Header;
      CsvH.Destroy;

      // Create the output header
      OutputHeaderLen:= (LIH * 2) + 1;
      SetLength( OutputHeader, OutputHeaderLen);
      UniqueField:= GetParam( 'u');
      OutputHeader[ 0]:= UniqueField;
      i:= 1;
      for S in Header do begin
         OutputHeader[ i]:= '1-' + S;
         Inc( i);
      end;
      for S in Header do begin
         OutputHeader[ i]:= '2-' + S;
         Inc( i);
      end;

      // Open the two CSV files and read each header
      if( Length( UnnamedParams) <> 2)then begin
         raise tCsvException.Create( 'You must enter the two CSV file names on the command line!');
      end;
      Csv1:= tCsv.Create( UnnamedParams[ 0], true);
      Csv2:= tCsv.Create( UnnamedParams[ 1], true);
      HL1:= Csv1.ParseHeader;
      HL2:= Csv2.ParseHeader;
      if( (HL1 = 0) or (HL2 = 0)) then begin
         raise tCsvException.Create( 'Unable to read the header from one of the files!');
      end;

      // Setup lookup tables
      LookupM:= LIH;
      Inc( LIH);
      SetLength( Lookup1, LIH);
      SetLength( Lookup2, LIH);
      try
         IFN:= 1;
         FieldName:= UniqueField;
         Lookup1[ 0]:= Csv1.IndexOf( FieldName);
         for i:= 1 to LookupM do begin
            FieldName:= Header[ i - 1];
            Lookup1[ i]:= Csv1.IndexOf( FieldName);
         end;
         IFN:= 2;
         FieldName:= UniqueField;
         Lookup2[ 0]:= Csv2.IndexOf( FieldName);
         for i:= 1 to LookupM do begin
            FieldName:= Header[ i - 1];
            Lookup2[ i]:= Csv2.IndexOf( FieldName);
         end;
      except
        on E: Exception do begin
           raise tCsvException.Create( 'The field ''%s'' was not found in ''%s''!',
                     [FieldName, UnnamedParams[IFN - 1]]);
        end;
      end;

      // Set the Compare() function
      i:= 0;
      if( ParamSet( 'int32')) then begin
         Inc( i);
         CompareUnique:= tCompareFunction( @CompareInt32);
      end;
      if( ParamSet( 'int64')) then begin
         Inc( i);
         CompareUnique:= tCompareFunction( @CompareInt64);
      end;
      if( ParamSet( 'word32')) then begin
         Inc( i);
         CompareUnique:= tCompareFunction( @CompareWord32);
      end;
      if( ParamSet( 'word64')) then begin
         Inc( i);
         CompareUnique:= tCompareFunction( @CompareWord64);
      end;
      if( ParamSet( 'text')) then begin
         Inc( i);
         CompareUnique:= tCompareFunction( @CompareString);
      end;
      if( i = 0) then begin
          i:= 1;
         CompareUnique:= tCompareFunction( @CompareWord64);
      end;
      if( i <> 1) then begin
         raise tCsvException.Create( 'You may only specify one type for the unique field!')
      end;

      OnlyCommonRows:= ParamSet( 'c');
   end; // InitVars


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      // Allow us to use stdout for the output which makes the output file name 
      // optional
      SetOutputFileParam( false, true, true, true); 

      // Setup all the command line parameters
      InsertUsage( '');
      InsertUsage( 'csv_diff reads two CSV files and compares the fields in the passed header.  It');
      InsertUsage( '         outputs outputs the ''--unique'' field, the ''1'' header fields, and');
      InsertUsage( '         the ''2'' header fields.  The header field names of the both files are');
      InsertUsage( '         prepended with ''1-'' and ''2-'' respectiviely.  Both files must be in');
      InsertUsage( '         ''--unique'' field order.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_diff [-h <CSV line of header field names>] <CSV file name #1>');
      InsertUsage( '            <CSV file name #2>');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      InsertParam( ['h','header'], true, '', 'The comma separated list of column names'); 
      InsertParam( ['u','unique'], true, 'ID', 'The field name which uniquely identifies a row.');
      InsertUsage( '                                 Usually its a numeric ID field and this');
      InsertUsage( '                                 parameter defaults to ''ID''.');
      InsertParam( ['c', 'only-common-rows'], false, '', 'Only outputs a line if the Unique field exists in');
      InsertUsage( '                                 both file ''1'' and file ''2'' and new');
      InsertUsage( '                                 spreadsheets');
      InsertParam( ['int32'], false, '', 'The unique field is a signed 32 bit integer');
      InsertUsage( '                                 value.');
      InsertParam( ['int64'], false, '', 'The unique field is a signed 64 bit integer');
      InsertUsage( '                                 value.');
      InsertParam( ['word32'], false, '', 'The unique field in a unsigned 32 bit integer');
      InsertUsage( '                                 value.');
      InsertParam( ['word64'], false, '', 'The unique field in a unsigned 64 bit integer');
      InsertUsage( '                                 value.  This is the default type.');
      InsertParam( ['text'], false, '', 'The unique field in a simple text value.');
      InsertUsage();

      ParseParams();  // parse the command line
   end; // InitArgvParser();


// ************************************************************************
// * main()
// ************************************************************************

begin
   InitArgvParser();
   InitVars();

   CompareFiles( Csv1, Csv2); 

   Csv1.Destroy;
   Csv2.Destroy;
end.  // csv_diff program
