{* ***************************************************************************

Copyright (c) 2020 by Lloyd B. Park

lbp_field_parser - This library is primarily designed to make it easier to parse
various log file.  It uses lists of fields that know how to parse themselves.
The fields are chained together in order to parse a fixed format line.
Fields can be nested.

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

unit lbp_field_parser;

interface

{$include lbp_standard_modes.inc}
//{$V-}    //Added by LP because it says so below
//{$R-}    //Range checking off
//{$S-}    //Stack checking off
//{$I-}    //I/O checking off
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

// ************************************************************************

uses
   lbp_types,
   lbp_generic_containers,
   lbp_parse_helper,
   lbp_csv,
   classes,
   sysutils;

// ************************************************************************

type
   tParserField = class;
   tParserFieldIndexDict = specialize tgDictionary<string, integer>;
   tParserFieldList      = specialize tgDoubleLinkedList< tParserField>;

// *************************************************************************

type
   tFieldParser = class( tChrSource)
      public
         IndexDict:          tParserFieldIndexDict;
         FieldList:          tParserFieldList;
         LineNumber:         int64;
         ErrorInLine:        boolean;
         RestOfLine:         string;  // SkipRestOfLine() populates this field.
         ErrorMsgIndex:      integer; // If this is set,then on errors the message may be placed in the associated field when ParseLine is called.
         MyFilter:           string;
         MyShowParseErrors:  boolean;
         MySkipUnknownLines: boolean;
         MyAddEndMsgField:   boolean;
         procedure  Init(); override;
         procedure  PostInit(); virtual;
         procedure  SkipRestOfLine(); virtual;
      public
         constructor Create( iStream: tStream; iDestroyStream: boolean = true);
         constructor Create( iString: string; IsFileName: boolean = false);
         constructor Create( var iFile:   text);
         destructor Destroy(); override;
         function   ParseLine: tCsvCellArray; virtual;
         function   Header():  tCsvCellArray; virtual;
         function   SortedHeader(): tCsvCellArray; virtual;
         function   FieldExists( Name: string): boolean;
         function   IndexOf( Name: string): integer;

         property   SkipNonPrintable: boolean read MySkipNonPrintable write MySkipNonPrintable;
         property   Line: int64 read LineNumber write LineNumber;
         property   Filter: string read MyFilter write MyFilter;
         property   ShowParseErrors: boolean read MyShowParseErrors write MyShowParseErrors;
         property   SkipUnknownLines: boolean read MySkipUnknownLines write MySkipUnknownLines;
         property   AddEndMsgField: boolean read MyAddEndMsgField write MyAddEndMsgField;
      end; // tFieldParser;


// ************************************************************************

type
   tParserField = class
      public
         Parent:       tParserField; // Only one of parent or parser
         Parser:       tFieldParser;   //    should be non-nil.
         Name:         string;
         ValidSet:     tCharSet;
         EndSet:       tCharSet;
         MinLength:    integer;
         MaxLength:    integer;
//         ErrorInField: boolean;  // Set by Verify(), used by Parse()
      protected 
         SubFields:   tParserFieldList; // Internal fields
      public
         constructor Create( iParent: tParserField; iName: string);
         constructor Create( iParser: tFieldParser; iName: string);
         destructor  Destroy(); override;
         procedure   Init(); virtual; 
         function    Parse(): string; virtual;
         procedure   Verify( iField: string); virtual;
         procedure   ReportError( ExtraMessage: string = ''); virtual;
      end; // tParserField


// *************************************************************************

var
   EndOfLineChrs:         tCharSet = [LFchr, CRchr, EOFchr];


// *************************************************************************

implementation

// =========================================================================
// = tFieldParser
// =========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tFieldParser.Create( iStream: tStream; iDestroyStream: boolean);
   begin
      inherited Create( iStream, iDestroyStream);
      PostInit();
   end; // Create()

// -------------------------------------------------------------------------

constructor tFieldParser.Create( iString: string; IsFileName: boolean);
   begin
      inherited Create( iString, isFileName);
      PostInit();
   end; // Create()


// -------------------------------------------------------------------------

constructor tFieldParser.Create( var iFile: text);
   begin
      inherited Create( iFile);
      PostInit();
   end; // Create()


// *************************************************************************
// * Init() - Initialize the class - Child classes override and add extra 
// * fields here.  Set AddEndMsgField to true if you want the catchall
// * 'Message' field added as the last column.
// *************************************************************************

procedure tFieldParser.Init();
   begin
      Inherited Init();
      Filter:= '';
      ErrorMsgIndex:= -1; 
      AddEndMsgField:= false; // Mostly for debugging.  It adds the extra field
                             // which will simply read anything left on the line
      IndexDict:= tParserFieldIndexDict.Create( tParserFieldIndexDict.tCompareFunction( @CompareStrings), false);
      FieldList:= tParserFieldList.Create();
      Line:=      1; // Start at the first line.
   end; // Init()


// *************************************************************************
// * PostInit() - Add a single Message field if no Filter was specified
// *************************************************************************

procedure tFieldParser.PostInit();
   begin
      if( AddEndMsgField) then begin
         tParserField.Create( self, 'Message');
      end;     
   end; // PostInit();


// *************************************************************************
// * Destroy() - Destructor
// *************************************************************************

destructor tFieldParser.Destroy();
   begin
      IndexDict.Destroy;
      FieldList.RemoveAll( true);
      FieldList.Destroy;
      inherited Destroy;
   end; // Destroy()


// *************************************************************************
// * ParseLine() - Returns a tCsvCellArray version of the next line
// *************************************************************************

function tFieldParser.ParseLine(): tCsvCellArray;
   var
      Field:  tParserField;
      i:      integer = 0;
      c:      char;
   begin
      repeat
         ErrorInLine:= false;
         i:= 0;
         SetLength( result, FieldList.Length);
         for Field in FieldList do if( not ErrorInLine) then begin
            if( i <> ErrorMsgIndex) then begin
               result[ i]:= Field.Parse();
            end;
            inc( i);
         end;
         SkipRestOfLine();
         if( ErrorInLine and (ErrorMsgIndex >= 0)) then begin
            result[ ErrorMsgIndex]:= RestOfLine;
         end;
         c:= PeekChr;
      until( (not ErrorInLine) or (c = EOFchr));

      // Handle the special case of the last line having an error
      if( ErrorInLine and ( c = EOFchr)) then begin
         SetLength( result, 0);
      end;
   end; // ParseLine();


// *************************************************************************
// * Header() - Returns an array of header names in the order they appear 
// *            in the CSV.  Returns an empty array if the Header hasn't
// *            been parsed.
// *************************************************************************

function tFieldParser.Header():  tCsvCellArray;
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

function tFieldParser.SortedHeader(): tCsvCellArray;
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
// * FieldExists() - Returns true if the passed Name is a field.
// *************************************************************************

function tFieldParser.FieldExists( Name: string): boolean;
   begin
      result:= IndexDict.Find( Name);
   end; // FieldExists()


// *************************************************************************
// * IndexOf() - Returns the field number of the passed field name
// *************************************************************************

function tFieldParser.IndexOf( Name: string): integer;
   begin
      result:= IndexDict.Items[ Name];
   end; // IndexOf()


// *************************************************************************
// * SkipRestOfLine() - Bypass anything remaining on the current line
// *************************************************************************

procedure tFieldParser.SkipRestOfLine();
   begin
      // Discard characters until LF, CR, or EOF is the next one.
      RestOfLine:= ParseElement( IntraLineAnsiChrs);
      // Skip LF and CR characters
      while( PeekChr in InterLineWhiteChrs) do Chr;
      Inc( LineNumber);
   end;   // SkipRestOfLine()




// =========================================================================
// = tParserField class
// =========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tParserField.Create( iParent: tParserField; iName: string);
   begin
      inherited Create();
      Name:= iName;
      Parent:= iParent;
      Parent.SubFields.Queue:= self;
      Parser:= Parent.Parser;
      Init();
   end; // Create()

// -------------------------------------------------------------------------

constructor tParserField.Create( iParser: tFieldParser; iName: string);
   var
      L: integer;
   begin
      inherited Create();
      Name:= iName;
      Parent:= nil;
      Parser:= iParser;

      // Add the field to the parser
      L:= Parser.FieldList.Length;
      Parser.FieldList.Queue:=  self;
      Parser.IndexDict.Add( Name, L);

      Init();
   end; // Create()


// *************************************************************************
// * Destroy() - Destructor
// *************************************************************************

destructor tParserField.Destroy();
   begin
      SubFields.RemoveAll( true);
      SubFields.Destroy;
      inherited Destroy;
   end; // Destroy()


// *************************************************************************
// * Init() - Child classes verride this rather than the constructor. 
// *           By Default we parse the whole rest of the line  
// *************************************************************************

procedure tParserField.Init();
   begin
      SubFields:= tParserFieldList.Create();

      ValidSet:= IntraLineAnsiChrs;
      EndSet:= EndOfLineChrs;
      MinLength:= 0;
      MaxLength:= High( Integer);
   end; // Init()


// *************************************************************************
// * Parse() - The field is the rest of the current line.
// *************************************************************************

function tParserField.Parse(): string;
   var
      c: char;
   begin
      result:= Parser.ParseElement( ValidSet);
      c:= Parser.PeekChr;
      // Remove the field end character unless it is an EndOfLine.
      if( c in EndSet) then begin
         if( not (c in EndOfLineChrs)) then begin
            Parser.Chr; // discard it
         end;
      end else begin
         ReportError( Format( 'The ''%s'' field contains invalid characters or the field separator is invalid!', [Name]));
      end;

      Verify( result);
   end; // Parse()


// *************************************************************************
// * Verify() - Run checks to make sure the field's value is valid.
// *************************************************************************

procedure tParserField.Verify( iField: string);
   var
      L: integer;
   begin
      L:= Length( iField);
      if( L < MinLength) then ReportError( Format( 'The ''%s'' Field was too short.', [Name]));
      if( L > MaxLength) then ReportError( Format( 'The ''%s'' Field was too long.', [Name]));
   end; // Verify()


// *************************************************************************
// * ReportError() - Sets the parser's error state and if the --show-parse
// *************************************************************************

procedure tParserField.ReportError( ExtraMessage: string);
   var
      TheParent: tParserField;
   begin
      // Propagate the errror all the way back to the parser
      TheParent:= self;
      while( TheParent <> nil) do begin
//         TheParent.ErrorInField:= true;
         TheParent:= TheParent.Parent;
      end;
      Parser.ErrorInLine:= true;

      if( Parser.ShowParseErrors) then begin
         writeln( StdErr,
                  Format( 'At line %u the ''%s'' field is malformed!  %s',
                  [ Parser.Line, Name, ExtraMessage]));
     end;
     if( not Parser.SkipUnknownLines) then begin
        raise ParseException.Create( 
                  'At line %u the ''%s'' field is malformed!  %s',
                  [ Parser.Line, Name, ExtraMessage]);
     end;
   end; // ReportError



// *************************************************************************

end.  // lbp_field_parser unit
