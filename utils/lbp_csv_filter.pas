{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Defines Filters to modify CSV files

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
unit lbp_csv_filter;

// Classes to handle Comma Separated Value strings and files.

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_argv,
   lbp_types,
   lbp_generic_containers,
   lbp_parse_helper, // CurrencyChrs
   lbp_csv_filter_aux,
   lbp_csv,
   lbp_ip_utils,
   regexpr,  // Regular expressions
   classes,
   sysutils;


// *************************************************************************

type
   tCsvFilter = class( tObject)
      protected
         NextFilter:    tCsvFilter;
         procedure Go(); virtual;
      public
         procedure SetInputHeader( Header: tCsvCellArray); virtual;
         procedure SetRow( Row: tCsvCellArray); virtual;
      end; // tCsvFilter
      

// *************************************************************************

type
   tCsvFilterQueueParent = specialize tgDoubleLinkedList< tCsvFilter>;
   tCsvFilterQueue = class( tCsvFilterQueueParent)
      public
         Destructor  Destroy(); override;
         procedure   Go(); virtual;
      end; // tCsvFilterQueue
      

// *************************************************************************

type
   tCsvInputFileFilter = class( tCsvFilter)
      protected
         Csv: tCsv;
         procedure Go(); override;
      public
         constructor Create( iStream: tStream; iDestroyStream: boolean = true);
         constructor Create( iString: string; IsFileName: boolean = false);
         constructor Create( var iFile:   text);
         destructor  Destroy(); override;
         procedure   SetInputDelimiter( iD: char);
         procedure   SetSkipNonPrintable( Skip: boolean);
      end; // tCsvInputFileFilter


// *************************************************************************

type
   tCsvOutputFileFilter = class( tCsvFilter)
      protected
         CloseOnDestroy:  boolean;
         OutputFile:      Text;
         OutputDelimiter: char;
      public
         constructor Create( iFileName: string);
         constructor Create( var iFile:   text);
         destructor  Destroy(); override;
         procedure   SetInputHeader( Header: tCsvCellArray); override;
         procedure   SetRow( Row: tCsvCellArray); override;
         procedure   SetOutputDelimiter( oD: char);
      end; // tCsvOutputFileFilter


// *************************************************************************
// * tCsvReorderFilter class - Specify a new header with fields in whatever
// *    order you desire.  New fields are added to rows with empty values.
// *    For complex situations where multiple different csv's with slightly
// *    different input headers are being combined, this filter will allow 
// *    multiple calls to SetInputHeader, but will only NewHeader() to the 
// *    next filter once. 
// *************************************************************************

type
   tCsvReorderFilter = class( tCsvFilter)
      protected
         HeaderSent: boolean;
         NewHeader:  tCsvCellArray;
         AllowNew:   boolean; // Allow new blank columns
         IndexMap:   tIntegerArray;
         NewLength:  integer;
      public
         Constructor Create( iNewHeader: tCsvCellArray; iAllowNew: boolean);
         constructor Create( iNewHeader: string; iAllowNew: boolean);
         procedure   SetInputHeader( Header: tCsvCellArray); override;
         procedure   SetRow( Row: tCsvCellArray); override;
      end; // tCsvReorderFilter


// *************************************************************************
// * tCsvUniqueFilter class - Only output's unique rows.  All unique rows
// * are stored in memory.  Be careful with large files!
// *************************************************************************

type
   tCsvUniqueFilter = class( tCsvFilter)
      protected
         UniqueTree: tStringTree;
      public
         constructor Create();
         destructor  Destroy(); override;
         procedure   SetRow( Row: tCsvCellArray); override;
      end; // tCsvUniqueFilter


// *************************************************************************
// * tCsvRenameFilter class - Rename the passed iInputFields to iOutputFields.
// *    Row data in unchanged. 
// *************************************************************************

type
   tCsvRenameFilter = class( tCsvFilter)
      protected
         InputFields:   tCsvCellArray;
         OutputFields:  tCsvCellArray;
         HeaderSent:    boolean;
      public
         Constructor Create( iInputFields, iOutputFields: tCsvCellArray);
         constructor Create( iInputFields, iOutputFields: string);
         procedure   SetInputHeader( Header: tCsvCellArray); override;
      end; // tCsvRenameFilter


// *************************************************************************
// tCsvGrepFilter class - Use regular expressions to seach through fields
// *************************************************************************

type
   tCsvGrepFilter = class( tCsvFilter)
      protected
         GrepFields:   tCsvCellArray;
         GrepIndexes:  tIntegerArray;
         RegExpr:      tRegExpr;
         InvertMatch:  boolean;
      public
         Constructor Create( iGrepFields:  tCsvCellArray;
                             iRegExpr:     string;
                             iInvertMatch: boolean = false;
                             iIgnoreCase:  boolean = false);
         Constructor Create( iGrepFields:  string;
                             iRegExpr:     string;
                             iInvertMatch: boolean = false;
                             iIgnoreCase:  boolean = false);
         Destructor  Destroy(); override;
         procedure   SetInputHeader( Header: tCsvCellArray); override;
         procedure   SetRow( Row: tCsvCellArray); override;
      end; // tCsvGrepFilter


// *************************************************************************
// * tCsvStringSortFilter()
// *************************************************************************

type
   tCsvStringSortFilter = class( tCsvFilter)
      protected type
         tRowTree = specialize tgAvlTree< tCsvStringRowTuple>;
      protected
         FieldName:        string;
         FieldIndex:       integer;
         Reverse:          boolean; // output in reverse order
         CaseInsensitive:  boolean; // sort case insensitive
         RowTree:          tRowTree;
      public
         constructor Create( iField:           string; 
                             iReverse:         boolean = false;
                             iCaseInsensitive: boolean = false);
         destructor  Destroy(); override;
         procedure   SetInputHeader( Header: tCsvCellArray); override;
         procedure   SetRow( Row: tCsvCellArray); override;
      end; // tCsvStringSortFilter


// *************************************************************************
// * tCsvInt32SortFilter()
// *************************************************************************

type
   tCsvInt32SortFilter = class( tCsvFilter)
      protected type
         tRowTree = specialize tgAvlTree< tCsvInt32RowTuple>;
      protected
         FieldName:        string;
         FieldIndex:       integer;
         Reverse:          boolean; // output in reverse order
         RowTree:          tRowTree;
      public
         constructor Create( iField:           string; 
                             iReverse:         boolean = false);
         destructor  Destroy(); override;
         procedure   SetInputHeader( Header: tCsvCellArray); override;
         procedure   SetRow( Row: tCsvCellArray); override;
      end; // tCsvInt32SortFilter


// *************************************************************************
// * tCsvInt64SortFilter()
// *************************************************************************

type
   tCsvInt64SortFilter = class( tCsvFilter)
      protected type
         tRowTree = specialize tgAvlTree< tCsvInt64RowTuple>;
      protected
         FieldName:        string;
         FieldIndex:       integer;
         Reverse:          boolean; // output in reverse order
         RowTree:          tRowTree;
      public
         constructor Create( iField:           string; 
                             iReverse:         boolean = false);
         destructor  Destroy(); override;
         procedure   SetInputHeader( Header: tCsvCellArray); override;
         procedure   SetRow( Row: tCsvCellArray); override;
      end; // tCsvInt64SortFilter


// *************************************************************************
// * tCsvWord32SortFilter()
// *************************************************************************

type
   tCsvWord32SortFilter = class( tCsvFilter)
      protected type
         tRowTree = specialize tgAvlTree< tCsvWord32RowTuple>;
      protected
         FieldName:        string;
         FieldIndex:       integer;
         Reverse:          boolean; // output in reverse order
         RowTree:          tRowTree;
      public
         constructor Create( iField:           string; 
                             iReverse:         boolean = false);
         destructor  Destroy(); override;
         procedure   SetInputHeader( Header: tCsvCellArray); override;
         procedure   SetRow( Row: tCsvCellArray); override;
      end; // tCsvWord32SortFilter


// *************************************************************************
// * tCsvWord64SortFilter()
// *************************************************************************

type
   tCsvWord64SortFilter = class( tCsvFilter)
      protected type
         tRowTree = specialize tgAvlTree< tCsvWord64RowTuple>;
      protected
         FieldName:        string;
         FieldIndex:       integer;
         Reverse:          boolean; // output in reverse order
         RowTree:          tRowTree;
      public
         constructor Create( iField:           string; 
                             iReverse:         boolean = false);
         destructor  Destroy(); override;
         procedure   SetInputHeader( Header: tCsvCellArray); override;
         procedure   SetRow( Row: tCsvCellArray); override;
      end; // tCsvWord64SortFilter


// *************************************************************************
// * tCsvCurrencySortFilter()
// *************************************************************************

type
   tCsvCurrencySortFilter = class( tCsvFilter)
      protected type
         tRowTree = specialize tgAvlTree< tCsvCurrencyRowTuple>;
      protected
         FieldName:        string;
         FieldIndex:       integer;
         Reverse:          boolean; // output in reverse order
         RowTree:          tRowTree;
      public
         constructor Create( iField:           string; 
                             iReverse:         boolean = false);
         destructor  Destroy(); override;
         procedure   SetInputHeader( Header: tCsvCellArray); override;
         procedure   SetRow( Row: tCsvCellArray); override;
      end; // tCsvCurrencySortFilter


// *************************************************************************
// * tCsvIpv4SortFilter()
// *************************************************************************

type
   tCsvIpv4SortFilter = class( tCsvWord32SortFilter)
      private
         IgnoreFailures: boolean;
      public
         constructor Create( iField:           string; 
                             iReverse:         boolean = false;
                             iIgnoreFailures:  boolean = false);
         procedure   SetRow( Row: tCsvCellArray); override;
      end; // tCsvIpv4SortFilter


// *************************************************************************
// * tCsvSetFieldFilter()
// *************************************************************************

type
   tCsvSetFieldFilter = class( tCsvFilter)
      private
         Values:       tCsvCellArray;
         Fields:       tCsvCellArray; 
         FieldLength:  integer; 
         Indexes:      tIntegerArray;
         AllCells:     boolean;
      public
         constructor Create( iFieldCsv: string;
                             iValueCsv: string;
                             iAllCells: boolean = false);
         procedure   SetInputHeader( Header: tCsvCellArray); override;
         procedure   SetRow( Row: tCsvCellArray); override;
      end; // tCsvSetFieldFilter


// *************************************************************************
// * tCsvStripEmptyRowFilter class - Strips out rows where every field is
// *                                  an empty string.
// *************************************************************************

type
   tCsvStripEmptyRowFilter = class( tCsvFilter)
      public
         procedure   SetRow( Row: tCsvCellArray); override;
   end; // tCsvStripEmptyRowFilter


// *************************************************************************
// * tCsvSequenceFilter class - Replaces the values in a singel field with
// *                            a sequence number. 
// *************************************************************************

type
   tCsvSequenceFilter  = class( tCsvFilter)
      protected
         FieldName:     string;
         FieldIndex:    integer;
         CurrentValue:  int64;
      public
         constructor Create( Field: string; InitialValue: string);
         constructor Create( Field: string; InitialValue: int64);
         procedure   SetInputHeader( Header: tCsvCellArray); override;
         procedure   SetRow( Row: tCsvCellArray); override;
   end; // tCsvSequenceFilter 


// *************************************************************************

implementation

// ========================================================================
// = tCsvFilter class
// ========================================================================
// *************************************************************************
// * SetInputHeader() - The default is just to pass the header through to
// *    the next filter.  If the child modified the header, it should 
// *    override this procedure and NOT call the inherited version.  It 
// *    should then pass the new/modified header to NextFilter
// *************************************************************************

procedure tCsvFilter.SetInputHeader( Header: tCsvCellArray);
   begin
      NextFilter.SetInputHeader( Header);
   end; // SetInputHeader


// *************************************************************************
// * SetRow() - The default is just to pass the row through to
// *    the next filter.  If the child modified the row, it should 
// *    override this procedure and NOT call the inherited version.  It 
// *    should then pass the new/modified row to NextFilter
// *************************************************************************

procedure tCsvFilter.SetRow( Row: tCsvCellArray);
   begin
      NextFilter.SetRow( Row);
   end; // SetRow()


// *************************************************************************
// * Go() - For the input filter only, Go reads the input and calls 
// *        the next filter's SetInputHeader() once and SetRow() for each row. 
// *************************************************************************

procedure tCsvFilter.Go();
   begin
      raise tCsvException.Create( 'tCsvFilter.Go() should only be implemented and called for the first class in the filter which starts to process going!  Do not use inherited Go()!')
   end; // Go()



// ========================================================================
// = tCsvFilterQueue class
// ========================================================================
// *************************************************************************
// * Destroy() - Destructor
// *************************************************************************

destructor tCsvFilterQueue.Destroy();
   var
      Filter: tCsvFilter;
   begin
      while( not IsEmpty) do begin
         Filter:= Queue;
         Filter.Destroy();
      end;
      inherited Destroy();
   end; // Destroy()


// *************************************************************************
// * Go() - Start the filter.  As a side effect it cleans up all contained 
// *        tCsvFilters and empties itself.        
// *************************************************************************

procedure tCsvFilterQueue.Go();
   var
      PrevFilter:  tCsvFilter;
      Filter:      tCsvFilter;
   begin
      if( Self.Length < 2) then raise tCsvException.Create( 'tCsvFilterQueue.Go() - At least an input and output filter must be in the queue!');
      // Set each filter's NextFilter
      PrevFilter:= nil;
      for Filter in self do begin
         if( PrevFilter <> nil) then PrevFilter.NextFilter:= Filter;        
         PrevFilter:= Filter;
//         writeln( 'tCsvFilterQueue.Go():  Filter class name = ', PrevFilter.ClassName);
      end;
      PrevFilter.NextFilter:= nil;  // The last filter has no nextfilter
      
      // Process the rows
      Filter:= Queue;
      Filter.Go(); // Only the input filter should have a working go function

      // Clean up after ourselves
      Filter.Destroy;
      while( not IsEmpty()) do begin
         Filter:= Queue;
         Filter.Destroy;
      end; 
   end; // Go



// ========================================================================
// = tCsvInputFileFilter class
// ========================================================================
// *************************************************************************
// * Create() - constructors
// *************************************************************************

constructor tCsvInputFileFilter.Create( iStream: tStream; iDestroyStream: boolean);
   begin
      inherited Create();
      Csv:= tCsv.Create( iStream, iDestroyStream);
   end; // Create()

// -------------------------------------------------------------------------

constructor tCsvInputFileFilter.Create( iString: string; IsFileName: boolean);
   begin
      inherited Create();
      Csv:= tCsv.Create( iString, IsFileName);
   end; // Create()


// -------------------------------------------------------------------------

constructor tCsvInputFileFilter.Create( var iFile: text);
   begin
      inherited Create();
      Csv:= tCsv.Create( iFile);
   end; // Create()


// *************************************************************************
// * Destroy() - destructor
// *************************************************************************

destructor tCsvInputFileFilter.Destroy();
   begin
      Csv.Destroy();
      inherited Destroy();
   end; // Destroy()


// *************************************************************************
// * Go() - Performs the actual CSV reading and sends the header and rows
// *        to the next filter
// *************************************************************************

procedure tCsvInputFileFilter.Go();
   var
      Temp:  tCsvCellArray;
      C:     char;
   begin
      Csv.ParseHeader();
      NextFilter.SetInputHeader( Csv.Header);
      repeat
         Temp:= Csv.ParseRow();
         if( Length( Temp) > 0) then NextFilter.SetRow( Temp);
         C:= Csv.PeekChr();
      until( C = EOFchr);
   end; // Go()


// *************************************************************************
// * SetInputDelimiter() - Sets the delimiter for use in the input CSV
// *************************************************************************

procedure tCsvInputFileFilter.SetInputDelimiter( iD: char);
   begin
      Csv.Delimiter:= iD;
   end; // SetInputDelimiter()


// *************************************************************************
// * SetInputDelimiter() - Sets the delimiter for use in the input CSV
// *************************************************************************

procedure tCsvInputFileFilter.SetSkipNonPrintable( Skip: boolean);
   begin
      Csv.SkipNonPrintable:= Skip;
   end; // SetSkipNonPrintable()



// ========================================================================
// = tCsvOutputFileFilter class
// ========================================================================
// *************************************************************************
// * Create() - constructors
// *************************************************************************

constructor tCsvOutputFileFilter.Create( iFileName: string);
   begin
      inherited Create();
      CloseOnDestroy:= true;
      OutputDelimiter:= lbp_csv.CsvDelimiter;
      Assign( OutputFile, iFileName);
      Rewrite( OutputFile);
   end; // Create()


// -------------------------------------------------------------------------

constructor tCsvOutputFileFilter.Create( var iFile: text);
   begin
      inherited Create();
      CloseOnDestroy:= false;
      OutputDelimiter:= lbp_csv.CsvDelimiter;

      // This is a fix for the case of StdOut.  For some reason even though
      // The file handle is correct, if we use iFile it will print to stdout, 
      // but doesn't work with pipes.  This method fixes it.
      if( TextRec( iFile).Handle = 1) then begin
         OutputFile:= System.Output;
      end else begin
         OutputFile:= iFile;
      end;
//      OutputFile:= iFile;
   end; // Create()


// *************************************************************************
// * Destroy() - destructor
// *************************************************************************

destructor tCsvOutputFileFilter.Destroy();
   begin
      if( CloseOnDestroy) then Close( OutputFile);
      inherited Destroy();
   end; // Destroy


// *************************************************************************
// * SetInputHeader() - Simply output the header
// *************************************************************************

procedure tCsvOutputFileFilter.SetInputHeader( Header: tCsvCellArray);
   begin
      writeln( Output, Header.ToCsv(OutputDelimiter));
   end; // SetInputHeader()


// *************************************************************************
// * SetRow() - Simply output the header
// *************************************************************************

procedure tCsvOutputFileFilter.SetRow( Row: tCsvCellArray);
   begin
     writeln( Output, Row.ToCsv( OutputDelimiter));
   end; // SetRow()


// *************************************************************************
// * SetOutputDelimiter() - Sets the delimiter for use in the output CSV
// *************************************************************************

procedure tCsvOutputFileFilter.SetOutputDelimiter( oD: char);
   begin
      OutputDelimiter:= oD;
   end; // SetOuputDelimiter()



// ========================================================================
// = tCsvReorderFilter class
// ========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCsvReorderFilter.Create( iNewHeader: tCsvCellArray; 
                                      iAllowNew: boolean);
   begin
      inherited Create();
      NewHeader:=  iNewHeader;
      NewLength:=  Length( NewHeader);
      AllowNew:=   iAllowNew;
      HeaderSent:= false;
      if( NewLength = 0) then lbp_argv.Usage( true, HeaderZeroLengthError);
   end; // Create()

