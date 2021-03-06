{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Allows a program to tee its output like piping to the UNIX tee program.

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


// =========================================================================
// = This unit can create the following text file handles:
// =    Log:  by default the file is created in the current directory and
// =          named the same as the program with the extension '.log'.
// =    Tee:  This text file outputs to stdout and to the Log file.
// =========================================================================
// = The basis of this code came from the example at:
// =    http://www.tek-tips.com/faqs.cfm?fid=6944
// =========================================================================

program lbp_console_tee_log;

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

// interface

uses
   lbp_argv,
   sysutils;


// *************************************************************************

var
   Log: text;
   Tee: text;



// ************************************************************************

//implementation

// ************************************************************************


var
   DoLog:   boolean = false;  // Create and open the log file
   DoTee:   boolean = false;  // Replace Output with Tee file handler
   MyOutput: text;
type
   IOFunc = function( var F : TTextRec): integer;


// *************************************************************************
// *************************************************************************
// function CRTinput(var F: TTextRec): integer;
//   { input function for CRT, reads in up to bufsize bytes and places number of bytes
//     actually read into BufEnd. }
//   begin
//     if ReadConsole(F.Handle, F.BufPtr, DWord(F.BufSize), DWord(F.BufEnd), nil) then
//       Result := 0
//     else
//       Result := 8;
//     F.BufPos := 0;
//   end;

// *************************************************************************
// * TeeOutput() 
// *************************************************************************

function TeeOutput(var F: TTextRec): integer;
  { output function for CRT, writes BufPos bytes and resets the buffer position }
   var
      numwritten: integer;
   begin
      if WriteConsole(F.Handle, F.BufPtr, F.BufPos, NumWritten, nil) then
         Result := 0
      else
         Result := 8;
      F.BufPos := 0;
   end; // TeeOutput


// *************************************************************************
// *************************************************************************
// function CRTflush(var F: TTextRec): integer;
//   { flushes the buffer of the file -
//     for input, sets the buffer position and end to 0 - effectively wiping
//     out what is read
//     for output, calls InOutFunc to write the buffer out }
//   var
//     FPtr: IOFunc;
//   begin
//     if F.Mode = fmInput then
//       begin
//         F.BufPos := 0;
//         F.BufEnd := 0;
//       end;
//     if F.Mode = fmOutput then
//       begin
//         FPtr := F.InOutFunc;
//         Result := FPtr(F);  // address call to function, if not zero return, quit
//         if Result > 0 then
//           exit;
//       end;
//     Result := 0;
//   end;

// *************************************************************************
// *************************************************************************
// function CRTclose(var F: TTextRec): integer;
//   { called upon close file to do the work, flush buffer if output }
//   var
//     FPtr: IOFunc;
//   begin
//     if F.Mode = fmOutput then  // if output then need to flush the buffer }
//       begin
//         FPtr := F.InOutFunc;
//         Result := FPtr(F); // address call to function, if not zero return, quit
//         if Result > 0 then
//           exit;
//       end;
//     CloseHandle(F.Handle);   // close file here
//     Result := 0;
//   end;

// *************************************************************************
// *************************************************************************
// function CRTopen(var F: TTextRec): integer;
//   { called by reset/rewrite/append.  fmInput, fmOutput, fmInOut
//     this function opens the file for read or write, also sets proper read and
//     write routines for the file }
//   begin
//     F.CloseFunc := @CRTClose;
//     if F.Mode = fmInput then
//       begin
//         F.Handle := GetStdHandle(STD_INPUT_HANDLE); // open CRT input handle
//         F.InOutFunc := @CRTInput;
//         F.FlushFunc := @CRTFlush;
//       end;
//     if F.Mode = fmOutput then
//       begin
//         F.Handle := GetStdHandle(STD_OUTPUT_HANDLE);  // open CRT output handle
//         F.InOutFunc := @CRTOutput;
//         F.FlushFunc := @CRTFlush;
//         SetConsoleTextAttribute(F.Handle, FOREGROUND_BR_MAGENTA); // to make it do something interesting
//       end;
//     if F.Mode = fmInOut then
//       {F.Mode := fmOutput;} // normally do this, but for CRT, make error:
//       Result := 8           // since fmInOut doesn't make sense
//     else
//       Result := 0;
//   end;

// *************************************************************************
// *************************************************************************
// procedure CRTassign(var f: Text);
//   { prepares special file for assign }
//   begin
//     // start console
//     FreeConsole;
//     AllocConsole;
//     SetConsoleTitle('CRT Assign Console');
//     // standard initializations
//     With TTextRec(F) do
//       begin
//         Mode := fmClosed;
//         BufSize := SizeOf(Buffer);
//         BufPtr := @Buffer;
//         OpenFunc := @CrtOpen;
//         Name[0] := #0;
//       end;
//   end;


// *************************************************************************
// * ParseArgV() - Parse the command line parameters
// *************************************************************************

procedure ParseArgv();
   var
      LogFile: string;           // File name of the log file.
   begin
      DoLog:= ParamSet( 'log');
      if( ParamSet( 'log-file')) then begin
         LogFile:= GetParam( 'log-file');
         DoLog:= true;
      end else begin
         LogFile:= ProgramName + '.log';
      end;
      if( ParamSet( 'tee')) then begin
         DoTee:= true;
         DoLog:= true;
      end;

      if( DoLog) then begin
         Assign( Log, LogFile);
         Rewrite( Log);
      end;
      if( DoTee) then begin
         MyOutput:= Output;
         Tee:= Output;
         Tee.InOutFunc:= @TeeOut;
         Tee.FlushFunc:= @TeeFlush;
      end;
   end; // ParseArgV


// *************************************************************************
// * finalization - Close the files that were opened
// *************************************************************************

procedure finalize();
   begin
      if( DoTee) then Output:= MyOutput;
      if( DoLog) then Close( Log);
   end; // finalization

// *************************************************************************
// * Initialization - Setup the command line parameters
// *************************************************************************

procedure initialize();
   begin
      // Add Usage messages
      AddUsage( '   ========== Tee/Log Parameters ==========');
      AddUsage( '      This module optionally opens a ''Log'' and ''Tee'' file.');
      AddUsage( '      The ''tee'' file sends output to stdout and to the ''Log'' file.');
      AddParam( ['log'], false,'', 'Open a text log file.  By default the file');
      AddUsage( '                                 created in the current directory and');
      AddUsage( '                                 the program''s name with the ''.log''');
      AddUsage( '                                 extension.');
      AddParam( ['log-file'], true, ProgramName + '.log', 'Causes the log file to be opened using');
      AddUsage( '                                 the user specified name');
      AddParam( ['tee'], false, '', 'Makes ''Tee'' the default output.');
      AddPostParseProcedure( @ParseArgv);
   end; // initialization


// *************************************************************************
// * Main()
// *************************************************************************

begin
   initialize;
   ParseParams();

   writeln( Log, 'Hello world!');
   finalize;
end. // lbp_console_tee_log program
