{* ***************************************************************************

Copyright (c) 2019 by Lloyd B. Park

Extract fields from a AwsLog string.  Quote and unquote AwsLog fields.

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
unit lbp_aws_log;

// Class to handle what I hope is a standard log format for AWS.  I built it
// to work with some CDN logs I had to report on.

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_types,
   lbp_generic_containers,
   lbp_parse_helper,
   lbp_csv;


// *************************************************************************

// *************************************************************************

type
   tAwsLog = class( tCsv)
      protected
         MyVersion: string;
         procedure  Init(); override;
      private
         procedure  SkipRestOfLine();
      public
         function   ParseHeader(): integer; override;// returns the number of cells in the header
         function   ParseRow(): tCsvCellArray; override;
      end; // tAwsLog class


// *************************************************************************

implementation

// =========================================================================
// = tAwsLog
// =========================================================================
// *************************************************************************
// * Init() - Initialize the class
// *************************************************************************

procedure tAwsLog.Init();
   begin
      Inherited Init();
      Delimiter:= ' ';
      ParseHeader();
      Delimiter:= TabChr;
   end; // Init()


// *************************************************************************
// * SkipRestOfLine()
// *************************************************************************
procedure tAwsLog.SkipRestOfLine();
   var
      C:  char;
   begin
      C:= Chr;
      // Skip to the end of the line
      while( (C <> EOFchr) and (C <> LFchr) and (C <> CRchr)) do C:= Chr;
      // Strip off any white space including empty lines.  This insures the next 
      // character starts a valid cell.
      while( C in WhiteChrs) do C:= Chr;
      Chr:= C; // put the last character back in the stream
   end; // SkipRestOfLine   


// *************************************************************************
// * ParseHeader() - Read the header so we can lookup column numbers by name
// *************************************************************************

function tAwsLog.ParseHeader(): integer;
   var
      TempHeader:  tCsvCellArray;
      TempVersion: tCsvCellArray;
      C:             char;
      VersionFound:  boolean;
      i:             integer;
      iMax:          integer;
   // ----------------------------------------------------------------------
   procedure MovePastBeginStr( BeginStr: string);
      var
         C: char;
         i: integer;
      begin
         {$ifdef DEBUG_PARSE_HELPER}
            if( DebugParser) then begin
               writeln( MyIndent, 'tAwsLog.MovePastBeginStr() called');
               MyIndent:= MyIndent + '   ';
            end;
         {$endif}
         iMax:= Length( BeginStr);
         for i:= 1 to iMax do begin
            C:= GetChr;
            if( C <> BeginStr[ i]) then begin
               raise tCsvException.Create( 'The AWS Log file is missing the %S line!', [BeginStr]);
            end;
         end; // for
         {$ifdef DEBUG_PARSE_HELPER}
            if( DebugParser) then SetLength( MyIndent, Length( MyIndent) - 3);
         {$endif}
      end; // MovePastBeginStr()
   // ----------------------------------------------------------------------
   begin
   {$ifdef DEBUG_PARSE_HELPER}
      if( DebugParser) then begin
         writeln( MyIndent, 'tAwsLog.ParseHeader() called');
         MyIndent:= MyIndent + '   ';
      end;
   {$endif}

      Delimiter:= ' ';
      VersionFound:= false;
      while(  IndexDict.Empty or (not VersionFound)) do begin
         // Get the letter following the '#' and store it in C
         C:= Chr;
         if( C <> '#') then begin
            raise tCsvException.Create( 'AWS log data line was found before both the Version and Field header lines were read!');           
         end;
         C:= Chr;
         case C of
            'V': if( not VersionFound) then begin 
               MovePastBeginStr( 'ersion: ');
               C:= PeekChr;
               if( (C = Delimiter) or (C in lbp_parse_helper.WhiteChrs)) then begin
                  raise tCsvException.Create( 'The #Version: line exists but no value is set!');
               end;
               TempVersion:= ParseRow;
               C:= PeekChr;
               if( (Length(TempVersion) <> 1)) then begin
                  raise tCsvException.Create( 'The #Version: line exists but has multiple values set!');
               end;
               MyVersion:= TempVersion[ 0];
               ParseElement( InterLineWhiteChrs);
               VersionFound:= true;
            end else SkipRestOfLine(); // 'V' case
            'F': if( IndexDict.Empty) then begin
               MovePastBeginStr( 'ields: ');
               C:= PeekChr;
               if( (C = Delimiter) or (C in lbp_parse_helper.WhiteChrs)) then begin
                  raise tCsvException.Create( 'The Fields: line exists but no value is set!');
               end;
               // Move past extra spaces immediatly after '#Fields: '
               while( C = Delimiter) do C:= Chr;
               TempHeader:= ParseRow;
               if( (Length(TempHeader) = 0)) then begin
                  raise tCsvException.Create( 'The #Fields: line exists but has no values');
               end;
               ParseElement( InterLineWhiteChrs);
               result:= Length( TempHeader);
               iMax:= result - 1;
               for i:= 0 to iMax do begin
                  if( Length( TempHeader[ i]) = 0) then begin
                     raise tCsvException.Create( 'The #Fields line exists, but one or more field names are empty!');
                  end;
                  IndexDict.Add( TempHeader[ i], i);
               end;
            end else SkipRestOfLine(); // 'F' case
         else 
            SkipRestOfLine; // An unknown header or comment line
         end; // case else
      end; // while both headers haven't been read.
      Delimiter:= TabChr;
      {$ifdef DEBUG_PARSE_HELPER}
         if( DebugParser) then SetLength( MyIndent, Length( MyIndent) - 3);
      {$endif}
   end; // ParseHeader()


// *************************************************************************
// * ParseRow() - Returns an array of strings.  The returned array is 
// *               invalid if an EOF is the next character in the tChrSource.
// *************************************************************************

//{$error Add code to ignore lines starting with #}
function tAwsLog.ParseRow(): tCsvCellArray;
   var
      TempCell:  string;
      C:         char;
      Ca:        tCsvCellArray;
      CaSize:    longint = 16;
      CaLen:     longint = 0;
      LastCell:  boolean = false;
   begin
   {$ifdef DEBUG_PARSE_HELPER}
      if( DebugParser) then begin
         writeln( '   tAwsLog.ParseRow() called');
         MyIndent:= MyIndent + '   ';
      end;
   {$endif}
      SetLength( Ca, CaSize);

      // Strip off any white space including empty lines.  This insures the next 
      // character starts a valid cell.
      C:= Chr;
      while( C in WhiteChrs) do C:= Chr;

      // Ignore #Version and #Field lines in the middle of the file
      while( C = '#') do begin
         C:= Chr;

         // Skip to the end of the line
         while( (C <> EOFchr) and (C <> LFchr) and (C <> CRchr)) do C:= Chr;

         // Strip off any white space including empty lines.  This insures the next 
         // character starts a valid cell.
         while( C in WhiteChrs) do C:= Chr;
      end;
      Chr:= C;
      
      // We only can add to cells if we are not at the end of the file
      if( C <> EOFchr) then begin
         repeat
            TempCell:= ParseCell();

            // Add TempCell to Sa - resize as needed
            if( CaLen = CaSize) then begin
               CaSize:= CaSize SHL 1;
               SetLength( Ca, CaSize);
            end;
            Ca[ CaLen]:= TempCell; 
            inc( CaLen);

            C:= PeekChr;
            LastCell:= C <> Delimiter;
            if( not LastCell) then C:= GetChr;
         until( LastCell);  // so this only matches, CR, LF, and EOF
         
         // If the 'line' ended with an EOF and no CR or LF then we need to fake
         // it since we are returning a valid array of cells.
         if( PeekChr = EOFchr) then UngetChr( LFchr);
      end;

      SetLength( Ca, CaLen);
      result:= Ca;
      {$ifdef DEBUG_PARSE_HELPER}
         if( DebugParser) then SetLength( MyIndent, Length( MyIndent) - 3);
      {$endif}
   end; // ParseRow()


// *************************************************************************

end. // lbp_AwsLog unit