// -------------------------------------------------------------------------

constructor tCsvReorderFilter.Create( iNewHeader: string; iAllowNew: boolean);
   begin
      inherited Create();
      NewHeader:=  StringToCsvCellArray( iNewHeader);
      NewLength:=  Length( NewHeader);
      AllowNew:=   iAllowNew;
      HeaderSent:= false;
      if( NewLength = 0) then lbp_argv.Usage( true, HeaderZeroLengthError);
   end; // Create()


// *************************************************************************
// * SetInputHeader() - Simply output the header
// *************************************************************************

procedure tCsvReorderFilter.SetInputHeader( Header: tCsvCellArray);
   var
      HeaderDict: tHeaderDict;
      Name:       string;
      i:          integer;
      iMax:       integer;
      ErrorMsg:   string;
   begin
      // Create and populate the temorary lookup tree
      HeaderDict:= tHeaderDict.Create( tHeaderDict.tCompareFunction( @CompareStrings));
      HeaderDict.AllowDuplicates:= false;
      iMax:= Length( Header) - 1;
      for i:= 0 to iMax do HeaderDict.Add( Header[ i], i);

      // Create and populate the IndexMap;
      iMax:= NewLength - 1;
      SetLength( IndexMap, NewLength);
      for i:= 0 to iMax do begin
         Name:= NewHeader[ i];
         // Is the new header field in the old headers?
         if( HeaderDict.Find( Name)) then begin
            IndexMap[ i]:= HeaderDict.Value();
         end else begin
            if( AllowNew) then begin
               IndexMap[ i]:= -1; 
            end else begin
               ErrorMsg:= sysutils.Format( HeaderUnknownField, [Name]);
               lbp_argv.Usage( true, ErrorMsg);
            end;
         end; // if/else New Header field was found in the on header 
      end; // for

      // Clean up the HeaderDict
      HeaderDict.RemoveAll();
      HeaderDict.Destroy();
 
      // Pass the new header to the next filter
      if( not HeaderSent) then begin
         NextFilter.SetInputHeader( NewHeader);
         HeaderSent:= true;
      end;
   end; // SetInputHeader()


