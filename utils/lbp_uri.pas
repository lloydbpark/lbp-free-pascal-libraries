{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

encode/decode URIs

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

unit lbp_uri;

{$ERROR This unit never got past the initial copy and edit!}

// This is a simple unit to handle URI encode and decode like the httpdefs unit
// from the FCL.  The difference is that many programs encode spaces as '%20'
// instead of '+'.  So I took the code from httpdefs and modified the encode to
// include a boolean to make it use '%20' if desired.

interface

{$include lbp_standard_modes.inc}

uses
   lbp_types;


// *************************************************************************

type
   CSVException = class( KentException);

// *************************************************************************

type
   tCSVLine = class
      protected
         MyLine:       string;
         MyCharPos:    integer;
         LineLength:   integer;
         MyDelimiter:  char;
      public
         constructor Create();
         constructor Create( iLine: string);
         function    PeekNextChar(): char;
         function    GetNextChar():  char;
         function    NextValue(): string;
         function    Quote( S: string): string;
         function    Dequote( qS: string): string;
      protected
         procedure   SetLine( iLine: string);
      public
         property    Line: string read MyLine write SetLine;
         property    Delimiter: char read MyDelimiter write MyDelimiter;
      end; // CSVLine class


// *************************************************************************


implementation

// *************************************************************************
// * HTTPDecode()
// *************************************************************************

function HTTPDecode(const AStr: String): String;

   var
     S,SS, R : PChar;
     H : String[3];
     L,C : Integer;

   begin
      L:=Length( Astr);
      SetLength( Result, L);
      If (L=0) then begin
         exit;
      end;
      S:=PChar( AStr);
      SS:=S;
      R:=PChar( Result);
      while ( S - SS) < L do begin
         case S^ of
            '+': R^:= ' ';
            '%': begin
                    Inc(S);
                    if( (S - SS) < L) then begin
                       if( S^ = '%') then begin
                          R^:='%'
                       end else begin
                          H:='$00';
                          H[ 2]:= S^;
                          Inc( S);
                          if( S - SS) < L then begin
                             H[ 3]:= S^;
                             Val( H, PByte( R)^, C);
                             if( C <> 0) then begin
                                R^:=' ';
                             end;
                          end;
                       end;
                    end;
                 end; // '%' case
            else
               R^ := S^;
            end;
            Inc( R);
            Inc( S);
         end;
         SetLength( Result, R - PChar( Result));
      end; // HTTPDecode()


// *************************************************************************

end. // lbp_uri unit
