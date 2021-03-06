{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Mechanism to record exception error messages for later output.

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

unit lbp_delayed_exceptions;

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

interface

uses
   lbp_types,
   lbp_lists,
   sysutils;


// *************************************************************************

type
   DelayedException = class( Exception);


procedure DelayException( E: Exception);
procedure RaiseDelayedExceptions( Message: string = '');


// *************************************************************************

implementation

// *************************************************************************

var
   ExceptionQ: DoubleLinkedList;  // Holds error message strings for each
                                  // delayed exception.


// ************************************************************************
// * DelayException() - Add an entry to the delayed exception queue
// ************************************************************************

procedure DelayException( E: Exception);
   var
      S: tStringObj;
   begin
      S:= tStringObj.Create( E.ClassName + ':  ' + E.Message);
      ExceptionQ.Enqueue( S);
   end; // DelayException()


// ************************************************************************
// * RaiseDelayedExceptions() - Raise a single exception which contains all
// *                            the exceptions saved with DelayException().
// *                            If no exceptions are saved, do nothing.
// ************************************************************************

procedure RaiseDelayedExceptions( Message: string);
   var
      ErrorStr:   string = '';
      S:          tStringObj;
   begin
      while( not ExceptionQ.Empty()) do begin
         S:= tStringObj( ExceptionQ.DeQueue);
         if( Length( ErrorStr) = 0) then begin
            ErrorStr:= Message;
         end;
         ErrorStr:= ErrorStr + LineEnding + S.Value;
         S:= tStringObj( ExceptionQ.DeQueue);
      end;
      if( Length( ErrorStr) > 0) then begin
         raise DelayedException.Create( ErrorStr);
      end;
   end; // RaiseDelayedExceptions()



// =========================================================================
// = Initialization and finalization
// =========================================================================

var
   S: tStringObj;

// *************************************************************************
// * initialization
// *************************************************************************

initialization
   begin
      ExceptionQ:= DoubleLinkedList.Create();
   end; // initialization


// *************************************************************************
// * finalization
// *************************************************************************

finalization
   begin
      while( not ExceptionQ.Empty()) do begin
         S:= tStringObj( ExceptionQ.Dequeue);
         S.Destroy;
      end;
      ExceptionQ.Destroy;
   end; // finalization


// *************************************************************************

end. // lbp_delayed_exceptions