// *************************************************************************
// * SetRow() - Simply output the header
// *************************************************************************

procedure tCsvReorderFilter.SetRow( Row: tCsvCellArray);
   var
      NewRow: tCsvCellArray;
      iMax:   integer;
      iOld:   integer;
      iNew:   integer;
   begin
      SetLength( NewRow, NewLength);
      // Trasfer fields from Row to NewRow;
      iMax:= NewLength - 1;
      for iNew:= 0 to iMax do begin
         iOld:= IndexMap[ iNew];
         if( iOld < 0) then NewRow[ iNew]:= '' else NewRow[ iNew]:= Row[ iOld];
      end;
      NextFilter.SetRow( NewRow);
   end; // SetRow()



// ========================================================================
// = tCsvUniqueFilter class
// ========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCsvUniqueFilter.Create();
   begin
      inherited Create();
      UniqueTree:= tStringTree.Create( tStringTree.tCompareFunction( @CompareStrings));
   end; // Create()


// *************************************************************************
// * Destroy() - destructor
// *************************************************************************

destructor tCsvUniqueFilter.Destroy();
   begin
      UniqueTree.RemoveAll;
      UniqueTree.Destroy;
      inherited Destroy;
   end; // Destroy()

// *************************************************************************
// * SetRow()
// *************************************************************************

