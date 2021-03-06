{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Handles various methods of logging

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

unit lbp_Log;  // Provides a common Log() function which can log to standard
              // out, a text file, or the syslog.

// Currently defined INI variables are:
//    [KSULog]
//    // Minimum log level sent to the log.
//    LogLevel=Debug
//    // Possible Syslog levels, are in order:
//    //   Debug, Info, Notice, Warning, Err, Crit, Alert, Emerg
//    //   NOTE:  Case is important!!!
//    Logging=yes
//    LogFile=/tmp/testrunonce.log
//    UseSysLog=false


interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

// SignalHandler for our timestamp when printing to a file or OUTPUT
uses
   lbp_argv,
{$ifndef windows}
   SystemLog,
   lbp_current_time,
   lbp_run_once,      // IsDaemon function call
{$endif}
   SysUtils,        // FileExists()
   lbp_vararray,   // Variable length arrays
   lbp_types,      // int16
   lbp_lists,
   lbp_ini_files;


// ************************************************************************

const
   LOG_EMERG   = 0;
   LOG_ALERT   = 1;
   LOG_CRIT    = 2;
   LOG_ERR     = 3;
   LOG_WARNING = 4;
   LOG_NOTICE  = 5;
   LOG_INFO    = 6;
   LOG_DEBUG   = 7;

   LogLevel:           int16    = LOG_ERR; // Maximum log level we will use
   LogPrefix:          string   = '';

procedure Log( const Level: int16; const Msg: String);
procedure Log( const Level: int16; const Msg: String;
                                    const Args: array of const);
function  HexDumpToList( var Buffer; Length: word): DoubleLinkedList;
procedure LogHexDump( const Level: int16; var Buffer; Length: word;
                      Prefix: string);
procedure LogBoolean( const Level: int16; const Name: string; Value: boolean);

type
   lbp_log_exception = class( lbp_exception);
   
var
   LogCS: tRTLCriticalSection;  // For the use of other units and programs
                                // Not used internaly.

// ************************************************************************

implementation

const
   LogFileName:        string   = '';
   LogFileAppend:      boolean  = false;
   DoLogging:          boolean  = true;     // Output Log messages to OUTPUT.
   UseSyslog:          boolean  = false;    // Output them to Syslog instead
                                            //   of LogFile
                                            // stamp the event
   SyslogIsOpen:       boolean  = false;
   LogFileIsOpen:      boolean  = false;

var
   LogFile:            Text;
   CritSect:           TRTLCriticalSection;

   
// ************************************************************************
// * Log() - Send message to the log facility
// ************************************************************************

procedure Log( const Level: int16; const Msg: String);
   begin
      if( DoLogging and (Level <= LogLevel)) then begin
{$ifndef windows}
         EnterCriticalSection( CritSect);
         if( UseSyslog) then begin

            if( not SyslogIsOpen) then begin
               openlog( @LogPrefix[ 1], LOG_NOWAIT, LOG_DEBUG);
            end;

            syslog( Level, pchar( Msg), []);
         end else begin
            if( not CronIsRunning) then begin
               CurrentTime.Now();  // Set CurrentTime to the current time.
            end;
            writeln( LogFile, TimeStr(), '  ', Msg);
            Flush( LogFile);
         end;

         LeaveCriticalSection( CritSect);
      end; // if DoLogging
{$endif}
{$ifdef windows}
         writeln( LogFile, Msg);
         Flush( LogFile);
      end;
{$endif}
   end; // Log()


// ------------------------------------------------------------------------

procedure Log( const Level: int16; const Msg: String;
                                    const Args: array of const);
   begin
      Log( Level, Format( Msg, Args));
   end; // LogF


// ************************************************************************
// * HexDumpToList() - Creates a linked list of strings.  Each string
// *                   will hold a dump of up to 16 bytes of the Buffer.
// ************************************************************************

function HexDumpToList( var Buffer; Length: word): DoubleLinkedList;
   var
      L:           DoubleLinkedList;
      B:           BigByteArrayPtr;
      S:           StringPtr;
      HexValue:    string;
      StrValue:    string;
      i:           word;
      HexIndex:    shortint;
      StrIndex:    shortint;
      Temp:        byte;

   begin
     // This is just to stop the compiler warnings about uninitialized vars.
     S:= nil;
     HexValue:= '';
     StrValue:= '';

      L:= DoubleLinkedList.Create();

      if( Length > 0) then begin
         B:= @Buffer;

         // Convert the array of bytes to a hex dump format
         // For each byte
         for i:= 0 to Length - 1 do begin
            Temp:= B^[ i];

            // Create a new string for every 16 bytes
            if( (i mod 16) = 0) then begin
               if( i <> 0) then begin
                  S^:= HexValue + ' ' + StrValue;
               end;

               // Initialize the arrays
               StrValue:= StringOfChar( '.', 16);
               HexValue:= StringOfChar( ' ', 16 * 3);
               HexIndex:= 1;
               StrIndex:= 1;

               new( S);
               L.Enqueue( S);
            end;

            // Add to the character string.
            if( Chr( Temp) in  ['A'..'Z', 'a'..'z', '0'..'9', ' ']) then begin
               StrValue[ StrIndex]:= Chr( Temp);
            end;
            inc( StrIndex);

            // Handle the upper nibble
            Temp:= B^[ i] SHR 4;
            if( Temp > 9) then begin
               HexValue[ HexIndex]:= Chr( Temp + ord( 'a') - 10);
            end else begin
               HexValue[ HexIndex]:= Chr( Temp + ord( '0'));
            end;
            inc( HexIndex);

            // Handle the lower nibble
            Temp:= B^[ i] and 15;
            if( Temp > 9) then begin
               HexValue[ HexIndex]:= Chr( Temp + ord( 'a') - 10);
            end else begin
               HexValue[ HexIndex]:= Chr( Temp + ord( '0'));
            end;
            inc( HexIndex, 2);
         end; // For each byte

         S^:= HexValue + ' ' + StrValue;
      end; // If we passed a non-zero length.

      HexDumpToList:= L;
   end; // HexDumpToList();


// ************************************************************************
// * LogHexDump() - Dumps the hex representation of Length bytes from Buffer
// *                to Log.  The first line is prefixed with Prefix and every
// *                other line is prefixed with Length( Prefix) spaces.
// ************************************************************************

procedure LogHexDump( const Level:  int16;
                      var   Buffer;
                            Length: word;
                            Prefix: string);
   var
      L:      DoubleLinkedList;
      S:      StringPtr;
      Spaces: String;
   begin
      EnterCriticalSection( CritSect);
      Spaces:= StringOfChar( ' ', System.Length( Prefix));
      L:= HexDumpToList( Buffer, Length);

         // Output the first line
         if( not L.Empty()) then begin
            S:= StringPtr( L.Dequeue());
            Log( Level, Prefix + S^);
            dispose( S);
         end;

         // Output any other lines.
         while( not L.Empty()) do begin
            S:= StringPtr( L.Dequeue());
            Log( Level, Spaces + S^);
            dispose( S);
         end;
      L.Destroy();
      LeaveCriticalSection( CritSect);
   end; // LogHexDump()


// ************************************************************************
// * LogBoolean()
// ************************************************************************

procedure LogBoolean( const Level: int16; const Name: string; Value: boolean);
   var
      ValueStr: string;
   begin
      if( Value) then begin
         ValueStr:= 'true';
      end else begin
         ValueStr:= 'true';
      end;

      Log( Level, Name + ' = ' + ValueStr);
   end; // LogBoolean()


// *************************************************************************
// * StringToLogLevel() - Convert the string representation of a Log Level
// *                      to a number.  Returns a -1 on error!
// *************************************************************************

function StringToLogLevel( S: string): int16;
   var
      Temp:  string;
   begin
      Temp:= LowerCase( S);
      if( Temp = 'debug') then begin
         LogLevel:= LOG_DEBUG;
      end else if( Temp = 'info') then
         LogLevel:= LOG_INFO
      else if( Temp = 'notice') then
         LogLevel:= LOG_NOTICE
      else if( Temp = 'warning') then
         LogLevel:= LOG_WARNING
      else if( Temp = 'err') then
         LogLevel:= LOG_ERR
      else if( Temp = 'crit') then
         LogLevel:= LOG_CRIT
      else if( Temp = 'alert') then
         LogLevel:= LOG_ALERT
      else if( Temp = 'emerg') then
         LogLevel:= LOG_EMERG
      else
         result:= -1;
   end; // StringToLogLevel()


// *************************************************************************
// * ReadLogLevel() - Reads the log level from the .ini file.
// *************************************************************************

procedure ReadLogLevel( SectName: string);
   var
      TempS: String;
      TempL: int16;  // Temporary Log Level
   begin
      TempS:= INI.ReadVariable( SectName, 'LogLevel', '');
      TempL:= StringToLogLevel( TempS);
      If( TempL >= 0) then LogLevel:= TempL;
   end; // ReadLogLevel()


// *************************************************************************
// * ParseArgV() - Parse the command line parameters
// *************************************************************************

procedure ParseArgv();
   var
      logconsole: boolean;
      logfile:    boolean;
      logappend:  boolean;
      logsyslog:  boolean;
      LL:         string;
   begin
      // If the user asked for no logging, then clear logging and exit
      if( ParamSet( 'no-log')) then begin
         LogFileName:=   '';
         LogFileAppend:= false;
         DoLogging:=     false;
         UseSyslog:=     false;
         exit;
      end;
      
      logconsole:= ParamSet( 'log-console');
      logfile:=    ParamSet( 'log-file');
      logappend:=  ParamSet( 'log-file-append');
      logsyslog:=  ParamSet( 'syslog');
      
      if( logconsole) then begin
         if( logfile or logappend or logsyslog) then begin
            raise argv_exception.create( 'Only one log destination may be set!');
         end;
         DoLogging:= true;
         LogFileAppend:= false;
         LogFileName:= '';

      end else if( logfile) then begin
         if( logconsole or logappend or logsyslog) then begin
            raise argv_exception.create( 'Only one log destination may be set!');
         end;
         DoLogging:= true;
         LogFileAppend:= false;
         ParseHelper( 'log-file', LogFileName);

      end else if( logappend) then begin
         if( logconsole or logfile or logsyslog) then begin
            raise argv_exception.create( 'Only one log destination may be set!');
         end;
         DoLogging:= true;
         LogFileAppend:= true;
         ParseHelper( 'log-file-append', LogFileName);

      end else if( logsyslog) then begin
         if( logconsole or logfile or logappend) then begin
            raise argv_exception.create( 'Only one log destination may be set!');
         end;
         DoLogging:= true;
         LogFileAppend:= false;
         UseSyslog:= true;
         LogFileName:= '';
      end;
      
      if( ParamSet( 'log-level')) then begin
         ParseHelper( 'log-level', LL);
         case LL of
            'debug': LogLevel:= LOG_DEBUG;
            'info': LogLevel:= LOG_INFO;
            'notice': LogLevel:= LOG_NOTICE;
            'warning': LogLevel:= LOG_WARNING;
            'err': LogLevel:= LOG_ERR;
            'crit': LogLevel:= LOG_CRIT;
            'alert': LogLevel:= LOG_ALERT;
            'emerg': LogLevel:= LOG_EMERG;
            else begin
               raise lbp_log_exception.Create( 'An invalid --log-level was specified!');
            end;
         end; // case
      end; // if log-level
   end; // ParseArgV


// *************************************************************************
// * ReadINI() - Read the .ini file variables
// *************************************************************************

procedure ReadINI();
   var
      Sect1:         string = 'lbpLog';
      Sect2:         string = 'KentLog';
   begin
      if( INI <> nil) then begin
         // Logging variables using the new section name
         ReadLogLevel( Sect1);

         LogFileName:= INI.ReadVariable( Sect1, 'LogFile', LogFileName);
         LogfileAppend:= INI.ReadVariable( Sect1, 'LogFileAppend', LogFileAppend);
         DoLogging:=   INI.ReadVariable( Sect1, 'Logging', true);

         // Logging variables using the old section name
         ReadLogLevel( Sect2);

         LogFileName:= INI.ReadVariable( Sect2, 'LogFile', LogFileName);
         LogfileAppend:= INI.ReadVariable( Sect2, 'LogFileAppend', LogFileAppend);
         DoLogging:=   INI.ReadVariable( Sect2, 'Logging', DoLogging);

{$ifndef windows}
         UseSyslog:=   INI.ReadVariable( Sect1, 'UseSyslog', IsDaemon());
         UseSyslog:=   INI.ReadVariable( Sect2, 'UseSyslog', UseSyslog);
{$endif}
      end; // if
   end; // ReadINI()


// *************************************************************************
// * ReopenLog() - Reopen the log based on the current settings.
// *************************************************************************

procedure ReopenLog();
   begin
      if( LogFileIsOpen) then begin
         LogFileIsOpen:= false;
         Close( LogFile);
      end;

{$ifndef windows}
      // Are we trying to log to standard out when we are a daemon?
      if( IsDaemon() and (not UseSysLog) and (LogFileName = '')) then begin
         DoLogging:= false;
      end;
{$endif}
      // Don't do anything else unless we are logging.
      if( DoLogging) then begin
{$ifndef windows}
         if( UseSyslog) then begin

            // Open the Syslog if needed
            if( not SyslogIsOpen) then begin
               SyslogIsOpen:= true;
               LogPrefix:= ProgramName + '[' + lbp_Run_Once.MyPIDStr + ']';
               openlog( @LogPrefix[ 1], LOG_NOWAIT, LOG_DEBUG);
            end;
         end else begin
            // Not using syslog

            // Close the Syslog if needed
            if( SyslogIsOpen) then begin
               UseSysLog:= true;
               Log( LOG_DEBUG, 'Logging has been turned off.  Closing Syslog.');
               UseSysLog:= false;
               Closelog();
               SyslogIsOpen:= false;
            end;
{$endif}
            // Open the LogFile
            if( LogFileName <> '') then begin
               assign( LogFile, LogFileName);
               if( LogFileAppend and FileExists( LogFileName)) then begin
                  append( LogFile);
               end else begin
                  rewrite( LogFile);
               end;
               LogFileIsOpen:= true;
            end else begin
               LogFile:= OUTPUT;
            end;
{$ifndef windows}
         end; // if UseSyslog
{$endif}
      end; // if DoLogging
   end; // ReopenLog()


// *************************************************************************
// * ReadVars() - Read INI and command line variables.  Then open the log
// *************************************************************************

procedure ReadVars();
   begin
      ReadINI;
      ParseArgv;
      ReopenLog;
   end; // ReadVars();


// =========================================================================
// = Initialization and finalization
// =========================================================================
// ************************************************************************

Initialization
   begin
{$ifdef DEBUG_UNIT_INITIALIZATION} 
      writeln( 'Initialization of lbp_log started.'); 
{$endif}

      InitCriticalSection( CritSect);
      InitCriticalSection( LogCS);

      // Add Usage messages
      AddUsage( '   ========== Logging options ==========');
      AddParam( ['no-log'], false, '', 'Disable logging');
      AddParam( ['log-console'], false, '', 'Send log messages to the console.');
      AddParam( ['log-file'], true , '', 'Send log messages to the passed file name.');
      AddParam( ['log-file-append'], true , '', 'Like --log-file but append to an existing file');
      AddParam( ['syslog'], false , '', 'Send log messages to syslog');
      AddParam( ['log-level'], true, '', 'Set one of the log levels to one of ''debug'',');
     // ''Err'' is the default.');
      AddUsage( '                                    ''info'', ''notice'', ''warning'', ''err'', ''crit'',');
      AddUsage( '                                    ''alert'', or ''emerg''.  ''err'' is the default.');
      AddUsage( '');

      AddPostParseProcedure( @ReadVars);
      if( INI <> nil) then begin
         INI.ProcStack.Enqueue( @ReadVars);
      end;

{$ifdef DEBUG_UNIT_INITIALIZATION} 
      writeln( 'Initialization of lbp_log ended.');
{$endif}
   end;


// ************************************************************************

finalization
   begin
{$ifdef DEBUG_UNIT_INITIALIZATION} 
      writeln( 'Finalization of lbp_log started.'); 
{$endif}
{$ifndef windows}
      if( SyslogIsOpen) then begin
         CloseLog();
      end;
{$endif}
      if( LogFileIsOpen) then begin
         Close( LogFile);
      end;
      LogPrefix:= '';
      LogFileName:= '';
      DoneCriticalSection( CritSect);
      DoneCriticalSection( LogCS);
{$ifdef DEBUG_UNIT_INITIALIZATION} 
      writeln( 'Finalization of lbp_log ended.'); 
{$endif}
   end;


// ************************************************************************

end. // lbp_Log
