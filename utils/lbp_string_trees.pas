{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Defines balanced binary tree of strings.

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

unit lbp_string_trees;
// Creates a balanced binary tree of pointers.  Makes use of a comparison

{$include lbp_standard_modes.inc}

interface

uses
   lbp_binary_Trees,
   lbp_types;      // tStringObj


// *************************************************************************

type
   // StringTree
   tStringTree = class( tBalancedBinaryTree)
      public
         StringObj:    tStringObj;
      public
         constructor   Create( iDuplicateOK: boolean);
         procedure        Add(        Item: string); overload;
         procedure        Add(        Item: string; AuxPointer: pointer); overload;
         procedure        Add(        Item: string; AuxInteger: integer); overload;
         function         Find(       Item: string): tStringObj; overload;
         function         GetFirst(): string; overload;
         function         GetLast():  string; overload;
         function         GetNext():  string; overload;
         function         GetPrevious(): string; overload;
         procedure        Remove(     SearchItem:     string); overload;
         procedure        Dump; virtual; // Debug
      end; // tStringTree


// *************************************************************************

implementation


// =========================================================================
// = Global procedures
// =========================================================================
// *************************************************************************
// * CompareStrings - global function used only by tStringTree
// *************************************************************************

function CompareStrings(  S1: tStringObj; S2: tStringObj): int8;
   begin
      if( S1.Value > S2.Value) then begin
         result:= 1;
      end else if( S1.Value < S2.Value) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareStrings()


// =========================================================================
// = tStringTree
// =========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tStringTree.Create( iDuplicateOK: boolean);
   begin
      StringObj:= nil;
      inherited Create( tCompareProcedure( @CompareStrings), iDuplicateOK);
   end; //constructor


// *************************************************************************
// * Add() - Add a string to the tree
// *************************************************************************

procedure tStringTree.Add( Item: string); overload;
   begin
      StringObj:= tStringObj.Create( Item);
      inherited Add( StringObj);
   end; // Add()


// -------------------------------------------------------------------------

procedure tStringTree.Add( Item: string; AuxPointer: pointer); overload;
   begin
      StringObj:= tStringObj.Create( Item);
      StringObj.AuxPointer:= AuxPointer;
      inherited Add( StringObj);
   end; // Add()


// -------------------------------------------------------------------------

procedure tStringTree.Add( Item: string; AuxInteger: integer); overload;
   begin
      StringObj:= tStringObj.Create( Item);
      StringObj.AuxInteger:= AuxInteger;
      inherited Add( StringObj);
   end; // Add()


// *************************************************************************
// * Find() - Find the string in the tree and return the object which
// *          contains it
// *************************************************************************

function tStringTree.Find( Item: string): tStringObj;
   var
      O:  tStringObj;
   begin
      O:= tStringObj.Create( Item);
      StringObj:= tStringObj( inherited Find( O));
      result:= StringObj;
      O.Destroy;
   end; // Find()


// *************************************************************************
// * GetFirst() - Get the first string in the tree
// *************************************************************************

function tStringTree.GetFirst(): string;
   begin
      StringObj:= tStringObj( inherited GetFirst());
      if( StringObj = nil) then begin
         result:= '';
      end else begin
         result:= StringObj.Value;
      end;
   end; // GetFirst()


// *************************************************************************
// * GetLast() - Get the Last string in the tree
// *************************************************************************

function tStringTree.GetLast():  string;
   begin
      StringObj:= tStringObj( inherited GetLast());
      if( StringObj = nil) then begin
         result:= '';
      end else begin
         result:= StringObj.Value;
      end;
   end; // GetLast()


// *************************************************************************
// * GetNext() - Get the Next string in the tree
// *************************************************************************

function tStringTree.GetNext():  string;
   begin
      StringObj:= tStringObj( inherited GetNext());
      if( StringObj = nil) then begin
         result:= '';
      end else begin
         result:= StringObj.Value;
      end;
   end; // GetNext()


// *************************************************************************
// * GetPrevious() - Get the previous string in the tree
// *************************************************************************

function tStringTree.GetPrevious(): string;
   begin
      StringObj:= tStringObj( inherited GetPrevious());
      if( StringObj = nil) then begin
         result:= '';
      end else begin
         result:= StringObj.Value;
      end;
   end; // GetPrevious()


// *************************************************************************
// * Remove - Remove the string from the tree
// *************************************************************************

procedure tStringTree.Remove( SearchItem: string);
   var
      O: tStringObj;
   begin
      O:= tStringObj.Create( SearchItem);
      inherited Remove( O, true);
      StringObj:= nil;
      O.Destroy;
   end; // Remove()


// *************************************************************************
// * Dump() - Display all the strings in the tree.
// *************************************************************************

procedure tStringTree.Dump();
   var
      Value: string;
   begin
      Value:= GetFirst();
      while( Length( Value) > 0) do begin
         writeln( 'Debug:  tStringTree.Dump():  ', Value);
         Value:= GetNext();
      end;
   end; // Dump()



// *************************************************************************

end. // lbp_string_trees unit
