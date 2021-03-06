{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

<brief description of the file.  for exampl: Definition of common types>

accumulate error messages at different severity levels.

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

// This unit provides a mechanism to accumulate error messages at different 
// severity levels.  Then a program can conditionaly raise an exception based on
// the maximum severity of any error messages.

unit lbp_errors;

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_types,
   lbp_lists;


// *************************************************************************

type
   lbpErrorException = class( lbp_exception);


// *************************************************************************

type
   tSeverityEnum = (
      SeverityNone,
      SeverityWarning,
      SeverityOnProgramExit,
      SeverityOnProcedureExit,
      SeverityNow);

// *************************************************************************


type
   tlbpError = class
      protected
         MsgList: DoubleLinkedList;
      public
         MaxSeverity: tSeverityEnum;
         constructor  Create();
         destructor   Destroy(); override;
         procedure    Clear();
         procedure    AddMessage( Severity: tSeverityEnum; Msg: String);
         // vvv - Return true if any messages have been added at Severity level or above
         function     Check( Severity: tSeverityEnum): boolean;
         // vvv - Throw exception if any messages have been added at Severity level or above
         procedure    AbortCheck( Severity: tSeverityEnum);
         // vvv - Output the messages currently in the queue
         procedure    OutputMessages();
      end; // tlbpError class

// *************************************************************************

var
   lbpErrors: tlbpError;


// *************************************************************************

implementation


// =========================================================================
// = tlbpError
// =========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tlbpError.Create();
   begin
      inherited Create();

      MsgList:= DoubleLinkedList.Create();
      MaxSeverity:= SeverityNone;
   end; // Create()


// *************************************************************************
// * Destroy() - Destructor
// *************************************************************************

destructor tlbpError.Destroy();
   begin
      OutputMessages();
      MsgList.Destroy();
      inherited Destroy;
   end; // Destroy()


// *************************************************************************
// * Clear() - Clear the messages
// *************************************************************************

procedure tlbpError.Clear();
   var
      QedString: StringPtr;
   begin
      while not MsgList.Empty do begin
         QedString:= StringPtr( MsgList.Dequeue);
         dispose( QedString);
      end;
      MaxSeverity:= SeverityNone;
   end; // Clear


// *************************************************************************
// * AddMessage()
// *************************************************************************

procedure tlbpError.AddMessage( Severity: tSeverityEnum; Msg: String);
   var
      QedString: StringPtr;
   begin
      if( Severity > MaxSeverity) then MaxSeverity:= Severity;
      new( QedString);
      QedString^:= Msg;
      MsgList.Enqueue( QedString);
   end; // AddMessage()


// *************************************************************************
// * Check()
// *************************************************************************

function tlbpError.Check( Severity: tSeverityEnum): boolean;
   begin
      result:= (not MsgList.Empty) and (Severity <= MaxSeverity);
   end; // Check()


// *************************************************************************
// * AbortCheck()
// *************************************************************************

procedure tlbpError.AbortCheck( Severity: tSeverityEnum);
   begin
      if( (not MsgList.Empty) and (Severity <= MaxSeverity)) then begin
         OutputMessages;
         raise lbpErrorException.Create( 'Accumulated warnings/errors');
      end;
   end; // AbortCheck()


// *************************************************************************
// * OutputMessages()
// *************************************************************************

procedure tlbpError.OutputMessages();
   var
      QedString: StringPtr;
   begin
      while not MsgList.Empty do begin
         QedString:= StringPtr( MsgList.Dequeue);
         writeln( StdErr, QedString^);
         dispose( QedString);
      end;
   end; // OutputMessages()


// =========================================================================
// = Initialization and Finalization
// =========================================================================

initialization
   begin
      lbpErrors:= tlbpError.Create;
   end; 


// ************************************************************************

finalization
   begin
      lbpErrors.Destroy;
   end;


// ************************************************************************

end. 