procedure tCsvUniqueFilter.SetRow( Row: tCsvCellArray);
   var
      RowStr: string;
   begin
      RowStr:= Row.ToCsv( ',');

      // If we haven't seen this row before     
      if( not UniqueTree.Find( RowStr)) then begin
         UniqueTree.Add( RowStr);
         NextFilter.SetRow( Row);
      end;
   end;  // SetRow()



// ========================================================================
// = tCsvRenameFilter class
// ========================================================================
var
   RenameLengthMismatchError: string =
   'The number of input and output fields must be the same!';
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCsvRenameFilter.Create( iInputFields, iOutputFields: tCsvCellArray); 
   begin
      inherited Create();
      InputFields:=  iInputFields;
      OutputFields:= iOutputFields;
      if( Length( InputFields) <> Length( OutputFields)) then begin
         lbp_argv.Usage( true, RenameLengthMismatchError);
      end;
      HeaderSent:= false;
   end; // Create()

// -------------------------------------------------------------------------

constructor tCsvRenameFilter.Create( iInputFields, iOutputFields: string);
   begin
      inherited Create();
      InputFields:=  StringToCsvCellArray( iInputFields);
      OutputFields:= StringToCsvCellArray( iOutputFields);      
      if( Length( InputFields) <> Length( OutputFields)) then begin
         lbp_argv.Usage( true, RenameLengthMismatchError);
      end;
      HeaderSent:= false;
   end; // Create()


// *************************************************************************
// * SetInputHeader() - Simply output the header
// *************************************************************************

procedure tCsvRenameFilter.SetInputHeader( Header: tCsvCellArray);
   var
      i:        integer;
      HI:       integer; // Header index
      HIMax:    integer;
      FI:       integer; // Field index
      FIMax:    integer;
      Found:    boolean;
      ErrorStr: string;
   begin
      HIMax:= Length( Header) - 1;
      FIMax:= length( InputFields) - 1;

      // For each Input field;
      for FI:= 0 to FIMax do begin
         // Find the Header Index
         HI:= 0;
         i:= 0;
         Found:= false;
         while( (not Found) and (i <= HIMax)) do begin
            if( Header[ i] = InputFields[ FI]) then begin
               Found:= true;
               HI:= i;
            end; // if
            inc( i);
         end; // While searching for the matching header field
         if( not Found) then begin
            ErrorStr:= Format( HeaderUnknownField, [InputFields[ FI]]);
            lbp_argv.Usage( true, ErrorStr);
         end;
         Header[ HI]:= OutputFields[ FI];
      end; // For each InputField

      // Pass the new header to the next filter
      if( not HeaderSent) then begin
         NextFilter.SetInputHeader( Header);
         HeaderSent:= true;
      end;
   end; // SetInputHeader()



