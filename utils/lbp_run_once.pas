{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

make sure only one copy of a program can run at the same time

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

unit lbp_run_once;
// Prevents a program which uses this unit from running more than once at a
// time unless a link or symbolic link with a different name is used to
// start the program.  Uses the standard /var/run/<Program Name> method.


interface

{$include lbp_standard_modes.inc}
{$I-}    // Turn off I/0 checking
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   lbp_argv,
   lbp_INI_Files,
   lbp_Types,
   BaseUnix,   // fpFork(), fpgetpid(), ...
   UnixUtil,   // BaseName()
   SysUtils;   //


// ************************************************************************

type
   DaemonizeOKException = class( lbp_exception);
   DaemonizeFailedException = class( lbp_exception);
   RunOnceException = class( lbp_exception);

var
   MyPID:           int32;
   MyPIDStr:        String;

procedure Daemonize();
function  IsDaemon(): boolean;


// ************************************************************************


implementation

const
   ClearVarRunFile: boolean = true;
   DoRunOnce:       boolean = false;
   DoDaemon:        boolean = false;
   Daemonized:      boolean = false;


// ************************************************************************
// * GetVarRunName() - Returns the name of the /var/run/ PID file name.
// ************************************************************************

function GetVarRunName(): string;
   var
      VarRunName: string;
      TempStr:    string;
   begin
      VarRunName:= '/var/run';
      if( fpAccess( VarRunName, W_OK) = 0) then begin
         VarRunName:= VarRunName + '/' + ProgramName + '.pid';
      end else begin
         Str( fpGetUID(), TempStr);
         VarRunName:= '/tmp/' + TempStr + '-' + ProgramName + '.pid';
      end;
      GetVarRunName:= VarRunName;
   end; // GetVarRunName();


// ************************************************************************
// * Daemonize() - Turn the program into a daemon.
// ************************************************************************

procedure Daemonize();
   var
      PID:        int32;
      VarRunName: string;
      VarRunFile: Text;
   begin
      PID:= fpFork();

      case PID of
         0:  begin // The child follows this path
               // Close the standard I/O files
               Close( INPUT);
               Close( OUTPUT);
               Assign( OUTPUT,'/dev/null');
               ReWrite( OUTPUT);
               Close( STDERR);
               Assign( STDERR,'/dev/null');
               ReWrite( STDERR);

               // Get our new process ID.
               MyPID:= fpGetPID();
               Str( MyPID, MyPIDStr);

                // Record our PID in our new /var/run file.
               VarRunName:= GetVarRunName();
               assign( VarRunFile, VarRunName);
               rewrite( VarRunFile);
               write( VarRunFile, MyPID);
               close( VarRunFile);

               Daemonized:= true;
             end;
         -1: Raise DaemonizeFailedException.Create(
                'Failed to fork in Daemonize()!');
         else begin
            Raise DaemonizeOKException.Create(
                'Normal exit of Daemonize() for the parent.');
         end;
      end; // case
   end; // Daemonize();


// ************************************************************************
// * IsDaemon() - Returns true if the program is running as a  daemon
// ************************************************************************

function IsDaemon(): boolean;
   begin
      IsDaemon:= Daemonized;
   end; // IsDaemon()


// ************************************************************************
// * RunOnceCheck() - Called by initialization to make sure the program
// *                  only runs one copy at a time.  As a side effect, the
// *                  file var/run/<ProgramName> contains the text
// *                  representation of the program's PID.
// ************************************************************************

procedure RunOnceCheck();
   var
      VarRunName: string;
      VarRunFile: Text;
      FileInfo:   stat;
      TempPID:    int32;
      TempStr:    string;
      ConvResult: integer;
   begin
      VarRunName:= GetVarRunName();
      assign( VarRunFile, VarRunName);

      // Does the file already exist?
      if( fpstat( VarRunName, FileInfo) = 0) then begin

         // Read the PID of the last copy.
         reset( VarRunFile);
         readln( VarRunFile, TempStr);
         val( TempStr, TempPID, ConvResult);

         // Make sure the conversion worked and the process isn't us?
         if( (ConvResult = 0) and (TempPID <> MyPID)) then begin

            // Is the process still running?
            if( fpstat( '/proc/' + TempStr, FileInfo) = 0) then begin
               // Don't clear the /var/run file.  The other process owns it!.
               ClearVarRunFile:= false;
               raise RunOnceException.Create(
                                       'Another copy of this program (' +
                                       ProgramName + ')is already running!');
            end;
         end; // If the PID file had a number in it.

      end;

      // Record our PID
      rewrite( VarRunFile);
      write( VarRunFile, MyPID);
      close( VarRunFile);
   end; // RunOnceCheck()


// ************************************************************************
// * CleanUp() - Remove the PID file if it exists
// ************************************************************************

procedure CleanUp();
   var
      VarRunName: String;
      VarRunFile: Text;
   begin
      if( ClearVarRunFile) then begin
         // Daemonize was NOT called, so clean up the VarRun file
         VarRunName:= GetVarRunName();
         if( FileExists( VarRunName)) then begin
            assign( VarRunFile, VarRunName);
            erase( VarRunFile);
         end;
      end;
   end; // CleanUp()


// *************************************************************************
// * ReadOptions() - Read INI and command line options
// *************************************************************************

procedure ReadOptions();
   begin
      // Read the INI file options, if any
      if( INI <> nil) then begin
         ClearVarRunFile:= INI.ReadVariable(
               'RunOnce', 'ErasePIDFileOnExit', ClearVarRunFile);
         DoRunOnce:= INI.ReadVariable( 'RunOnce', 'OnlyOnce', DoRunOnce);
         DoDaemon:= INI.ReadVariable( 'RunOnce', 'Daemon', DoDaemon);
      end;

      // Read the command line options, if any
      if( ParamSet( 'no-run-once')) then DoRunOnce:= false
      else if( ParamSet( 'run-once')) then DoRunOnce:= true;
      if( ParamSet( 'no-daemon')) then DoDaemon:= false
      else if( ParamSet( 'daemon')) then DoDaemon:= true;
      
      // Do the run-once check and/or daemonize as needed
      MyPID:= fpGetPID();
      Str( MyPID, MyPIDStr);

      if( DoRunOnce) then begin
         RunOnceCheck();
      end;

      if( DoDaemon) then begin
         try
            Daemonize();
         except
            On E: DaemonizeOKException do begin
               // Parent process
               Halt;
            end;
         end; // try/except
      end; // if
   end; // ReadOptions();


// ************************************************************************

initialization
   begin
      // Add Usage messages
      AddUsage( '   ========== Run Once / Service options ==========');
      AddParam( ['run-once'], false, '', 'Make sure only one copy of this program is');
      AddUsage( '                                    running at a time.');
      AddParam( ['no-run-once'], false, '','Override an INI run-once setting');
      AddParam( ['daemon'], false, '', 'Run the program as a Windows service or UNIX');
      AddUsage( '                                    daemon.');
      AddParam( ['no-daemon'], false, '','Override an INI deamon setting');
      AddUsage();
      
      AddPostParseProcedure( @ReadOptions);
   end;


// ************************************************************************

finalization
   begin
      CleanUp();
   end;


// ************************************************************************

end.

