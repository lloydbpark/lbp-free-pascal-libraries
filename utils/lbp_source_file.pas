{* ***************************************************************************

Copyright (c) 2018 by Lloyd B. Park

This unit defines SourceFile which is used to read a text file a character
at a time for use in a parser or simple compiler project.  

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


unit lbp_source_file;

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_argv,
   lbp_types,
{$ifdef UNIX}
   baseunix,
   termio,
{$endif}
   lbp_generic_lists;

// ************************************************************************

type
   tSourceFile = class( tObject)
      private type
         tCharList = specialize tgList< char>;
      private
         MyFile:  file of char;
         MyQ:     tCharList;
      public
         constructor Create( iFileName: string = '');
         destructor  Destroy; override;
         function    GetChar: char; virtual;
         function    Peek( i: integer): char;
      end; // tSourceFile


// ************************************************************************

var
   SourceFile: tSourceFile = nil;

// ************************************************************************

implementation

// ************************************************************************
// * IsATTY() - Returns true if the passed file handle is a terminal as
// *            opposed to a file or pipe.
// ************************************************************************

{$ifdef UNIX}
function IsATTY( Handle: Longint): Boolean;
   var
      t : Termios;
   begin
      result:= (TCGetAttr( Handle, t) = 0);
   end;
{$endif}


// ========================================================================
// = tSourceFile class
// ========================================================================
// ************************************************************************
// * Create() - constructor
// ************************************************************************

constructor tSourceFile.Create( iFileName: string);
   begin
      if( (iFileName = '') and (not IsATTY( 0))) then begin
         MyFile:= Input;
      end else begin
         AssignFile( MyFile, iFileName);
         RestFile( MyFile);
      end;
   end; // Create()


// ************************************************************************
// * Destroy() - destructor
// ************************************************************************


// ************************************************************************
// * GetChar() - Get the next character from the source
// ************************************************************************


// ************************************************************************
// * Peek() - Look ahead in the source
// ************************************************************************



function Open_File( var BF: TBuffered_File; FileName: string): tpChar;
   { Opens a buffered file for input. }
   { Returns a pointer to character that should be used as the initial }
   { value passed as a parameter to the first call to Get_Char.        }

   var
      i:    integer; { loop var }
      Temp: tpChar;
   begin
      { Open the file }
      assign( BF.InFile, FileName);
      reset( BF.InFile, 1);

      { initialize the buffers }
      for i:= 0 to 1 do with BF.Buffer[ i] do begin
         Head:= @Data[0];
         Head^:= Sentinel;
         Tail:= @Data[ BuffSize + 1];
         Tail^:= Sentinel;
         Reload:= true;
      end;
      Temp:= BF.Buffer[ 0].Tail;
      dec( Temp);
      Open_File:= Temp;

   end; { Open_File }

{ ************************************************************************ }

procedure Close_File( var BF: TBuffered_File);
   { Closes buffered file. }
   begin
      close( BF.InFile);
   end; { Close_File }

{ ************************************************************************ }

Procedure Get_Chr( var BF: TBuffered_File; var C: tpChar);
   { Points C to the next character in the buffered file.  Reloads the }
   { individual buffers from the file when needed. }
   var
      NumRead:   word;    { The number of char read in BlockRead }

   { ------------------------------------------------------------------ }

   procedure CheckBufferWrap( Old_Index, New_Index: integer);
      { Checks to see if we should move from Buffer[ Old_Index] to }
      { Buffer[ New_Index].  If so, it reloads the buffer if needed. }
      { It is assumed the (Sentinel) has been encountered. }
      begin
         { Are we at the Tail of Buffer[ Old_Index]? }
         with BF.Buffer[ Old_Index] do begin
            if (C = Tail) then begin
                { Yes we are at the Tail, so mark old buffer for reloading }
                {    in the future. }
                Reload:= true;
                with BF.Buffer[ New_Index] do begin
                   { Point C to the first valid character in the Buffer }
                   C:= @Data[ 1];
                   if Reload then begin
                      BlockRead( BF.InFile, Data[ 1], BuffSize, NumRead);
                      { Make the next character past the last one read. }
                      Data[ succ( NumRead)]:= Sentinel;
                      Reload:= False;
                   end; { if Reload }
                end; { With BF.Buffer[ New_index] }
            end; { if }
         end; { with BF.Buffer[ OldIndex] }
      end; { CheckBufferWrap }

   { ------------------------------------------------------------------ }

   begin { Get_Chr }
      inc( C);

      if (C^ = Sentinel) then begin
         { Check to see if we need to move to the other buffer. }
         { Since we do not know which one we are in, we need to }
         { check both of them. }
         CheckBufferWrap( 0, 1);
         CheckBufferWrap( 1, 0);
      end; { if }

   end; { Get_Chr }

{ ************************************************************************ }

Procedure Unget_Chr( var BF: TBuffered_File; var C: tpChar);
   { Points C to the previous character in the buffered file. }

   { ------------------------------------------------------------------ }

   procedure CheckBufferWrap( Old_Index, New_Index: integer);
      { Checks to see if we should move from Buffer[ Old_Index] to }
      { Buffer[ New_Index]. }
      { It is assumed the (Sentinel) has been encountered. }
      begin
         { Are we at the Head of Buffer[ Old_Index]? }
         if (C = BF.Buffer[ Old_Index].Head) then begin
             { Yes we are at the Head. }
             { Point C to the last valid character in the other Buffer }
             C:= @BF.Buffer[ New_Index].Data[ BuffSize];
         end; { if }
      end; { CheckBufferWrap }

   { ------------------------------------------------------------------ }


   begin { Unget_Chr }
      dec( C);

      if (C^ = Sentinel) then begin
         { Check to see if we need to move to the other buffer. }
         { Since we do not know which one we are in, we need to }
         { check both of them. }
         CheckBufferWrap( 0, 1);
         CheckBufferWrap( 1, 0);
      end; { if }

   end; { Unget_Chr }

{ ************************************************************************ }

{ ************************************************************************ }

{ ************************************************************************ }

{ ************************************************************************ }

{ ************************************************************************ }

end. // lbp_source_file unit