// ========================================================================
// = tCsvGrepFilter class
// ========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCsvGrepFilter.Create( iGrepFields:  tCsvCellArray; 
                                   iRegExpr:     string;
                                   iInvertMatch: boolean = false;
                                   iIgnoreCase:  boolean = false);
   begin
      inherited Create();
      GrepFields:=        iGrepFields;
      InvertMatch:=       iInvertMatch;
      RegExpr:=           tRegExpr.Create( iRegExpr);
      RegExpr.ModifierI:= iIgnoreCase;
      RegExpr.ModifierM:= true; // start and end line works for each line in a multi-line field
   end; // Create()

// -------------------------------------------------------------------------

constructor tCsvGrepFilter.Create( iGrepFields:  string; 
                                   iRegExpr:     string;
                                   iInvertMatch: boolean = false;
                                   iIgnoreCase:  boolean = false);
   begin
      inherited Create();
      GrepFields:=        StringToCsvCellArray( iGrepFields);
      InvertMatch:=       iInvertMatch;
      RegExpr:=           tRegExpr.Create( iRegExpr);
      RegExpr.ModifierI:= iIgnoreCase;
      RegExpr.ModifierM:= true; // start and end line works for each line in a multi-line field
   end; // Create()


// *************************************************************************
// * Destroy() - destructor
// *************************************************************************

destructor tCsvGrepFilter.Destroy();
   begin
      RegExpr.Destroy();
      inherited Destroy;
   end; // Destroy()


// *************************************************************************
// * SetInputHeader()
// *************************************************************************

procedure tCsvGrepFilter.SetInputHeader( Header: tCsvCellArray);
   var 
      HL:       integer; // Header Length
      GFL:      integer; // Grep fields Length;
      HI:       integer; // Header index
      GFI:      integer; // Grep fields index;
      Found:    boolean;
      ErrorMsg: string;
   begin
      // If an empty GrepFields was passed to Create(), then we use all the fields
      HL:=  Length( Header);
      GFL:= Length( GrepFields);
      if( GFL = 0) then begin
         GFL:= HL;
         GrepFields:= Header;
      end;
      SetLength( GrepIndexes, GFL);
      
      // For each Grep Field
      GFI:= 0;
      while( GFI < GFL) do begin
         HI:= 0;
         Found:= false;
  
         // for each Header
         while( (not found) and (HI < HL)) do begin
            if( Header[ HI] = GrepFields[ GFI]) then begin
               Found:= true;
               GrepIndexes[ GFI]:= HI;
            end;
            inc( HI);
         end; // while Header
  
         if( Found) then begin
            
         end else begin
            ErrorMsg:= Format( HeaderUnknownField, [GrepFields[ GFI]]);
            lbp_argv.Usage( true, ErrorMsg);
         end;

         inc( GFI);  
      end; // while GrepFields

      NextFilter.SetInputHeader( Header);
   end; // SetInputHeader


// *************************************************************************
// * SetRow() - Only pass rows that match the regexpr pattern
// *************************************************************************

procedure tCsvGrepFilter.SetRow( Row: tCsvCellArray);
   var
      Found: boolean = false;
      i:     integer;
   begin
      for i in GrepIndexes do begin
         if( RegExpr.Exec( Row[ i])) then Found:= true;
      end;

      if( Found xor InvertMatch) then NextFilter.SetRow( Row);
   end; // SetRow()



// ========================================================================
// = tCsvStringSortFilter class
// ========================================================================
// *************************************************************************
// * CompareStringRowTuple() - Global function to support sorting
// *************************************************************************

function CompareStringRowTuple( T1, T2: tCsvStringRowTuple): integer;
   begin
      if( T1.key > T2.key) then begin
         result:= 1;
      end else if( T1.key < T2.key) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareStringRowTuple();


// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCsvStringSortFilter.Create( iField:           string; 
                                         iReverse:         boolean = false;
                                         iCaseInsensitive: boolean = false);
   var
      Func: tRowTree.tCompareFunction;
   begin
      inherited Create();
      FieldName:=       iField;
      Reverse:=         iReverse;
      CaseInsensitive:= iCaseInsensitive;
      Func:=            tRowTree.tCompareFunction( @CompareStringRowTuple);
      RowTree:=         tRowTree.Create( Func, true);
   end; // Create()


// *************************************************************************
// * Destroy() - destructor - Does the actual output
// *************************************************************************

destructor tCsvStringSortFilter.Destroy();
   begin
      if( Reverse) then begin
        while RowTree.Previous() do begin
           NextFilter.SetRow( RowTree.Value.Row);
        end;
      end else begin
        while RowTree.Next() do begin
           NextFilter.SetRow( RowTree.Value.Row);
        end;
      end;

      RowTree.RemoveAll( true);
      RowTree.Destroy();
   end; // Destroy();


// *************************************************************************
// * SetInputHeader() - Find the Field Index and then pass the header to the
// *                    next filter.
// *************************************************************************

procedure tCsvStringSortFilter.SetInputHeader( Header: tCsvCellArray);
   var
      i:     integer;
      iMax:  integer;
      Found: boolean;
   begin
      i:= 0;
      iMax:= Length( Header) - 1;
      Found:= false;
      while( (not Found) and (i <= iMax)) do begin
         if( Header[ i] = FieldName) then begin
             Found:= true;
             FieldIndex:= i;
         end;
         inc( i);
      end;

      if( not Found) then Usage( true, Format( HeaderUnknownField, [FieldName]));

      NextFilter.SetInputHeader( Header);
   end; // SetInputHeader();


// *************************************************************************
// * SetRow() - Add the row to the tree
// *************************************************************************

procedure tCsvStringSortFilter.SetRow( Row: tCsvCellArray);
   var
      Field: string;
      RowTuple: tCsvStringRowTuple;
   begin
      RowTuple:= tCsvStringRowTuple.Create();
      Field:= Row[ FieldIndex];
      if( CaseInsensitive) then Field:= LowerCase( Field);
      RowTuple.Key:= Field;
      RowTuple.Row:= Row;
      RowTree.Add( RowTuple);
   end; // SetRow();



// ========================================================================
// = tCsvInt32SortFilter class
// ========================================================================
// *************************************************************************
// * CompareInt32RowTuple() - Global function to support sorting
// *************************************************************************

function CompareInt32RowTuple( T1, T2: tCsvInt32RowTuple): integer;
   begin
      if( T1.key > T2.key) then begin
         result:= 1;
      end else if( T1.key < T2.key) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareInt32RowTuple();


// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCsvInt32SortFilter.Create( iField:           string; 
                                         iReverse:         boolean = false);
   var
      Func: tRowTree.tCompareFunction;
   begin
      inherited Create();
      FieldName:=       iField;
      Reverse:=         iReverse;
      Func:=            tRowTree.tCompareFunction( @CompareInt32RowTuple);
      RowTree:=         tRowTree.Create( Func, true);
   end; // Create()


// *************************************************************************
// * Destroy() - destructor - Does the actual output
// *************************************************************************

destructor tCsvInt32SortFilter.Destroy();
   begin
      if( Reverse) then begin
        while RowTree.Previous() do begin
           NextFilter.SetRow( RowTree.Value.Row);
        end;
      end else begin
        while RowTree.Next() do begin
           NextFilter.SetRow( RowTree.Value.Row);
        end;
      end;

      RowTree.RemoveAll( true);
      RowTree.Destroy();
   end; // Destroy();


// *************************************************************************
// * SetInputHeader() - Find the Field Index and then pass the header to the
// *                    next filter.
// *************************************************************************

procedure tCsvInt32SortFilter.SetInputHeader( Header: tCsvCellArray);
   var
      i:     integer;
      iMax:  integer;
      Found: boolean;
   begin
      i:= 0;
      iMax:= Length( Header) - 1;
      Found:= false;
      while( (not Found) and (i <= iMax)) do begin
         if( Header[ i] = FieldName) then begin
             Found:= true;
             FieldIndex:= i;
         end;
         inc( i);
      end;

      if( not Found) then Usage( true, Format( HeaderUnknownField, [FieldName]));

      NextFilter.SetInputHeader( Header);
   end; // SetInputHeader();


// *************************************************************************
// * SetRow() - Add the row to the tree
// *************************************************************************

procedure tCsvInt32SortFilter.SetRow( Row: tCsvCellArray);
   var
      Field: string;
      Temp:  Int64;
      RowTuple: tCsvInt32RowTuple;
   begin
      RowTuple:= tCsvInt32RowTuple.Create();
      Field:= Row[ FieldIndex];
      Temp:= Field.ToInt64;
      if( (Temp > MaxInt32) or (Temp < MinInt32)) then begin
         raise tCsvException.Create( RangeErrorInt32, [Field]);
      end;
      RowTuple.Key:= Int32( Temp);
      RowTuple.Row:= Row;
      RowTree.Add( RowTuple);
   end; // SetRow();



// ========================================================================
// = tCsvInt64SortFilter class
// ========================================================================
// *************************************************************************
// * CompareInt64RowTuple() - Global function to support sorting
// *************************************************************************

function CompareInt64RowTuple( T1, T2: tCsvInt64RowTuple): integer;
   begin
      if( T1.key > T2.key) then begin
         result:= 1;
      end else if( T1.key < T2.key) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareInt64RowTuple();


// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCsvInt64SortFilter.Create( iField:           string; 
                                        iReverse:         boolean = false);
   var
      Func: tRowTree.tCompareFunction;
   begin
      inherited Create();
      FieldName:=       iField;
      Reverse:=         iReverse;
      Func:=            tRowTree.tCompareFunction( @CompareInt64RowTuple);
      RowTree:=         tRowTree.Create( Func, true);
   end; // Create()


// *************************************************************************
// * Destroy() - destructor - Does the actual output
// *************************************************************************

destructor tCsvInt64SortFilter.Destroy();
   begin
      if( Reverse) then begin
        while RowTree.Previous() do begin
           NextFilter.SetRow( RowTree.Value.Row);
        end;
      end else begin
        while RowTree.Next() do begin
           NextFilter.SetRow( RowTree.Value.Row);
        end;
      end;

      RowTree.RemoveAll( true);
      RowTree.Destroy();
   end; // Destroy();


// *************************************************************************
// * SetInputHeader() - Find the Field Index and then pass the header to the
// *                    next filter.
// *************************************************************************

procedure tCsvInt64SortFilter.SetInputHeader( Header: tCsvCellArray);
   var
      i:     integer;
      iMax:  integer;
      Found: boolean;
   begin
      i:= 0;
      iMax:= Length( Header) - 1;
      Found:= false;
      while( (not Found) and (i <= iMax)) do begin
         if( Header[ i] = FieldName) then begin
             Found:= true;
             FieldIndex:= i;
         end;
         inc( i);
      end;

      if( not Found) then Usage( true, Format( HeaderUnknownField, [FieldName]));

      NextFilter.SetInputHeader( Header);
   end; // SetInputHeader();


// *************************************************************************
// * SetRow() - Add the row to the tree
// *************************************************************************

procedure tCsvInt64SortFilter.SetRow( Row: tCsvCellArray);
   var
      Field: string;
      RowTuple: tCsvInt64RowTuple;
   begin
      RowTuple:= tCsvInt64RowTuple.Create();
      Field:= Row[ FieldIndex];
      RowTuple.Key:= Field.ToInt64;
      RowTuple.Row:= Row;
      RowTree.Add( RowTuple);
   end; // SetRow();



// ========================================================================
// = tCsvWord32SortFilter class
// ========================================================================
// *************************************************************************
// * CompareWord32RowTuple() - Global function to support sorting
// *************************************************************************

function CompareWord32RowTuple( T1, T2: tCsvWord32RowTuple): integer;
   begin
      if( T1.key > T2.key) then begin
         result:= 1;
      end else if( T1.key < T2.key) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareWord32RowTuple();


// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCsvWord32SortFilter.Create( iField:           string; 
                                        iReverse:         boolean = false);
   var
      Func: tRowTree.tCompareFunction;
   begin
      inherited Create();
      FieldName:=       iField;
      Reverse:=         iReverse;
      Func:=            tRowTree.tCompareFunction( @CompareWord32RowTuple);
      RowTree:=         tRowTree.Create( Func, true);
   end; // Create()


// *************************************************************************
// * Destroy() - destructor - Does the actual output
// *************************************************************************

destructor tCsvWord32SortFilter.Destroy();
   begin
      if( Reverse) then begin
        while RowTree.Previous() do begin
           NextFilter.SetRow( RowTree.Value.Row);
        end;
      end else begin
        while RowTree.Next() do begin
           NextFilter.SetRow( RowTree.Value.Row);
        end;
      end;

      RowTree.RemoveAll( true);
      RowTree.Destroy();
   end; // Destroy();


// *************************************************************************
// * SetInputHeader() - Find the Field Index and then pass the header to the
// *                    next filter.
// *************************************************************************

