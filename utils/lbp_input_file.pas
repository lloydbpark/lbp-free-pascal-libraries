{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Open a file for input based on command line options
Note:  You must call SetInputFileParam() before parsing arguments!

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

unit lbp_input_file;

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_types,
{$ifdef UNIX}
   baseunix,
   termio,   // isatty()
{$else}
   jwawinbase,
//    windowns,  // In order to fake isatty()
{$endif}
   classes, // tHandleStream
   lbp_argv;


// ************************************************************************

var
   InputFile:       text;
   InputStream:     tHandleStream;
   InputFileHandle: tHandle;  // the UNIX or Windows file handle associated with InputFile


// ************************************************************************

function  IsATTY( Handle: longint): boolean;
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
{$ifdef WINDOWS}
   WinPipe:     boolean = false;  // Set to true to enable an input pipe  
{$endif}        

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
{$else} // Windows version
function IsATTY( Handle: Longint): Boolean;
   var
      FileInfo: tByHandleFileInformation;
   begin
      result:= not GetFileInformationByHandle( Handle, FileInfo);
      writeln( 'IsATTY() = ', result);
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
     Usage: string = 'The optional input file name.';
     PipeUsage: string = 'Allow the input to come from a pipe' +
                LineEnding + '                                 on Windows Systems';
   begin
      DoNotOpen:= not DoOpen;
      IsRequired:= Required;
      if( Required) then begin
         Usage:= 'The input file name.  This parameter or a pipe' +
                 LineEnding + '                                 is required';
{$ifdef WINDOWS}
         WinPipe:= true;
{$endif}
      end;
      if( AsOption) then begin
         AddUsage( '   ========== Input File library ==========');
         if( DoOpen) then begin
            AddUsage( '      Allows the user to pass an input file name to the program or to read');
            AddUsage( '      its input from a command line pipe.');
         end;
         if( UseF) then begin
            AddParam( ['f','input-file'], true, '', Usage);
{$ifdef WINDOWS}
            if( not Required) then begin
               AddParam( ['w','winpipe'], false, '', PipeUsage);
            end;
{$endif}
         end else begin
            AddParam( ['input-file'], true, '', Usage);
{$ifdef WINDOWS}
            if( not Required) then begin
               AddParam( ['winpipe'], false, '', PipeUsage);
            end;
{$endif}
         end;
      end else begin
         if( useF) then begin
            InsertParam( ['f','input-file'], true, '', Usage);
{$ifdef WINDOWS}
            if( not Required) then begin
               InsertParam( ['w','winpipe'], false, '', PipeUsage);
            end;
{$endif}
         end else begin
            InsertParam( ['input-file'], true, '', Usage);
{$ifdef WINDOWS}
            if( not Required) then begin
               InsertParam( ['winpipe'], false, '', PipeUsage);
            end;
{$endif}
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
      if( lbp_types.show_init) then writeln( 'lbp_input_file.ParseArgV:  begin');

{$ifdef WINDOWS}
      if( not IsRequired) then WinPipe:= ParamSet( 'winpipe');
{$endif}
      if( ParamSet( 'input-file')) then begin
         if( not DoNotOpen) then begin
            FileName:= GetParam( 'input-file');
            assign( InputFile, FileName);
            reset( InputFile);
            Opened:= true;
            Available:= true;
         end;
{$ifdef UNIX}
      // Do we read from the input pipe?
      end else if( (not IsATTY( 0)) and (not DoNotOpen)) then begin
         InputFile:= Input;
         Available:= true;
      end else if( IsRequired) then begin
{$endif}
{$ifdef WINDOWS}
      end else if( WinPipe and (not DoNotOpen)) then begin
         InputFile:= Input;
         Available:= true;
      end else if( IsRequired) then begin
{$endif}
         lbp_argv.Usage( true, 'No input file was specified and no input from a pipe is available!');
      end;
      // Get the UNIX or windows file handle of InputFile
      if( Available) then begin
         InputFileHandle:= TextRec( InputFile).Handle;
         InputStream:= tHandleStream.Create( InputFileHandle);
      end;
      if( lbp_types.show_init) then writeln( 'lbp_input_file.ParseArgV:  end');
   end; // ParseArgV


// *************************************************************************

initialization
   begin
      // Add Usage messages
      if( lbp_types.show_init) then writeln( 'lbp_input_file.initialization:  begin');
      AddPostParseProcedure( @ParseArgv);

      if( lbp_types.show_init) then writeln( 'lbp_input_file.initialization:  end');
   end;


// ************************************************************************

finalization
   begin
      if( lbp_types.show_init) then writeln( 'lbp_input_file.finalization:  begin');
      if( Opened) then close( InputFile);
      if( Available) then InputStream.Destroy;
      if( lbp_types.show_init) then writeln( 'lbp_input_file.finalization:  end');
   end;


// *************************************************************************

end. // lbp_input_file unit
