{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Definition of common types

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

unit lbp_types;

// Simple ordinal types so we don't get confused about what size integer we
// are using.

// Also adds a generic Exception which can contain a pointer to the class,
// object or whatever which is related to the error.

interface

{$include lbp_standard_modes.inc}

uses
   sysutils;   // Exceptions


// *************************************************************************

// Ordinal types
type
   int8   = -$80..$7f;
   int16  = -$8000..$7fff;
   int32  = -$80000000..$7fffffff;
// int64    is already defined in the RTL.
   word8  = 0..$ff;
   word16 = 0..$ffff;
   word32 = 0..$ffffffff;
   word64 = qword; // for consistancy
   size_t = int32; // Used by many standard C calls

   int8ptr   = ^int8;
   int16ptr  = ^int16;
   int32ptr  = ^int32;
   word8ptr  = ^word8;
   word16ptr = ^word16;
   word32ptr = ^word32;
   word64ptr = ^word64;


const
   MaxInt8   = High( int8);
   MinInt8   = Low( int8);
   MaxInt16  = High( Int16);
   MinInt16  = Low( Int16);
   MaxInt32  = High( Int32);
   MinInt32  = Low( Int32);
   MaxWord8  = $ff;
   MaxWord16 = $ffff;
   MaxWord32 = $ffffffff;

var
   MaxInt64:  int64;
   MinInt64:  int64;
   MaxWord64: word64;


// -------------------------------------------------------------------------

function BooleanToString( B: boolean): string;


// -------------------------------------------------------------------------

// Simple Array types

type
   CharArray   = array of char;
   StringArray = array of String;
   int8Array   = array of int8;
   int16Array  = array of int16;
   int32Array  = array of int32;
   word8Array  = array of word8;
   word16Array = array of word16;
   word32Array = array of word32;
   word64Array = array of word64;

function ToStringArray( A: array of string): StringArray;

// -------------------------------------------------------------------------

// For lack of a good place to put this, I placed it here.  It allows my
// units to print debug information to stdout.  They are set true when the 
// lbp_argv unit is initialized and the user has entered --show-init as 
// a parameter to the program.

var
   show_init:       boolean = false;
   show_progress:   boolean = false;
   show_debug:      boolean = false;

// -------------------------------------------------------------------------

type
   tProcedure = procedure();


// -------------------------------------------------------------------------

   StringPtr = ^String;


// -------------------------------------------------------------------------

   lbp_exception = class( Exception)
      public
         constructor Create( const iMessage: String);
         constructor Create( const iMessage: String;
                             const Args:     array of const);
         procedure   DumpCallStack();
      end; // lbp_exception class


// -------------------------------------------------------------------------
{$warning Put a case statement in tStringObj for different Aux types}
 
   tStringObj = class
      public
         Value:       string;
         AuxPointer:  pointer;  // Used to attach some user object
         AuxInteger:  integer;
         constructor  Create( S: string);
         destructor   Destroy; override;
      end;


// -------------------------------------------------------------------------

   tWord64Obj = class
      public
         Value:      word64;
         constructor Create( X: word64);
      end;


// -------------------------------------------------------------------------

   tInt64Obj = class
      public
         Value:      int64;
         constructor Create( X: int64);
      end;


// -------------------------------------------------------------------------

   tWord32Obj = class
      public
         Value:      word32;
         constructor Create( X: word32);
      end;


// -------------------------------------------------------------------------

   tInt32Obj = class
      public
         Value:      int32;
         constructor Create( X: int32);
      end;


// -------------------------------------------------------------------------

   tObjProcedure = procedure( E: tObject);


// *************************************************************************
// * tCompareProcedure() - Should return:
// *             1  if E1 > E2
// *             -1 if E1 < E2
// *             0  if E1 = E2
// *************************************************************************

type
   tCompareProcedure = function( Obj1: tObject; Obj2: tObject): int8;

// Use these standard comparison functions for simple comparison objects.
function AllwaysSmaller( O1: tObject; O2: tObject): int8;
function CompareString(  S1: tObject; S2: tObject): int8;
function CompareWord64(  N1: tObject; N2: tObject): int8;
function CompareInt64(   N1: tObject; N2: tObject): int8;
function CompareWord32(  N1: tObject; N2: tObject): int8;
function CompareInt32(   N1: tObject; N2: tObject): int8;


// *************************************************************************


implementation


// ========================================================================
// = tStringObj
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tStringObj.Create( S: string);
   begin
      Value:= S;
   end; // Create();


// ************************************************************************
// * Destroy() - Destructor
// ************************************************************************

destructor tStringObj.Destroy();
   begin
      Value:= '';
   end; // Destroy();



// ========================================================================
// = tWord64Obj
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tWord64Obj.Create( X: word64);
   begin
      Value:= X;
   end; // Create();



// ========================================================================
// = tInt64Obj
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tInt64Obj.Create( X: int64);
   begin
      Value:= X;
   end; // Create();



// ========================================================================
// = tWord32Obj
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tWord32Obj.Create( X: word32);
   begin
      Value:= X;
   end; // Create();



// ========================================================================
// = tInt32Obj
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tInt32Obj.Create( X: int32);
   begin
      Value:= X;
   end; // Create();



// ========================================================================
// = lbp_exception
// ========================================================================
// ************************************************************************
// Create() - Constructor
// ************************************************************************

constructor lbp_exception.Create( const iMessage: String);
   begin
      inherited Create( iMessage);
   end; // Create();


// -------------------------------------------------------------------------

constructor lbp_exception.Create( const iMessage:  String;
                                  const Args:      array of const);
   begin
      inherited Create( Format( iMessage, Args));
   end; // Create();


// ************************************************************************
// * DumpCallStack - Prints out the call stack just like the standard
// *                 exception handler.
// ************************************************************************

procedure lbp_exception.DumpCallStack();
   begin
      writeln( STDERR, 'Program exception! ' + LineEnding +
               '   Exception class: ' + ClassName + LineEnding +
               '   Message:         ' + Message + LineEnding);
      DumpExceptionBacktrace( STDERR);
   end; // DumpCallStack();


// ========================================================================
// = Utility functions
// ========================================================================
// ************************************************************************
// * BooleanToString() - Simple helper
// ************************************************************************

function BooleanToString( B: boolean): string;
   begin
      if( B) then result:= 'true' else result:= 'false';
   end; // BooleanToString()
   

// ========================================================================
// = Standard Comparison functions
// ========================================================================
// ************************************************************************
// * AllwaysSmaller() - Allways returns -1
// ************************************************************************

function AllwaysSmaller( O1: tObject; O2: tObject): int8;
   begin
      result:= -1;
   end; // AllwaysSmaller()

// ************************************************************************
// * CompareString()
// ************************************************************************

function CompareString( S1: tObject; S2: tObject): int8;
   var
      Temp1: tStringObj;
      Temp2: tStringObj;
   begin
      Temp1:= tStringObj( S1);
      Temp2:= tStringObj( S2);
      if( Temp1.Value > Temp2.Value) then begin
         result:= 1;
      end else if( Temp1.Value < Temp2.Value) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareString()


// ************************************************************************
// * CompareWord64()
// ************************************************************************

function CompareWord64(  N1: tObject; N2: tObject): int8;
   var
      Temp1: tWord64Obj;
      Temp2: tWord64Obj;
   begin
      Temp1:= tWord64Obj( N1);
      Temp2:= tWord64Obj( N2);
      if( Temp1.Value > Temp2.Value) then begin
         result:= 1;
      end else if( Temp1.Value < Temp2.Value) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // Compare()


// ************************************************************************
// * CompareInt64()
// ************************************************************************

function CompareInt64(   N1: tObject; N2: tObject): int8;
   var
      Temp1: tInt64Obj;
      Temp2: tInt64Obj;
   begin
      Temp1:= tInt64Obj( N1);
      Temp2:= tInt64Obj( N2);
      if( Temp1.Value > Temp2.Value) then begin
         result:= 1;
      end else if( Temp1.Value < Temp2.Value) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // Compare()


// ************************************************************************
// * CompareWord32()
// ************************************************************************

function CompareWord32(  N1: tObject; N2: tObject): int8;
   var
      Temp1: tWord32Obj;
      Temp2: tWord32Obj;
   begin
      Temp1:= tWord32Obj( N1);
      Temp2:= tWord32Obj( N2);
      if( Temp1.Value > Temp2.Value) then begin
         result:= 1;
      end else if( Temp1.Value < Temp2.Value) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // Compare()


// ************************************************************************
// * CompareInt32()
// ************************************************************************

function CompareInt32(   N1: tObject; N2: tObject): int8;
   var
      Temp1: tInt32Obj;
      Temp2: tInt32Obj;
   begin
      Temp1:= tInt32Obj( N1);
      Temp2:= tInt32Obj( N2);
      if( Temp1.Value > Temp2.Value) then begin
         result:= 1;
      end else if( Temp1.Value < Temp2.Value) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // Compare()



// =========================================================================
// = GlobalFunction
// =========================================================================
// ************************************************************************
// * ToStringArray() - Allows the caller to initialize a variable length
// *                   array of strings by passing the strings to this
// *                   function like this:
// *                   ToStringArray( ['one', 'two', 'threee'])
// ************************************************************************

function ToStringArray( A: array of string): StringArray;
   var
      i:    integer;
      L: integer;
   begin
      L:= length( A);
      setlength( result, L);
      dec( L);
      for i:= 0 to L do result[ i]:= A[ i];
   end; // ToStringArray()


// =========================================================================
// = Unit Initialization
// =========================================================================

var
   Temp: integer;

initialization;
   begin
      Val( '9223372036854775807', MaxInt64, Temp);
      Val( '-9223372036854775808', MinInt64, Temp);
      val( '18446744073709551615', MaxWord64, Temp);
   end;


// *************************************************************************

{$NOTES OFF} // Stops the message about Temp not being used.

end. // lbp_types unit
