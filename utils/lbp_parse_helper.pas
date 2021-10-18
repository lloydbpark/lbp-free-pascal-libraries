{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

lbp_parse_helper



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

unit lbp_parse_helper;

interface

{$include lbp_standard_modes.inc}
//{$V-}    //Added by LP because it says so below
//{$R-}    //Range checking off
//{$S-}    //Stack checking off
//{$I-}    //I/O checking off
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

// ************************************************************************

uses
   {$ifdef DEBUG_PARSE_HELPER}
      lbp_argv,
   {$endif}
   lbp_types,
   lbp_generic_containers,
   classes,
   sysutils;

// ************************************************************************

type
   tCharList = specialize tgList< char>;
   tCharSet = set of char;
   ParseException = class( lbp_exception);
const
   ParserBufferSize = 4096;
   EOFchr = char( 26);
   CRchr  = char( 13);
   LFchr  = char( 10);
   TabChr = char( 9);
var
   AsciiChrs:    tCharSet = [char( 0)..char( 127)];
   AnsiChrs:     tCharSet = [char( 0)..char( 255)]; // UTF8 is a subset of this.
   AlphaChrs:    tCharSet = ['a'..'z', 'A'..'Z'];
   NumChrs:      tCharSet = ['0'..'9'];
   CurrencyChrs: tCharSet = ['0'..'9',',','.'];
   AlphaNumChrs: tCharSet = ['a'..'z', 'A'..'Z', '0'..'9'];
   WhiteChrs:    tCharSet = [ ' ', TabChr, LFchr, CRchr];
   QuoteChrs:    tCharSet = ['''', '"' ];
   SymbolChrs:   tCharSet = [char( 33)..char( 47), char( 58)..char( 64),
                               char( 91)..char( 96), char( 123)..char( 126)];
   CtlChrs:      tCharSet = [char(0)..char(31),char(127)];
   IntraLineWhiteChrs:  tCharSet = [ ' ', TabChr];
   InterLineWhiteChrs:  tCharSet = [ LFchr, CRchr];
   EolChrs:             tCharSet = [LFchr, CRchr, EOFchr];
   AsciiPrintableChrs:  tCharSet;
   AnsiPrintableChrs:   tCharSet;
   IntraLineAsciiChrs:  tCharSet;
   IntraLineAnsiCHrs:   tCharSet;
   {$ifdef DEBUG_PARSE_HELPER}
      DebugParser:      boolean = false;
   {$endif}


// ************************************************************************
// * tChrSource class - Provides tools to get and unget characters from
// *                    some text source.
// ************************************************************************
type
   tChrSource = class( tObject)
      private
         ChrBuff:        array[ 0..(ParserBufferSize - 1)] of char;
         ChrBuffLen:     longint;
         ChrBuffPos:     longint;
         UngetQ:         tCharList;
         Stream:         tStream;
         DestroyStream:  boolean;
      protected
         // Element Parsing variables;
         MyS:            string;
         MySSize:        longint;
         MySLen:         longint;
         {$ifdef DEBUG_PARSE_HELPER}         
            MyPosition:  integer;
            MyIndent:    string;
         {$endif}
         MySkipNonPrintable:  boolean; // Attempt to fix files with some unicode mixed in.
                                       // Does nothing here, but can be used by child classes.
      public
         constructor Create( iStream: tStream; iDestroyStream: boolean = true);
         constructor Create( iString: string; IsFileName: boolean = false);
         constructor Create( var iFile:   text);
         destructor  Destroy(); override;
      protected
         procedure   Init(); virtual;
         procedure   InitS(); virtual;
         procedure   ParseAddChr( C: char); virtual;
         procedure   RemoveBom(); // Remove the Byte Order Mark for unicode
      public
         function    PeekChr(): char; virtual;
         function    GetChr(): char; virtual;
         procedure   UngetChr( C: char); virtual;
         function    ParseElement( var AllowedChrs: tCharSet): string; virtual;
         function    SkipText( iText: string): boolean;  // true if matched text was found and skipped
         function    ReadLn(): string;
         procedure   SkipEOL();  // Skip one End of Line.  Does nothing if we aren't at an EndOfLine
         property    Chr: char read GetChr write UngetChr;
         {$ifdef DEBUG_PARSE_HELPER}
            property    Position: integer read MyPosition;
         {$endif}
      end; // tChrSource class


// ************************************************************************

implementation

// ========================================================================
// = tChrSource class
// ========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tChrSource.Create( iStream: tStream; iDestroyStream: boolean);
   begin
      inherited Create();
      MySkipNonPrintable:= false;
      UngetQ:= nil;
      Stream:= iStream;
      DestroyStream:= iDestroyStream;
      Init();
   end; // Create()

// -------------------------------------------------------------------------

constructor tChrSource.Create( iString: string; IsFileName: boolean);
   begin
      inherited Create();
      MySkipNonPrintable:= false;      
      UngetQ:= nil;

      if( IsFileName) then begin
         if( not FileExists( iString)) then begin
            raise ParseException.Create( 'The passed file ''%s'' does not exist!', [iString]);
         end;
         Stream:= tFileStream.Create( iString, fmOpenRead);
      end else begin
         Stream:= tStringStream.Create( iString);
      end;
      DestroyStream:= true;
      Init();
   end; // Create()


// -------------------------------------------------------------------------

constructor tChrSource.Create( var iFile: text);
   begin
      inherited Create();
      UngetQ:= nil;
      MySkipNonPrintable:= false;
      Stream:= tHandleStream.Create( TextRec( iFile).Handle);
      DestroyStream:= true;
      Init();
   end; // Create()


// *************************************************************************
// * Destroy() - Destructor
// *************************************************************************

destructor tChrSource.Destroy();
   begin
       if( DestroyStream) then Stream.Destroy();
       if( UngetQ <> nil) then UngetQ.Destroy;
       inherited Destroy();
   end; // Destroy()


// *************************************************************************
// * Init() - internal function to initialize variables.  Called by Create()
// *************************************************************************

procedure tChrSource.Init();
   begin
      UngetQ:= tCharList.Create( 8, 'UngetQ');

      ChrBuffLen:= Stream.Read( ChrBuff, ParserBufferSize);
      ChrBuffPos:= 0;
      {$ifdef DEBUG_PARSE_HELPER}
         MyPosition:= 0;
         MyIndent:= '';
      {$endif}
//      RemoveBom(); // Remove unicode Byte Order Marker if it exists.
   end; // Init()


// ************************************************************************
// * InitS() - Set S's initial length and size
// ************************************************************************

procedure tChrSource.InitS();
   begin
      MySSize:= 16;
      SetLength( MyS, MySSize);
      MySLen:= 0;      
   end; // InitS()


// ************************************************************************
// * ParseAddChr() - Add a character to S and resize as needed.
// ************************************************************************

procedure tChrSource.ParseAddChr( C: char);
   begin
      // If we used up all the space in S then double it's capacity.
      if( MySLen = MySSize) then begin
         MySSize:= MySSize SHL 1;
         SetLength( MyS, MySSize);
      end;
      inc( MySLen);
      MyS[ MySLen]:= C; 
   end; // ParseAddChar()


// ************************************************************************
// * RemoveBom() - Remove the optional byte order mark for unicode from the
// *               front of the file.  Because this code currently expects
// *               the file to contain ASCII or ANSI characters an exception
// *               is raised for anything other than the utf-8 BOM.
// ************************************************************************
{$WARNING This proceedure isn't working.  The order of characters gets messed up somehow}
procedure tChrSource.RemoveBom();
   var
      // Byte Order Mark strings (Unicode standard)
      BomUtf8:    string = char( $ef) + char( $bb) + char( $bf);
      BomUtf16BE: string = char( $fe) + char( $ff);
      BomUtf16LE: string = char( $ff) + char( $fe);
      BomUtf32BE: string = char( $00) + char( $00) + char( $fe) + char( $ff);
      BomUtf32LE: string = char( $ff) + char( $fe) + char( $00) + char( $00);
      S2:  string;
      S3:  string;
      S4:  string = '    ';
      i:   integer;
   begin
      // Get possible BOMs
      for i:= 1 to 4 do S4[ i]:= Chr;
      S3:= Copy( S4, 1, 3);
      S2:= Copy( S4, 1, 2);
      // writeln( 'S2 = ', S2);
      // writeln( 'S3 = ', S3);
      // writeln( 'S4 = ', S4);
      if( S3 = BomUtf8) then begin
         UngetChr( S4[ 4]);
      end else if( (S2 = BomUtf16BE) or (S2 = BomUtf16LE)) then begin
         raise ParseException.Create( 'The imput is in UTF-16 format and this program expects UTF-8 or ASCII!');
      end else if( (S4 = BomUtf32BE) or (S4 = BomUtf32LE)) then begin
         raise ParseException.Create( 'The imput is in UTF-32 format and this program expects UTF-8 or ASCII!');
      end else begin
         for i:= 1 to 4 do UngetChr( S4[ i]);
      end;
      // for i:= 1 to 8 do write( GetChr());
      // writeln;
      // writeln;
   end; // RemoveBom()


// *************************************************************************
// * PeekChr() - Returns the next char in the stream
// *************************************************************************

function tChrSource.PeekChr(): char;
   begin
      result:= EOFchr;
      if( not UngetQ.IsEmpty()) then begin
         result:= UngetQ.Queue;
         UngetQ.Head:= result; // Put it back
      end else begin
         if( ChrBuffPos = ChrBuffLen) then begin
            // Read another block into the buffer
            ChrBuffLen:= Stream.Read( ChrBuff, ParserBufferSize);
            ChrBuffPos:= 0;
         end;
         if( ChrBuffPos < ChrBuffLen) then begin
           result:= ChrBuff[ ChrBuffPos];
         end;
      end; 
      {$ifdef DEBUG_PARSE_HELPER}
         if( DebugParser) then begin
            write( MyIndent, 'tChrSource.PeekChr() at ', Position + 1, ' = ');
            if( result in IntraLineAnsiChrs) then begin
               writeln( '''', result, '''');
            end else begin
               writeln( 'ord(', ord( result), ')');
            end;
         end;
      {$endif}
   end; // PeekChr();


// *************************************************************************
// * GetChr() - Returns the next char in the stream
// *************************************************************************

function tChrSource.GetChr(): char;
   begin
      result:= EOFchr;
      if( not UngetQ.IsEmpty()) then begin
         result:= UngetQ.Queue;
      end else begin
         if( ChrBuffPos = ChrBuffLen) then begin
            // Read another block into the buffer
            ChrBuffLen:= Stream.Read( ChrBuff, ParserBufferSize);
            ChrBuffPos:= 0;
         end;
         if( ChrBuffPos < ChrBuffLen) then begin
           result:= ChrBuff[ ChrBuffPos];
           inc( ChrBuffPos);
         end;
      end;
      {$ifdef DEBUG_PARSE_HELPER}
         Inc( MyPosition);
         if( DebugParser) then begin
            write( MyIndent, 'tChrSource.GetChr() at ', Position, ' = ');
            if( result in IntraLineAnsiChrs) then begin
               writeln( '''', result, '''');
            end else begin
               writeln( 'ord(', ord( result), ')');
            end;
         end;
      {$endif}
   end; // GetChr();


// *************************************************************************
// * UngetChr() - inserts the passed character into the stream
// *************************************************************************

procedure tChrSource.UngetChr( C: char);
   begin
      UngetQ.Queue:= C;
      {$ifdef DEBUG_PARSE_HELPER}
         if( DebugParser) then begin
            write( MyIndent, 'tChrSource.UngetChr() at ', Position, ' = ');
            if( C in IntraLineAnsiChrs) then begin
               writeln( '''', C, '''');
            end else begin
               writeln( 'ord(', ord( C), ')');
            end;
         end;
         Dec( MyPosition);
      {$endif}
   end; // UngetChr()


// ************************************************************************
// * ParseElement()
// ************************************************************************

function tChrSource.ParseElement( var AllowedChrs: tCharSet): string;
   var
      C: char;
   begin
      {$ifdef DEBUG_PARSE_HELPER}
         if( DebugParser) then begin
            writeln( MyIndent, 'tChrSource.ParseElement() called');
            MyIndent:= MyIndent + '   ';
         end;
      {$endif}
      InitS();
      C:= GetChr();
      while( C in AllowedChrs) do begin
         ParseAddChr( C);
         C:= GetChr();
      end;
      UngetChr( C);
      SetLength( MyS, MySLen);
      result:= MyS;

      {$ifdef DEBUG_PARSE_HELPER}
         if( DebugParser) then SetLength( MyIndent, Length( MyIndent) - 3);
      {$endif}
   end; // ParseElement()


// ************************************************************************
// * SkipText() - Returns true if the passed string exactly matches the 
// *              next characters in the stream.  It skips characters 
// *              until one doesn't match or if has found the entire string.
// ************************************************************************

function tChrSource.SkipText( iText: string): boolean;
   var
      c: char;
   begin
      result:= false;
      for c in iText do begin
         if( not (c = GetChr)) then exit;
      end;
      result:= true;
   end; // SkipText();


// ************************************************************************
// * SkipEol() - If the next characters in the queue are a Windows, Unix,
// *             or old Mac OS line ending, it will be skipped.  Otherwise
// *             nothing happens.
// ************************************************************************

procedure tChrSource.SkipEol();
   begin
      if( PeekChr = CRchr) then GetChr; // discard it.
      if( PeekChr = LFchr) then GetChr; // discard it.
   end; // SkipEol()


// ************************************************************************
// * ReadLn() - Read one line and discard the Eol.
// ************************************************************************

function tChrSource.ReadLn(): string;
   begin
      result:= '';
      while( not( PeekChr in EolChrs)) do result:= result + chr;
      if( PeekChr = CRchr) then GetChr; // discard it.
      if( PeekChr = LFchr) then GetChr; // discard it.
   end; // SkipEol()



/// ========================================================================
// * Unit initialization and finalization.
// ========================================================================
// *************************************************************************
// * ParseArgV() - Read and initialize INI variables.  Then parse the
// *               command line parameters which will override INI settings.
// *************************************************************************

{$ifdef DEBUG_PARSE_HELPER}
   procedure ParseArgv();
      begin
         DebugParser:= ParamSet( 'debug-parse-helper');
      end;
{$endif}


// *************************************************************************
// * InitArgvParser() - Add debugging option
// *************************************************************************

{$ifdef DEBUG_PARSE_HELPER}
   procedure InitArgvParser();
      begin
         AddUsage( '   ========== lbp_parse_helper debuging ==========');
         AddParam( ['debug-parse-helper'], false, '',   'Display progress through the parser.');
         AddUsage();

         AddPostParseProcedure( @ParseArgv);
      end; // InitArgvParser()
{$endif}


// *************************************************************************

begin
   AsciiPrintableChrs:= (AsciiChrs - CtlChrs) + WhiteChrs;
   AnsiPrintableChrs:= (AnsiChrs - CtlChrs) + WhiteChrs;
   IntraLineAsciiChrs:=  AsciiPrintableChrs - InterLineWhiteChrs;
   IntraLineAnsiChrs:=   AnsiPrintableChrs - InterLineWhiteChrs;
   {$ifdef DEBUG_PARSE_HELPER}
      InitArgvParser();
   {$endif}
end.  // lbp_parse_helper unit