procedure tCsvWord32SortFilter.SetInputHeader( Header: tCsvCellArray);
   var
      i:     integer;
      iMax:  integer;
      Found: boolean;
   begin
      i:= 0;
      iMax:= Length( Header) - 1;
      Found:= false;
      while( (not Found) and (i <= iMax)) do begin
         if( Header[ i] = FieldName) then begin
             Found:= true;
             FieldIndex:= i;
         end;
         inc( i);
      end;

      if( not Found) then Usage( true, Format( HeaderUnknownField, [FieldName]));

      NextFilter.SetInputHeader( Header);
   end; // SetInputHeader();


// *************************************************************************
// * SetRow() - Add the row to the tree
// *************************************************************************

procedure tCsvWord32SortFilter.SetRow( Row: tCsvCellArray);
   var
      Field: string;
      Temp:  Int64;
      RowTuple: tCsvWord32RowTuple;
   begin
      RowTuple:= tCsvWord32RowTuple.Create();
      Field:= Row[ FieldIndex];
      Temp:= Field.ToInt64;
      if( (Temp > MaxWord32) or (Temp < 0)) then begin
         raise tCsvException.Create( RangeErrorWord32, [Field]);
      end;
      RowTuple.Key:= Word32( Temp);
      RowTuple.Row:= Row;
      RowTree.Add( RowTuple);
   end; // SetRow();



// ========================================================================
// = tCsvWord64SortFilter class
// ========================================================================
// *************************************************************************
// * CompareWord64RowTuple() - Global function to support sorting
// *************************************************************************

function CompareWord64RowTuple( T1, T2: tCsvWord64RowTuple): integer;
   begin
      if( T1.key > T2.key) then begin
         result:= 1;
      end else if( T1.key < T2.key) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareWord64RowTuple();


// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCsvWord64SortFilter.Create( iField:           string; 
                                         iReverse:         boolean = false);
   var
      Func: tRowTree.tCompareFunction;
   begin
      inherited Create();
      FieldName:=       iField;
      Reverse:=         iReverse;
      Func:=            tRowTree.tCompareFunction( @CompareWord64RowTuple);
      RowTree:=         tRowTree.Create( Func, true);
   end; // Create()


// *************************************************************************
// * Destroy() - destructor - Does the actual output
// *************************************************************************

destructor tCsvWord64SortFilter.Destroy();
   begin
      if( Reverse) then begin
        while RowTree.Previous() do begin
           NextFilter.SetRow( RowTree.Value.Row);
        end;
      end else begin
        while RowTree.Next() do begin
           NextFilter.SetRow( RowTree.Value.Row);
        end;
      end;

      RowTree.RemoveAll( true);
      RowTree.Destroy();
   end; // Destroy();


// *************************************************************************
// * SetInputHeader() - Find the Field Index and then pass the header to the
// *                    next filter.
// *************************************************************************

procedure tCsvWord64SortFilter.SetInputHeader( Header: tCsvCellArray);
   var
      i:     integer;
      iMax:  integer;
      Found: boolean;
   begin
      i:= 0;
      iMax:= Length( Header) - 1;
      Found:= false;
      while( (not Found) and (i <= iMax)) do begin
         if( Header[ i] = FieldName) then begin
             Found:= true;
             FieldIndex:= i;
         end;
         inc( i);
      end;

      if( not Found) then Usage( true, Format( HeaderUnknownField, [FieldName]));

      NextFilter.SetInputHeader( Header);
   end; // SetInputHeader();


// *************************************************************************
// * SetRow() - Add the row to the tree
// *************************************************************************

procedure tCsvWord64SortFilter.SetRow( Row: tCsvCellArray);
   var
      Field: string;
      RowTuple: tCsvWord64RowTuple;
   begin
      RowTuple:= tCsvWord64RowTuple.Create();
      Field:= Row[ FieldIndex];
      RowTuple.Key:= StrToQWord( Field);
      RowTuple.Row:= Row;
      RowTree.Add( RowTuple);
   end; // SetRow();



// ========================================================================
// = tCsvCurrencySortFilter class
// ========================================================================
// *************************************************************************
// * CompareCurrencyRowTuple() - Global function to support sorting
// *************************************************************************

function CompareCurrencyRowTuple( T1, T2: tCsvCurrencyRowTuple): integer;
   begin
      if( T1.key > T2.key) then begin
         result:= 1;
      end else if( T1.key < T2.key) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareCurrencyRowTuple();


// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCsvCurrencySortFilter.Create( iField:           string; 
                                        iReverse:         boolean = false);
   var
      Func: tRowTree.tCompareFunction;
   begin
      inherited Create();
      FieldName:=       iField;
      Reverse:=         iReverse;
      Func:=            tRowTree.tCompareFunction( @CompareCurrencyRowTuple);
      RowTree:=         tRowTree.Create( Func, true);
   end; // Create()


// *************************************************************************
// * Destroy() - destructor - Does the actual output
// *************************************************************************

destructor tCsvCurrencySortFilter.Destroy();
   begin
      if( Reverse) then begin
        while RowTree.Previous() do begin
           NextFilter.SetRow( RowTree.Value.Row);
        end;
      end else begin
        while RowTree.Next() do begin
           NextFilter.SetRow( RowTree.Value.Row);
        end;
      end;

      RowTree.RemoveAll( true);
      RowTree.Destroy();
   end; // Destroy();


// *************************************************************************
// * SetInputHeader() - Find the Field Index and then pass the header to the
// *                    next filter.
// *************************************************************************

procedure tCsvCurrencySortFilter.SetInputHeader( Header: tCsvCellArray);
   var
      i:     integer;
      iMax:  integer;
      Found: boolean;
   begin
      i:= 0;
      iMax:= Length( Header) - 1;
      Found:= false;
      while( (not Found) and (i <= iMax)) do begin
         if( Header[ i] = FieldName) then begin
             Found:= true;
             FieldIndex:= i;
         end;
         inc( i);
      end;

      if( not Found) then Usage( true, Format( HeaderUnknownField, [FieldName]));

      NextFilter.SetInputHeader( Header);
   end; // SetInputHeader();


// *************************************************************************
// * SetRow() - Add the row to the tree
// *************************************************************************

