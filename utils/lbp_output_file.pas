{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Open a file for output based on command line options

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

unit lbp_output_file;

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_types,
   lbp_argv,
   classes; // tHandleStream


// ************************************************************************

var
   OutputFile:       text;
   OutputStream:     tHandleStream;
   OutputFileHandle: tHandle;  // the UNIX or Windows file handle associated with OutputFile

// ************************************************************************

function  OutputAvailable(): boolean;
procedure SetOutputFileParam( Required: boolean = true;   // must have an output file
                              UseO:     boolean = true;  // Add '-o' as an aliase paramater
                              AsOption: boolean = true;  // Add the parameter in its own section
                              DoOpen: boolean = true);   // Open the OutputFile


// ************************************************************************


implementation

// ************************************************************************

var
   Opened:      boolean = false;
   Available:   boolean = false;
   IsRequired:  boolean = true;   // Set this to false if the Output file is optional
   DoNotOpen:   boolean = false;

// ************************************************************************
// * OutputAvailable() Returns true if the output file is available
// ************************************************************************

function OutputAvailable(): boolean;
   begin
      result:= Available;
   end; // OutputAvailable()


// ************************************************************************
// * SetOutputFileParam() - Adds the parameter to the ArgV system.
// *                       if AsOption is true the parameter is added in
// *                       its own section.  If false, it is instered for
// *                       use in the main program's options.
// *                       if UseO is true, add '-o' as an alias for this
// *                       parameter.
// ************************************************************************

procedure SetOutputFileParam( Required: boolean;
                              UseO:     boolean;
                              AsOption: boolean;
                              DoOpen:   boolean);
   var
     Usage: string = 'The output file name.';
   begin
      DoNotOpen:= not DoOpen;
      IsRequired:= Required;
      if( Required) then begin
         Usage:= 'The output file name.  This parameter is required.';
      end else begin
         Usage:= 'The optional output file name.';
      end;
      if( AsOption) then begin
         AddUsage( '   ========== Output File library ==========');
         AddUsage( '      Allows the user to redirect the output to the named file.');
         if( UseO) then begin
            AddParam( ['o','output-file'], true, '', Usage);
         end else begin
            AddParam( ['output-file'], true, '', Usage);
         end;
         AddUsage( '');
      end else begin
         if( UseO) then begin
            InsertParam( ['o','output-file'], true, '', Usage);
         end else begin
            InsertParam( ['output-file'], true, '', Usage);
         end;
      end;
   end; // SetOutputFileParam()



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
      if( lbp_types.show_init) then writeln( 'lbp_output_file.ParseArgV:  begin');

      if( ParamSet( 'output-file')) then begin
         if( not DoNotOpen) then begin
            FileName:= GetParam( 'output-file');
            assign( OutputFile, FileName);
            rewrite( OutputFile);
            Opened:= true;
            Available:= true;
         end;
      end else if( IsRequired) then begin
         raise lbp_exception.Create( 'No output file was specified!');
      end else begin
         flush( Output);
         OutputFile:= Output;
         Available:= true;
      end;
      // Get the UNIX or windows file handle of OutputFile
      if( Available) then begin
         OutputFileHandle:= TextRec( OutputFile).Handle;
         OutputStream:= tHandleStream.Create( OutputFileHandle);
      end;
      if( lbp_types.show_init) then writeln( 'lbp_output_file.ParseArgV:  end');
   end; // ParseArgV


// *************************************************************************

initialization
   begin
      // Add Usage messages
      if( lbp_types.show_init) then writeln( 'lbp_output_file.initialization:  begin');
      AddPostParseProcedure( @ParseArgv);

      if( lbp_types.show_init) then writeln( 'lbp_output_file.initialization:  end');
   end;


// ************************************************************************

finalization
   begin
      if( lbp_types.show_init) then writeln( 'lbp_output_file.finalization:  begin');
      flush( OutputFile);
      if( Opened) then close( OutputFile);
      if( Available) then OutputStream.Destroy;
      if( lbp_types.show_init) then writeln( 'lbp_output_file.finalization:  end');
   end;


// *************************************************************************

end. lbp_output_file unit
