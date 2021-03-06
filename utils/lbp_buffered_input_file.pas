{* ***************************************************************************

Copyright (c) 2018 by Lloyd B. Park

Buffers the input from a text file to facilitate parsing where line breaks are
just another optional white space.  It combines the features of lbp_input_file
and the buffering I incorporated in a compiler college class in 1993.

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
unit lbp_buffered_input_file;

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_types,
{$ifdef UNIX}
   baseunix,
   termio,
{$endif}
   lbp_argv;


// ************************************************************************

var
   InputFile:       file of char;
   InputFileHandle: tHandle;  // the UNIX or Windows file handle associated with InputFile

// ************************************************************************

{$ifdef UNIX}
function  IsATTY( Handle: longint): boolean;
{$endif}
function  InputAvailable(): boolean;
procedure SetInputFileParam( Required: boolean = true;  // must have an input file or pipe
                             UseF: boolean = true;     // Add '-f' as an aliase paramater
                             AsOption: boolean = true; // Add the parameter in its own section
                             DoOpen: boolean = true);   // Open the InputFile


// ************************************************************************


implementation

// ************************************************************************

var
   Opened:      boolean = false;
   Available:   boolean = false;
   IsRequired:  boolean = true;   // Set this to false if the Input file is optional
   DoNotOpen:   boolean = false;

// ************************************************************************
// * IsATTY() - Returns true if the passed file handle is a terminal as
// *            opposed to a file or pipe.
// ************************************************************************

{$ifdef UNIX}
Function IsATTY( Handle: Longint): Boolean;
   var
      t : Termios;
   begin
      IsAtty:= (TCGetAttr( Handle, t) = 0);
   end;
{$endif}

// ************************************************************************
// * InputAvailable() Returns true if the input file is available
// ************************************************************************

function InputAvailable(): boolean;
   begin
      result:= Available;
   end; // InputAvailable()


// ************************************************************************
// * SetInputFileParam() - Adds the parameter to the ArgV system.
// *                       if AsOption is true the parameter is added in
// *                       its own section.  If false, it is instered for
// *                       use in the main program's options.
// *                       if UseF is true, add '-f' as an alias for this
// *                       parameter.
// ************************************************************************

procedure SetInputFileParam( Required: boolean;
                             UseF:     boolean;
                             AsOption: boolean;
                             DoOpen:   boolean);
   var
     Usage: string = 'The input file name.';
   begin
      DoNotOpen:= not DoOpen;
      IsRequired:= Required;
      if( Required) then begin
         Usage:= 'The input file name.  This parameter or a pipe' +
                 LineEnding + '                                 is required';
      end else begin
         Usage:= 'The optional input file name.';
      end;
      if( AsOption) then begin
         AddUsage( '   ========== Input File library ==========');
{$ifdef UNIX}
        if( DoOpen) then begin
           AddUsage( '      Allows the user to pass an input file name to the program or to read');
           AddUsage( '      its input from a command line pipe.');
        end;
{$else}
         AddUsage( '      Allows the user to pass an input file name to the program');
{$endif}
         if( UseF) then begin
            AddParam( ['f','input-file'], true, '', Usage);
         end else begin
            AddParam( ['input-file'], true, '', Usage);
         end;
         AddUsage( '');
      end else begin
         if( UseF) then begin
            InsertParam( ['f','input-file'], true, '', Usage);
         end else begin
            InsertParam( ['input-file'], true, '', Usage);
         end;
      end;
   end; // SetInputFileParam()



// ========================================================================
// * Unit initialization and finalization.
// ========================================================================
// *************************************************************************
// * ParseArgV() - Read and initialize INI variables.  Then parse the
// *               command line parameters which will override INI settings.
// *************************************************************************

procedure ParseArgv();
   var
      FileName: string;
   begin
      if( lbp_types.show_init) then writeln( 'lbp_buffered_input_file.ParseArgV:  begin');

      if( ParamSet( 'input-file')) then begin
         if( not DoNotOpen) then begin
            FileName:= GetParam( 'input-file');
            assign( InputFile, FileName);
            reset( InputFile);
            Opened:= true;
            Available:= true;
         end;
{$ifdef UNIX}
      end else if( (not IsATTY( 0)) and (not DoNotOpen)) then begin
         InputFile:= Input;
         Available:= true;
{$endif}
      end else if( IsRequired) then begin
         raise lbp_exception.Create( 'No input file was specified and no input from a pipe is available!');
      end;
      // Get the UNIX or windows file handle of InputFile
      if( Available) then begin
         InputFileHandle:= FileRec( InputFile).Handle;
      end;
      if( lbp_types.show_init) then writeln( 'lbp_buffered_input_file.ParseArgV:  end');
   end; // ParseArgV


// *************************************************************************

initialization
   begin
      // Add Usage messages
      if( lbp_types.show_init) then writeln( 'lbp_buffered_input_file.initialization:  begin');
      AddPostParseProcedure( @ParseArgv);

      if( lbp_types.show_init) then writeln( 'lbp_buffered_input_file.initialization:  end');
   end;


// ************************************************************************

finalization
   begin
      if( lbp_types.show_init) then writeln( 'lbp_buffered_input_file.finalization:  begin');
      if( Opened) then close( InputFile);
      if( lbp_types.show_init) then writeln( 'lbp_buffered_input_file.finalization:  end');
   end;


// *************************************************************************

end.  // lbp_buffered_input_file unit
