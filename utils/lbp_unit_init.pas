{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

delay initialization of a unit

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

// A unit used to delay initialization of other units;
//
// Units using this unit should pass a function which takes no parameters and
// does initialization to the AddUnitInitProc() function.
//    Ex:  AddUnitInitProc( @MyInitialization);
//
// Programs using this unit or units which use this unit should call
// InitializeUnits()
//
// An example for a usage case is a database unit which uses command line
// arguments for database connection fields.  Then another unit whose
// purpose is to create a class populated with data from the database for
// quick lookup by other parts of the program.  The lbp_argv is designed
// to read command line parameters when called by the main process after
// it has optionally added useage information.  Therefore, the initialization
// of the lookup class has to come after the command line arguments are read.

unit lbp_unit_init;

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_types,
   lbp_lists,
   sysutils;

   
// ************************************************************************

type
   tUnitInitProc = procedure();

procedure AddUnitInitProc( P: tUnitInitProc);
procedure InitializeUnits();


// ************************************************************************

implementation

var
   UnitInitProcList:  DoubleLinkedList;  // A list of unit initialization procedures to be run


// ************************************************************************
// * AddUnitInitProc() - Addd the passed procedure to the list of
// *                           procedures to be called by the main procedure
// *                           when it is ready initialize units
// ************************************************************************

procedure AddUnitInitProc( P: tUnitInitProc);
   begin
      UnitInitProcList.Enqueue( P);
   end; // AddUnitInitProc();


// ************************************************************************
// * InitializeUnits() - Call each delayed initialization procedure
// *                           procedures to be called by the main procedure
// *                           when it is ready initialize units
// ************************************************************************

procedure InitializeUnits();
   var
      P: tUnitInitProc;
   begin
      while not UnitInitProcList.Empty do begin
         P:= tUnitInitProc( UnitInitProcList.Dequeue);
         P();
      end;
      UnitInitProcList.Destroy;
      UnitInitProcList:= nil;
   end; // InitializeUnits()


// ========================================================================
// = Initialization and Finalization
// ========================================================================
// ************************************************************************

initialization
   begin
      UnitInitProcList:= DoubleLinkedList.Create();
   end; // initialization


// ************************************************************************

finalization
   begin
      // The elements are procedure pointers and not classes.  So we don't
      // want to call Destroy() on each element when we clear the list.
      if( UnitInitProcList <> nil) then begin
         UnitInitProcList.RemoveAll( false);
         UnitInitProcList.Destroy();
      end;
   end; // finalization;


// ************************************************************************
end. // lbp_unit_init unit
