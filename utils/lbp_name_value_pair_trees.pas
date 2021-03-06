{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

A binary tree of name/value string pairs

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

unit lbp_name_value_pair_trees;
// Creates a balanced binary tree of Name/Value string pairs.  The tree is
// sorted and searched by Name and Value is retrieved using the Value property. 

{* ***************************************************************************

Redo this using both an AVL tree and a double linked list to hold the NvPair.
The NVPair object should contain the double linked list node so 

*************************************************************************** *}








{$include lbp_standard_modes.inc}

interface

uses
   lbp_binary_Trees,
   lbp_types;

// *************************************************************************
// * tgNVPNode - Name Value Pair node.
// *************************************************************************
type
   generic tNVPNode<T> = class
      protected
         MyName:  string;
         MyValue: T;
         procedure SetName( iName: string);
         function  GetName(): string;
         procedure SetValue( iValue: T);
         function  GetValue(): T;
      public
         constructor Create( iName: string; iValue: T = Default( T));
         property    Name:  string read GetName  write SetName;
         property    Value: T      read GetValue write SetValue;            
      end; //



// *************************************************************************
// * tgNameValuePairTree - Basic tree with case sensitive searching.
// *************************************************************************
type
   generic tgNameValuePairTree<T> = class( tBalancedBinaryTree)
      private type
         tNode = specialize tgNVPNode<T>;
      protected
         NVP:        tNode;
      public
         constructor  Create( iDuplicateOK: boolean);
         procedure    Add(  iName: string; iValue: string); overload;
         function     Find( iName: string): String; overload;
         function     GetFirst():  string; overload;
         function     GetLast():   string; overload;
         function     GetNext():   string; overload;
         function     GetPrevious(): string; overload;
         procedure    Remove( iName: string); overload;
         procedure    Dump; virtual; // Debug
      private
         function     GetValue(): T;
         function     CompareNames( N2: tNode): int8;
      public
         property     Value: T read GetValue;
      end; // tNameValuePairTree


// *************************************************************************

implementation

// =========================================================================
// = Global procedures
// =========================================================================
// *************************************************************************
// * CompareNames - global function used only by tNameValuePairTree
// *************************************************************************

function CompareNames(  P1: tNVPNode; P2: tNVPNode): int8;
   begin
      if( P1.MyName > P2.MyName) then begin
         result:= 1;
      end else if( P1.MyName < P2.MyName) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareNames()



// =========================================================================
// = tgNVPNode - Name Value Pair node.
// =========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tgNVPNode.Create( iName: string; iValue: T);
   begin
      Name:=  iName;
      Value:= iValue;
   end; // Create()


// *************************************************************************
// * SetName()
// *************************************************************************

procedure tgNVPNode.SetName( iName: string);
   begin
     MyName:= iName;
   end; // SetName()


// *************************************************************************
// * GetName()
// *************************************************************************

function tgNVPNode.GetName(): string;
   begin
      result:= MyName;
   end; // GetName()


// *************************************************************************
// * SetValue
// *************************************************************************

procedure tgNVPNode.SetValue( iValue: T);
   begin
     MyValue:= iValue;
   end; // SetValue()


// *************************************************************************
// * GetValue
// *************************************************************************

function tgNVPNode.GetValue(): T;
   begin
      result:= MyValue;
   end; // GetValue()



// =========================================================================
// = tgNameValuePairTree
// =========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tgNameValuePairTree.Create( iDuplicateOK: boolean);
   begin
      inherited Create( tCompareProcedure( @CompareNames), iDuplicateOK);
   end; //constructor


// *************************************************************************
// * Add() - Add a string to the tree
// *************************************************************************

procedure tgNameValuePairTree.Add( iName: string; iValue: string);
   begin
      NVP:= tNVPNode.Create( iName, iValue);
      inherited Add( NVP);
   end; // Add()


// *************************************************************************
// * Find() - Find the string in the tree and return the Value associated
// *          with it.
// *************************************************************************

function tgNameValuePairTree.Find( iName: string): string;
   var
      Temp: tNVPNode;
   begin
      Temp:= tNVPNode.Create( iName, '');
      NVP:= tNVPNode( inherited Find( Temp));
      if( NVP = nil) then result:= '' else result:= NVP.Value;
      Temp.Destroy;
      NVP:= nil;
   end; // Find()


// *************************************************************************
// * GetFirst() - Get the first Name in the tree
// *************************************************************************

function tgNameValuePairTree.GetFirst(): string;
   begin
      NVP:= tNVPNode( inherited GetFirst());
      if( NVP = nil) then result:= '' else result:= NVP.Name;
   end; // GetFirst()


// *************************************************************************
// * GetLast() - Get the Last string in the tree
// *************************************************************************

function tgNameValuePairTree.GetLast():  string;
   begin
      NVP:= tNVPNode( inherited GetLast());
      if( NVP = nil) then result:= '' else result:= NVP.Name;
   end; // GetLast()


// *************************************************************************
// * GetNext() - Get the Next string in the tree
// *************************************************************************

function tgNameValuePairTree.GetNext():  string;
   begin
      NVP:= tNVPNode( inherited GetNext());
      if( NVP = nil) then result:= '' else result:= NVP.Name;
   end; // GetNext()


// *************************************************************************
// * GetPrevious() - Get the previous string in the tree
// *************************************************************************

function tgNameValuePairTree.GetPrevious(): string;
   begin
      NVP:= tNVPNode( inherited GetPrevious());
      if( NVP = nil) then result:= '' else result:= NVP.Name;
   end; // GetPrevious()


// *************************************************************************
// * Remove - Remove the string from the tree
// *************************************************************************

procedure tgNameValuePairTree.Remove( iName: string);
   begin
      NVP:= tNVPNode.Create( iName, '');
      inherited Remove( NVP, true);
      NVP.Destroy;
      NVP:= nil;
   end; // Remove()


// *************************************************************************
// * CompareNames() - Compare the Names of the tNodes
// *************************************************************************

function CompareNames<T>( N2: T): int8;
   begin
      if( Name > N2.Name) then begin
         result:= 1;
      end else if( Name < N2.Name) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareNames()


// *************************************************************************
// * GetValue() - Returns the value of the current Name Value pair
// *************************************************************************

function tgNameValuePairTree.GetValue(): string;
   begin
      if( NVP = nil) then result:= '' else result:= NVP.Value;
   end; // GetValue()


// *************************************************************************
// * Dump() - Display all the strings in the tree.
// *************************************************************************

procedure tgNameValuePairTree.Dump();
   var
      TempName: string;
   begin
      TempName:= GetFirst();
      while( Length( TempName) > 0) do begin
         writeln( 'Debug:  tNameValuePairTree.Dump():  ', TempName, 
                  ' = ', Value);
         TempName:= GetNext();
      end;
   end; // Dump()



// *************************************************************************

end. // lbp_name_value_pair_trees unit
