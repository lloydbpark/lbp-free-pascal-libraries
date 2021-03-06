{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Extract fields from a CSV string.  Quote and unquote CSV fields.

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
unit lbp_csv;

// Classes to handle Comma Separated Value strings and files.

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_types,
   lbp_generic_containers,
   lbp_parse_helper;


// *************************************************************************

type
   tCsvException   =  class( lbp_exception);
   tCsvCellArray =  array of string;
   tCsvRowArray   =  array of tCsvCellArray;
   tCsvCellArrayHelper = type helper for tCsvCellArray
      function ToCsv( Delimiter: char = ','): string;
   end;

const
   USchr  = char( 31);  // Unit Separator - Send after each valid field
   RSchr  = char( 30);  // Record Separator - Send after each valid record
const
   EndOfRowChrs:     tCharSet = [ EOFchr, LFchr, CRchr];

function CsvQuote( S: string): string; // Quote the string in a CSV compatible way

procedure SetCsvDelimiter( D: char);  // Set the default Delimiter for quoting CSV
       // and the creation of tCsv instances
function GetCsvDelimiter(): char; // Returns the default Delimiter
property CsvDelimiter: char read GetCsvDelimiter write SetCsvDelimiter;

// *************************************************************************

type
   tCsv = class( tChrSource)
      private type
         tIndexDict = specialize tgDictionary<string, integer>;
         tRevIndexDict = specialize tgDictionary<integer, string>;
      protected
         IndexDict:           tIndexDict;
         MyDelimiter:         char;
         EndOfCellChrs:       tCharSet;
         QuoteableChrs:       tCharSet;
         UnquotedCellChrs:    tCharSet;
         IntraLineWhiteChrs:  tCharSet;
         WhiteChrs:           tCharSet;
         procedure  Init(); override;
         function   ParseQuotedStr(): string;
         procedure  SetDelimiter( D: char);
      public
         destructor Destroy(); override;
         function   ParseHeader(): integer; virtual;// returns the number of cells in the header
         function   ColumnExists( Name: string): boolean; virtual;
         function   IndexOf( Name: string): integer; virtual;
         function   Header():  tCsvCellArray; virtual;
         function   SortedHeader(): tCsvCellArray; virtual;
         function   ParseCell(): string; virtual;
         function   ParseRow(): tCsvCellArray; virtual;
         function   Parse(): tCsvRowArray; virtual;
         procedure  DumpIndex(); virtual;
         property   Delimiter: char read MyDelimiter write SetDelimiter;
         property   SkipNonPrintable: boolean read MySkipNonPrintable write MySkipNonPrintable;
      end; // tCsv class


// *************************************************************************

implementation

// *************************************************************************

var
   MyGlobalDelimiter:     char;
   MyGlobalQuoteableChrs: tCharSet;

// =========================================================================
// = tCSV
// =========================================================================
// *************************************************************************
// * Init() - Initialize the class
// *************************************************************************

procedure tCsv.Init();
   begin
      Inherited Init();
      Delimiter:= MyGlobalDelimiter; // Set the default delimiter between cells
      QuoteChrs:= [ '"']; 
      IndexDict:= tIndexDict.Create( tIndexDict.tCompareFunction( @CompareStrings), false);
   end; // Init()


// *************************************************************************
// * Destroy() - Destructor
// *************************************************************************

destructor tCsv.Destroy();
   begin
      IndexDict.Destroy;
      inherited Destroy;
   end; // Destroy()


// *************************************************************************
// * ParseHeader() - Read the header so we can lookup column numbers by name
// *************************************************************************

function tCsv.ParseHeader(): integer;
   var
      MyHeader:  tCsvCellArray;
      i:       integer;
      iMax:    integer;
   begin
      {$ifdef DEBUG_PARSE_HELPER}
         if( DebugParser) then begin
            writeln( 'tCsv.ParseHeader() called');
            MyIndent:= MyIndent + '   ';
         end;
      {$endif}
      MyHeader:= ParseRow();
      result:= Length( MyHeader);
      iMax:= result - 1;
      for i:= 0 to iMax do IndexDict.Add( MyHeader[ i], i);

      {$ifdef DEBUG_PARSE_HELPER}
         if( DebugParser) then SetLength( MyIndent, Length( MyIndent) - 3);
      {$endif}
   end; // ParseHeader()


// *************************************************************************
// * ColumnExists() - Returns true if the passed Name is a Column.
// *************************************************************************

function tCsv.ColumnExists( Name: string): boolean;
   begin
      result:= IndexDict.Find( Name);
   end; // ColumnExists()


// *************************************************************************
// * IndexOf() - Returns the column number of the passed header string
// *************************************************************************

function tCsv.IndexOf( Name: string): integer;
   begin
      result:= IndexDict.Items[ Name];
   end; // IndexOf()


// *************************************************************************
// * Header() - Returns an array of header names in the order they appear 
// *            in the CSV.  Returns an empty array if the Header hasn't
// *            been parsed.
// *************************************************************************

function tCsv.Header():  tCsvCellArray;
   begin
      SetLength( result, IndexDict.Count);
      IndexDict.StartEnumeration;
      while( IndexDict.Next) do result[ IndexDict.Value]:= IndexDict.Key; 
   end; // Header()


// *************************************************************************
// * SortedHeader() - Returns an array of header names sorted alphabetically.
// *                  Returns an empty array if the Header hasn't been
// *                  parsed.
// *************************************************************************

function tCsv.SortedHeader(): tCsvCellArray;
   var
      i: integer= 0;
   begin
      SetLength( result, IndexDict.Count);
      IndexDict.StartEnumeration;
      while( IndexDict.Next) do begin
         result[ i]:= IndexDict.Key;
         inc( i);
      end; 
   end; // SortedHeader()


// *************************************************************************
// * ParseQuotedStr() - Returns a quoted cell.  Assumes the first character
// *                    in the character source is the leading quote.
// *************************************************************************

function tCsv.ParseQuotedStr(): string;
   var
      Quote:    char;
      C:        char;
   begin
      {$ifdef DEBUG_PARSE_HELPER}
         if( DebugParser) then writeln( MyIndent, 'tCsv.ParseQuotedStr() called');
      {$endif}
      result:= ''; // Set default value
      InitS();
      Quote:= Chr;
      
      C:= Chr;
      While( True) do begin
         if( C in AnsiPrintableChrs) then begin
            if( C = Quote) then begin
               if( PeekChr() = Quote) then begin
                  // Two quotes in a row
                  C:= Chr; 
               end else begin
                  SetLength( MyS, MySLen);
                  result:= MyS;
                  // Strip trailing spaces
                  ParseElement( IntraLineWhiteChrs);
                 exit;
               end;
            end; // if C = Quote
            ParseAddChr( C);
         end else begin
            // Not printable;
            if( C = EOFchr) then lbp_exception.Create(
               'The end of the file was reached while parsing a quoted string!');
            if( not SkipNonPrintable) then lbp_exception.Create(
               'Invalid character in a quoted string:  Ord(%d)', [ord( C)]);
         end; // else not AnsiPrintableChrs
         C:= Chr;
      end;
   end; // ParseQuotedStr()


// *************************************************************************
// * SetDelimiter() - Sets the character that separates cells in a line
// *************************************************************************

procedure tCsv.SetDelimiter( D: char);
//   var
//      DSet: tCharSet;
   begin
      {$ifdef DEBUG_PARSE_HELPER}
         if( DebugParser) then begin
            write( MyIndent, 'tCsv.SetDelimiter() to ');
            if( D in IntraLineAnsiChrs) then begin
               writeln( '''', D, '''');
            end else begin
               writeln( 'ord(', ord( D), ')');
            end;
         end;
      {$endif}

      MyDelimiter:= D;
//      DSet:= [ D];
      EndOfCellChrs:= EndOfRowChrs + [ D];
      UnquotedCellChrs:= AnsiPrintableChrs - EndOfCellChrs;
      QuoteableChrs:= [ '"'] + WhiteChrs + [ D];
      IntraLineWhiteChrs:= lbp_parse_helper.IntraLineWhiteChrs - [ D];
      WhiteChrs:= lbp_parse_helper.WhiteChrs - [ D];
   end; // SetDelimiter()


// *************************************************************************
// * ParseCell() - Returns a cell.  It leaves the EndOfCell character in the 
// *               buffer.
// *************************************************************************

function tCsv.ParseCell(): string;
   {$WARNING tCsvParseCell needs to honor SkipNonPrintable}
   var
      C:        char;
      i:        integer;
   begin
      {$ifdef DEBUG_PARSE_HELPER}
         if( DebugParser) then begin
            writeln( MyIndent, 'tCsv.ParseCell()');
            MyIndent:= MyIndent + '   ';
         end;
      {$endif}

      result:= ''; // Set default value
      InitS();

      // Discard leading white space
      ParseElement( IntraLineWhiteChrs);

      // Handle quoted cells
      C:= PeekChr();
      if( C in QuoteChrs) then begin
         result:= ParseQuotedStr();
         // Discard trailing spaces;
         ParseElement( IntraLineWhiteChrs);
      // Handle unquoted cells
      end else begin
         result:= ParseElement( UnquotedCellChrs);
         // Strip trailing spaces
         i:= Length( result);
         while( (i > 0) and (Result[ i] in IntraLineWhitechrs)) do dec( i);
         SetLength( result, i);
      end;

      C:= PeekChr();
      if( not (C in EndOfCellChrs)) then begin
         raise tCsvException.Create( 'Cell ''' + result + 
                  ''' was not followed by a valid end of cell character');
      end;

      {$ifdef DEBUG_PARSE_HELPER}
         if( DebugParser) then SetLength( MyIndent, Length( MyIndent) - 3);
      {$endif}
      // if( C in InterLineWhiteChrs) then UngetChr( ',');
   end; // ParseCell()


// *************************************************************************
// * ParseRow() - Returns an array of strings.  The returned array is 
// *              invalid if an EOF is the next character in the tChrSource.
// *************************************************************************

function tCsv.ParseRow(): tCsvCellArray;
   var
      TempCell:  string;
      C:         char;
      Sa:        tCsvCellArray;
      SaSize:    longint = 16;
      SaLen:     longint = 0;
      LastCell:  boolean = false;
   begin
      {$ifdef DEBUG_PARSE_HELPER}
         if( DebugParser) then writeln( 'tCsv.ParseRow() called');
      {$endif}

      SetLength( Sa, SaSize);

      // Strip off any white space including empty lines.  This insures the next 
      // character starts a valid cell.
      while( PeekChr() in WhiteChrs) do GetChr();

      // We only can add to cells if we are not at the end of the file
      if( PeekChr <> EOFchr) then begin
         repeat
            TempCell:= ParseCell();

            // Add TempCell to Sa - resize as needed
            if( SaLen = SaSize) then begin
               SaSize:= SaSize SHL 1;
               SetLength( Sa, SaSize);
            end;
            Sa[ SaLen]:= TempCell; 
            inc( SaLen);

            C:= PeekChr;
            LastCell:= C <> MyDelimiter;
            if( not LastCell) then C:= GetChr;
         until( LastCell);  // so this only matches, CR, LF, and EOF
         
         // If the 'line' ended with an EOF and no CR or LF then we need to fake
         // it since we are returning a valid array of cells.
         if( PeekChr = EOFchr) then UngetChr( LFchr);
      end;

      SetLength( Sa, SaLen);
      result:= Sa;
   end; // ParseRow()


// *************************************************************************
// * Parse() - Returns an array of tCsvLines
// *************************************************************************

function tCsv.Parse(): tCsvRowArray;
   var
      TempLine:  tCsvCellArray;
      C:         char;
      Ra:        tCsvRowArray;
      RaSize:    longint;
      RaLen:     longint;
   begin
      {$ifdef DEBUG_PARSE_HELPER}
         if( DebugParser) then begin
            writeln( 'tCsv.Parse() called');
            MyIndent:= MyIndent + '   ';
         end;
      {$endif}
      RaSize:= 32;
      SetLength( Ra, RaSize);
      RaLen:= 0;      

      // Keep going until we reach the end of file character
      repeat
         TempLine:= ParseRow();
         C:= PeekChr();
         if( C <> EOFchr) then begin
            // Add TempLine to La - resize as needed
            if( RaLen = RaSize) then begin
               RaSize:= RaSize SHL 1;
               SetLength( Ra, RaSize);
            end;
            Ra[ RaLen]:= TempLine; 
            inc( RaLen);
         end;
      until( C = EOFchr);
      
      SetLength( Ra, RaLen);
      result:= Ra;
      {$ifdef DEBUG_PARSE_HELPER}
         if( DebugParser) then SetLength( MyIndent, Length( MyIndent) - 3);
      {$endif}
   end; // Parse()


// *************************************************************************
// * DumpIndex() - Writes the Column index one per line.
// *************************************************************************

procedure tCsv.DumpIndex();
   var
      RevIndexDict: tRevIndexDict;
      i: integer;
      V: string;
   begin
      RevIndexDict:= tRevIndexDict.Create( tRevIndexDict.tCompareFunction( @CompareIntegers));

      // Copy the existing dictionary to the new reverse lookup one.
      IndexDict.StartEnumeration;
      while( IndexDict.Next) do begin
         i:= IndexDict.Value;
         V:= IndexDict.Key;
         RevIndexDict.Add( i, V);
      end;

      RevIndexDict.StartEnumeration;
      while( RevIndexDict.Next) do begin
         V:= RevIndexDict.Value;
         i:= RevIndexDict.Key;
         writeln( i:4, ' - ', V);
      end;

      RevIndexDict.Destroy();
   end; // DumpIndex()



// =========================================================================
// = tCsvCellArrayHelper
// =========================================================================
// *************************************************************************
// * ToCsv() - Convert the array into a line of CSV text
// *************************************************************************

function tCsvCellArrayHelper.ToCsv( Delimiter: char = ','): string;
   var
      S:      string;
      Temp:   string;
      First:  boolean;
   begin
      result:= '';
      First:= true;
      for S in self do begin
         Temp:= CsvQuote( S);
         if( First) then begin
            First:= false;
            result:= temp;
         end else begin 
            result:= result + Delimiter + temp;
         end;
      end; // for
   end; // ToCsv()



// =========================================================================
// = Global functions
// =========================================================================
// *************************************************************************
// * SetCsvDelimiter() - Sets the default character that separates cells in 
// *                     a line.
// *************************************************************************

procedure SetCsvDelimiter( D: char);
   begin
      MyGlobalDelimiter:= D;
      MyGlobalQuoteableChrs:= [ '"'] + WhiteChrs + [ D];
   end; // SetCsvDelimiter()


// *************************************************************************
// * GetCsvDelimiter() - Returns the default character that separates cells
// *                     in a line
// *************************************************************************

function GetCsvDelimiter(): char;
   begin
      result:= MyGlobalDelimiter;
   end; // GetCsvDelimiter()


// *************************************************************************
// * CsvQuote() = Return the passed string 
// *************************************************************************

function CsvQuote( S: string): string;
   var
      C:       char;
      QuoteIt: boolean = false;
   begin
      result:= '';
      for C in S do begin
         if( C in MyGlobalQuoteableChrs) then QuoteIt:= true;
         if( C = '"') then result:= result + '"';
         result:= result + C;
      end;
      if( QuoteIt) then result:= '"' + result + '"';
   end; // CsvQuote()


// *************************************************************************

begin
   SetCsvDelimiter( ',');
end. // lbp_csv unit