procedure tCsvCurrencySortFilter.SetRow( Row: tCsvCellArray);
   var
      Field: string;
      RowTuple: tCsvCurrencyRowTuple;
   begin
      {$WARNING Built in currency parsing is broken.  It doesn't skip the '$' nor the ','  I need to take a look at how its implemented and fix it.}
      RowTuple:= tCsvCurrencyRowTuple.Create();
      Field:= Row[ FieldIndex];
      if( Field = '') then Field:= '0';
      if( not (Field[ 1] in CurrencyChrs)) then begin
         Field:= Copy( Field, 2, Length( Field) - 1);
      end; 
      RowTuple.Key:= StrToCurr( Field);
      RowTuple.Row:= Row;
      RowTree.Add( RowTuple);
   end; // SetRow();



// ========================================================================
// = tCsvIpv4SortFilter class
// ========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCsvIpv4SortFilter.Create( iField:           string; 
                                       iReverse:         boolean = false;
                                       iIgnoreFailures:  boolean = false);
   begin
      inherited Create( iField, iReverse);
      IgnoreFailures:= iIgnoreFailures;
   end; // Create() 


// *************************************************************************
// * SetRow() - Add the row to the tree
// *************************************************************************

procedure tCsvIpv4SortFilter.SetRow( Row: tCsvCellArray);
   var
      Field:    string;
      RowTuple: tCsvWord32RowTuple;
      Temp:     word32;
   begin
      RowTuple:= tCsvWord32RowTuple.Create();
      Field:= Row[ FieldIndex];
      try
         Temp:= IPStringToWord32( Field);
      except
        on E: Exception do
        begin
           Temp:= 0;
           if( not IgnoreFailures) then raise E;
        end;
      end;
      RowTuple.Key:= Temp;
      RowTuple.Row:= Row;
      RowTree.Add( RowTuple);
   end; // SetRow();



// ========================================================================
// = tCsvSetFieldFilter class - Set a default value for a field
// ========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCsvSetFieldFilter.Create( iFieldCsv: string;
                                       iValueCsv: string;
                                       iAllCells: boolean = false);
   var
      VL: integer;
   begin
      inherited Create();
      Fields:= StringToCsvCellArray( iFieldCsv);
      Values:= StringToCsvCellArray( iValueCsv);
      AllCells:= iAllCells;

      FieldLength:= Length( Fields);
      SetLength( Indexes, FieldLength);
      VL:= Length( Values);
      if( VL <> FieldLength) then lbp_argv.Usage( true, FieldValueLengthError);
   end; // Create() 


// *************************************************************************
// * SetInputHeader()
// *************************************************************************

procedure tCsvSetFieldFilter.SetInputHeader( Header: tCsvCellArray);
   var 
      HL:       integer; // Header Length
      HI:       integer; // Header index
      FI:       integer; // Fields index;
      Found:    boolean;
      ErrorMsg: string;
   begin
      // If an empty Fields was passed to Create(), then we use all the fields
      HL:=  Length( Header);

      // For each  Field
      FI:= 0;
      while( FI < FieldLength) do begin
         HI:= 0;
         Found:= false;
  
         // for each Header
         while( (not found) and (HI < HL)) do begin
            if( Header[ HI] = Fields[ FI]) then begin
               Found:= true;
               Indexes[ FI]:= HI;
            end;
            inc( HI);
         end; // while Header
  
         if( not Found) then begin
            ErrorMsg:= Format( HeaderUnknownField, [Fields[ FI]]);
            lbp_argv.Usage( true, ErrorMsg);
         end;

         inc( FI);  
      end; // while Fields

      NextFilter.SetInputHeader( Header);
   end; // SetInputHeader


// *************************************************************************
// * SetRow() - Add the row to the tree
// *************************************************************************

procedure tCsvSetFieldFilter.SetRow( Row: tCsvCellArray);
   var
      i:      integer;
      iMax:   integer;
      iCell:  integer;
   begin
      // Set default values for fields
      iMax:= FieldLength - 1;
      for i:= 0 to iMax do begin
         iCell:= Indexes[ i];
         if( AllCells or (Row[ iCell] = '')) then Row[ iCell]:= Values[ i];
      end;
      
      NextFilter.SetRow( Row);
   end; // SetRow();



// ========================================================================
// = tCsvStripEmptyRowFilter class - Strips out rows where every field is
// =                                  an empty string.
// ========================================================================
// ************************************************************************
// * SetRow() - This does all the work for each row.
// ************************************************************************

procedure tCsvStripEmptyRowFilter.SetRow( Row: tCsvCellArray);
   var
      Field: string;
      Found: boolean = false;
   begin
      for Field in Row do begin
         if( Field.Length > 0) then begin
            Found:= true;
            break; 
         end;
      end;

      if( Found) then NextFilter.SetRow( Row);
   end; // SetRow()



// ========================================================================
// = tCsvSequenceFilter class - Replaces the values in a singel field with
// =                            a sequence number. 
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tCsvSequenceFilter.Create( Field: string; InitialValue: string);
   begin     
      Create( Field, InitialValue.ToInt64);
   end; // Create();

// ------------------------------------------------------------------------

constructor tCsvSequenceFilter.Create( Field: string; InitialValue: int64);
   begin
      inherited Create();
      CurrentValue:= InitialValue;
      FieldName:= Field;
   end; // Create()


// ************************************************************************
// * SetInputHeader() - Get the FieldIndex and forward the header as normal.
// ************************************************************************

procedure tCsvSequenceFilter.SetInputHeader( Header: tCsvCellArray);
   var
      Found:    boolean;
      i:        integer;
      iMax:     integer;
      ErrorMsg: string;
   begin
      Found:= false;
      iMax:= Length( Header) - 1;
      for i:= 0 to iMax do begin
         if( Header[ i] = FieldName) then begin
            Found:= true;
            FieldIndex:= i;
            break;
         end;
      end;

      // handle errors
      if( not Found) then begin
         ErrorMsg:= sysutils.Format( HeaderUnknownField, [FieldName]);
         lbp_argv.Usage( true, ErrorMsg);
      end;

      NextFilter.SetInputHeader( Header);
   end; // SetHeader



// ************************************************************************
// * SetRow() - This does all the work for each row.
// ************************************************************************

procedure tCsvSequenceFilter.SetRow( Row: tCsvCellArray);
   begin
      Row[ FieldIndex]:= CurrentValue.ToString;
      inc( CurrentValue);
      
      NextFilter.SetRow( Row);
   end; // SetRow()



// *************************************************************************

end. // lbp_csv_filter unit
