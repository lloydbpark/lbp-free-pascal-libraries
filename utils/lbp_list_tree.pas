{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park


This is a temporary location for the definition of the tgListDictionary class.
It combines the tgDoubleLinkedList and the tgDictionary classes.  It will be
moved to lbp_generic_containers when it is finished and tested.


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

unit lbp_list_tree;

interface

{$include lbp_standard_modes.inc}
//{$V-}    //Added by LP because it says so below
//{$R-}    //Range checking off
//{$S-}    //Stack checking off
//{$I-}    //I/O checking off
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   sysutils,      // Exceptions
   lbp_types,     // lbp_exception
   lbp_utils,     // padleft() - only used for debug code.
   lbp_generic_containers;
   
// ************************************************************************

// ************************************************************************
// * tgListDictionary class - Combines the features of a double linked list
// *      and a dictionary.  I plan to use this unit to hold XML elements.
// *      So sometimes I want to search for an element by tag name, iterated
// *      child elements in natural (creation) order, or be able to get the
// *      nth child.
// ************************************************************************

type
   generic tgListDictionary< K, V> = class( tObject)
      private type
      // ---------------------------------------------------------------
         tNode = class( tObject)
            protected
               Parent:      tNode;
               LeftChild:   tNode;
               RightChild:  tNode;
               PrevNode:    tNode;
               NextNode:    tNode;
               Balance:     integer;
               Key:         K;
               Value:       V;
            public
               constructor  Create( iKey: K; iValue: V);
               procedure    Clear;
               function     TreeDepth(): integer; // longest WAY down. e.g. only one tNode => 0 !
               function     First():    tNode;
               function     Last():     tNode;
               function     Next():     tNode;
               function     Previous(): tNode;
            end; // tNode class
      // ---------------------------------------------------------------
      private type
         tSortedEnumerator = class( tObject)
            private
               Tree:    tgListDictionary;
               Node:    tNode;
            public
               constructor Create( iTree: tgListDictionary);
               function    MoveNext: Boolean;
               function    GetEnumerator(): tSortedEnumerator;
               property    Current: V read Node.Value;
            end; // enumerator class
      // ---------------------------------------------------------------
      private type
         tReverseSortedEnumerator = class( tObject)
            private
               Tree:    tgListDictionary;
               Node:    tNode;
            public
               constructor Create( iTree: tgListDictionary);
               function    MoveNext: Boolean;
               function    GetEnumerator(): tReverseSortedEnumerator;
               property    Current: V read Node.Value;
            end; // enumerator class
      // ---------------------------------------------------------------
      private type
         tKeyEnumerator = class( tObject)
            private
               Tree:    tgListDictionary;
               Node:    tNode;
            public
               constructor Create( iTree: tgListDictionary);
               function    MoveNext: Boolean;
               function    GetEnumerator(): tKeyEnumerator;
               property    Current: K read Node.Key;
            end; // enumerator class
      // ---------------------------------------------------------------
      private type
         tReverseKeyEnumerator = class( tObject)
            private
               Tree:    tgListDictionary;
               Node:    tNode;
            public
               constructor Create( iTree: tgListDictionary);
               function    MoveNext: Boolean;
               function    GetEnumerator(): tReverseKeyEnumerator;
               property    Current: K read Node.Key;
            end; // enumerator class
      // ---------------------------------------------------------------


      public
         type
            tCompareFunction = function( const iKey1, iKey2: K): Integer;
            tNodeToStringFunction = function( const iKey: K): string;  
      private
         MyRoot:          tNode;
         DuplicateOK:     boolean;
         MyForward:       boolean; // Iterator direction
         CurrentNode:     tNode;
         MyCount:         integer;
         MyName:          string;
         MyCompare:       tCompareFunction;
         MyNodeToString:  tNodeToStringFunction;
      public
         Constructor Create( iCompare:        tCompareFunction;
                             iAllowDuplicates: boolean = false);
         Destructor  Destroy(); override;
         procedure   RemoveAll( DestroyElements: boolean = false); virtual;
         procedure   Add( iKey: K; iValue: V); virtual;
         procedure   RemoveCurrent(); virtual; // Remove the Current Node from the tree
         procedure   Remove( iKey: K);  virtual; // Remove the node which contains T
         function    Find( iKey: K): boolean; virtual;
         procedure   StartEnumeration(); virtual;
         function    Previous():  boolean; virtual;
         function    Next():      boolean; virtual;
         function    Key(): K; virtual;
         function    Value(): V; virtual;
   //      function    GetEnumerator(): tEnumerator;
         function    Sorted():  tSortedEnumerator;
         function    ReverseSorted(): tReverseSortedEnumerator;
         function    KeyEnum(): tKeyEnumerator;
         function    ReverseKeyEnum():  tReverseKeyEnumerator;
         procedure   Dump( N:       tNode  = nil; 
                           Prefix:  string = ''); virtual;  // Debug code
      private
         function    FindNode( iKey: K): tNode; virtual;
         function    FindItem( iKey: K): V; virtual; // used by the index property
         procedure   RemoveNode( N: tNode);  virtual; // Remove the passed node
         function    IsEmpty():  boolean; virtual;
         procedure   RemoveSubtree( StRoot: tNode; DestroyElements: boolean); virtual;
         function    FindInsertPosition( iKey: K): tNode; virtual;
         procedure   RebalanceAfterAdd( N: tNode); virtual;
         procedure   RebalanceAfterRemove( N: tNode); virtual;
         procedure   DestroyValue( Args: array of const);
      public
         property    AllowDuplicates: boolean
                                read DuplicateOK write DuplicateOK;
         property    Empty: boolean read IsEmpty write RemoveAll;
         property    Count: integer read MyCount;
         property    Root:  tNode read MyRoot;
         property    Name:  string  read MyName write MyName;
         property    Compare: tCompareFunction read MyCompare write MyCompare;
         property    NodeToString:  tNodeToStringFunction read MyNodeToString write MyNodeToString;
         property    Items[ iKey: K]: V read FindItem; default;
      end; // tgListDictionary


// ************************************************************************

implementation



// ========================================================================
// = tNode generic class
// ========================================================================
// ************************************************************************
// * Create() - constructor
// ************************************************************************
constructor tgListDictionary.tNode.Create( iKey: K; iValue: V);
   begin
      Parent:=     nil;
      LeftChild:=  nil;
      RightChild:= nil;
      PrevNode:=   nil;
      NextNode:=   nil;
      Balance:=    0;
      Key:=        iKey;
      Value:=      iValue;
   end; // Create()


// ************************************************************************
// * Clear() - Zero out the fields 
// ************************************************************************

procedure tgListDictionary.tNode.Clear();
   begin
      Parent:=     nil;
      LeftChild:=  nil;
      RightChild:= nil;
      PrevNode:=   nil;
      NextNode:=   nil;
      Balance:=    0;
      Key:= Default( K);
      Value:= Default( V);
   end; // Clear()


// ************************************************************************
// * TreeDepth() - Returns the depth of this node.
// ************************************************************************

function tgListDictionary.tNode.TreeDepth(): integer;
// longest WAY down. e.g. only one node => 0 !
   var 
      LeftDepth:  integer;
      RightDepth: integer;
   begin
   if LeftChild<>nil then begin
      LeftDepth:=LeftChild.TreeDepth+1
   end else begin
      LeftDepth:=0;
   end;

   if RightChild<>nil then begin
      RightDepth:=RightChild.TreeDepth+1
   end else begin
      RightDepth:=0;
   end;
   
   if LeftDepth>RightDepth then
      Result:=LeftDepth
   else
      Result:=RightDepth;
   end; // TreeDepth


// ************************************************************************
// * First() - Return the lowest value (leftmost) node of this node's 
// *           subtree. 
// ************************************************************************

function tgListDictionary.tNode.First(): tNode;
   begin
      result:= Self;
      while( result.LeftChild <> nil) do result:= result.LeftChild;
   end;


// ************************************************************************
// * Last() - Return the lowest value (rightmost) node of this node's 
// *          subtree. 
// ************************************************************************

function tgListDictionary.tNode.Last(): tNode;
   begin
      result:= Self;
      while( result.RightChild <> nil) do result:= result.RightChild;
   end;


// ************************************************************************
// * Next() - Return the next node in the tree
// ************************************************************************

function tgListDictionary.tNode.Next(): tNode;
   var
      PreviousNode: tNode;
   begin
      result:= Self;
      // Do we need to head toward our parent?
      if( result.RightChild = nil) then begin
         // Try from our parent
         repeat
            PreviousNode:= result;
            result:= result.Parent;
         until( (result = nil) or (result.LeftChild = PreviousNode)) 

      end else begin
         // try our RightChild child
         result:= result.RightChild;
         while( result.LeftChild <> nil) do result:= result.LeftChild;
      end;     
   end; // Next()


// ************************************************************************
// * Previous() - Return the previous node in the tree
// ************************************************************************

function tgListDictionary.tNode.Previous(): tNode;
   var
      PreviousNode: tNode;
   begin
      result:= Self;
      // Do we need to head toward our parent?
      if( result.LeftChild = nil) then begin
         // Try from our parent
         repeat
            PreviousNode:= result;
            result:= result.Parent;
         until( (result = nil) or (result.RightChild = PreviousNode)) 

      end else begin
         // try our RightChild child
         result:= result.LeftChild;
         while( result.RightChild <> nil) do result:= result.RightChild;
      end;     
   end; // Previous()



// ========================================================================
// = tEnumerator class
// ========================================================================
// ************************************************************************
// * Create() - constructor
// ************************************************************************

constructor tgListDictionary.tSortedEnumerator.Create( iTree: tgListDictionary);
   begin
      Tree:=    iTree;
      Node:=    nil;    
   end; // Create()


// ************************************************************************
// * MoveNext()
// ************************************************************************

function tgListDictionary.tSortedEnumerator.MoveNext(): boolean;
   begin
      // Starting a new iteration?
      if( (Node = nil) and (Tree.MyRoot <> nil)) then begin
         Node:= Tree.MyRoot.First;
      end else if( Node <> nil) then begin
         Node:= Node.Next;
      end;

      result:= (Node <> nil)
   end; // MoveNext()


// ************************************************************************
// * GetEnumerator()
// ************************************************************************

function tgListDictionary.tSortedEnumerator.GetEnumerator: tSortedEnumerator;
   begin
      result:= self;  
   end; // GetEnumerator()



// ========================================================================
// = tReverseSortedEnumerator class
// ========================================================================
// ************************************************************************
// * Create() - constructor
// ************************************************************************

constructor tgListDictionary.tReverseSortedEnumerator.Create( iTree: tgListDictionary);
   begin
      Tree:=    iTree;
      Node:=    nil;    
   end; // Create()


// ************************************************************************
// * MoveNext()
// ************************************************************************

function tgListDictionary.tReverseSortedEnumerator.MoveNext(): boolean;
   begin
      // Starting a new iteration?
      if( (Node = nil) and (Tree.MyRoot <> nil)) then begin
         Node:= Tree.MyRoot.Last;
      end else if( Node <> nil) then begin
         Node:= Node.Previous;
      end;

      result:= (Node <> nil)
   end; // MoveNext()


// ************************************************************************
// * GetEnumerator()
// ************************************************************************

function tgListDictionary.tReverseSortedEnumerator.GetEnumerator: tReverseSortedEnumerator;
   begin
      result:= self;  
   end; // GetEnumerator()



// ========================================================================
// = tKeyEnumerator class
// ========================================================================
// ************************************************************************
// * Create() - constructor
// ************************************************************************

constructor tgListDictionary.tKeyEnumerator.Create( iTree: tgListDictionary);
   begin
      Tree:=    iTree;
      Node:=    nil;    
   end; // Create()


// ************************************************************************
// * MoveNext()
// ************************************************************************

function tgListDictionary.tKeyEnumerator.MoveNext(): boolean;
   begin
      // Starting a new iteration?
      if( (Node = nil) and (Tree.MyRoot <> nil)) then begin
         Node:= Tree.MyRoot.First;
      end else if( Node <> nil) then begin
         Node:= Node.Next;
      end;

      result:= (Node <> nil)
   end; // MoveNext()


// ************************************************************************
// * GetEnumerator()
// ************************************************************************

function tgListDictionary.tKeyEnumerator.GetEnumerator: tKeyEnumerator;
   begin
      result:= self;  
   end; // GetEnumerator()



// ========================================================================
// = tReverseKeyEnumerator class
// ========================================================================
// ************************************************************************
// * Create() - constructor
// ************************************************************************

constructor tgListDictionary.tReverseKeyEnumerator.Create( iTree: tgListDictionary);
   begin
      Tree:=    iTree;
      Node:=    nil;    
   end; // Create()


// ************************************************************************
// * MoveNext()
// ************************************************************************

function tgListDictionary.tReverseKeyEnumerator.MoveNext(): boolean;
   begin
      // Starting a new iteration?
      if( (Node = nil) and (Tree.MyRoot <> nil)) then begin
         Node:= Tree.MyRoot.Last;
      end else if( Node <> nil) then begin
         Node:= Node.Previous;
      end;

      result:= (Node <> nil)
   end; // MoveNext()


// ************************************************************************
// * GetEnumerator()
// ************************************************************************

function tgListDictionary.tReverseKeyEnumerator.GetEnumerator: tReverseKeyEnumerator;
   begin
      result:= self;  
   end; // GetEnumerator()


// ========================================================================
// = tgListDictionary generic class
// ========================================================================
// ************************************************************************
// * Create() - Constructors
// ************************************************************************

constructor tgListDictionary.Create( iCompare:     tCompareFunction;
                                     iAllowDuplicates: boolean);
   begin
      inherited Create;
      MyRoot:= nil;
      MyCompare:= iCompare;
      MyNodeToString:= nil;
      DuplicateOK:= iAllowDuplicates;
      MyForward:= true;
      CurrentNode:= nil;
      MyName:= '';
      MyCount:= 0;
   end; // Create()


// ************************************************************************
// * Destroy() - Destructor
// ************************************************************************

Destructor tgListDictionary.Destroy();
   begin
      RemoveAll;
      inherited Destroy();
   end;


// ************************************************************************
// * RemoveAll() - Remove all the elements from the tree and optionally 
// *               Destroy() the elements.
// ************************************************************************

procedure tgListDictionary.RemoveAll( DestroyElements: boolean);
   begin
      if( MyRoot <> nil) then RemoveSubtree( MyRoot, DestroyElements);
      MyRoot:= nil;
   end; // RemoveAll()


// ************************************************************************
// * FindInsertPosition() - Find the node to which this new iKey will be 
// *                        a child.
// ************************************************************************

function tgListDictionary.FindInsertPosition( iKey: K): tNode;
   var 
      Comp: integer;
   begin
      Result:= MyRoot;
      while( Result <> nil) do begin
         Comp:= MyCompare( iKey, Result.Key);
         if Comp < 0 then begin
            if Result.LeftChild <> nil then Result:=Result.LeftChild
            else exit;
         end else begin
            if Result.RightChild <> nil then Result:=Result.RightChild
            else exit;
         end;
      end; // while
   end; //FindInsertPosition()


// ************************************************************************
// * Add() - Add an element to the tree
// ************************************************************************

procedure tgListDictionary.Add( iKey: K; iValue: V);
   var 
      InsertPos:   tNode;
      Comp:        integer;
      NewNode:     tNode;
   begin
      NewNode:= tNode.create( iKey, iValue);
      inc( MyCount);
      if MyRoot <> nil then begin
         InsertPos:= FindInsertPosition( iKey);
         Comp:= MyCompare( iKey, InsertPos.Key);
         NewNode.Parent:= InsertPos;
         if( Comp < 0) then begin
            // insert to the left
            InsertPos.LeftChild:= NewNode;
         end else begin
            // Check for unallowed duplicate
            if( (Comp = 0) and not DuplicateOK) then begin
              NewNode.Destroy(); // Clean up
              raise lbpContainerException.Create( 'Duplicate key values are not allowed in this AVL Tree!');
            end;
            // insert to the right
            InsertPos.RightChild:= NewNode;
         end;
         RebalanceAfterAdd( NewNode);
      end else begin
         MyRoot:=NewNode;
      end;
   end; // tgListDictionary.Add()


// ************************************************************************
// * Remove() - Remove the current node from the tree
// ************************************************************************

procedure tgListDictionary.RemoveCurrent();
   begin
      if( CurrentNode = nil) then begin
         raise lbpContainerException.Create( 'Attempting to delete the current node from the tree when it is empty!');
      end;
      RemoveNode( CurrentNode);
      CurrentNode:=nil;
   end; // Remove()


// ************************************************************************
// * Remove() - Find a node which contains iKey and remove it.
// ************************************************************************

procedure tgListDictionary.Remove( iKey: K);
   var
      N: tNode;
   begin
      CurrentNode:= nil;
      N:= FindNode( iKey);
      if( N = nil) then begin
         raise lbpContainerException.Create( 'The passed key was not found in the tree.');
      end;
      RemoveNode( N);
   end; // Remove()


// ************************************************************************
// * Find() - returns true if the passed iKey is found in the tree
// *          Call Value() to get the found value.
// ************************************************************************

function tgListDictionary.Find( iKey: K): boolean;
   begin
      CurrentNode:= FindNode( iKey);
      result:= (CurrentNode <> nil);
   end; // Find()


// ************************************************************************
// * StartEnumeration() - Prepare for a new enmeration.
// ************************************************************************

procedure tgListDictionary.StartEnumeration();
   begin
      CurrentNode:= nil;
   end; /// StartEnumeration()


// ************************************************************************
// * Previous() - Move to the previous node in the tree and return true if
// *              successful.
// ************************************************************************

function tgListDictionary.Previous(): boolean;
   begin
      // Starting a new iteration?
      if( (CurrentNode = nil) and (MyRoot <> nil)) then begin
         CurrentNode:= MyRoot.Last;
      end else if( CurrentNode <> nil) then begin
         CurrentNode:= CurrentNode.Previous;
      end;

      result:= (CurrentNode <> nil)
   end; /// Previous()


// ************************************************************************
// * Next()) - Move to the Next node in the tree and return true if successful.
// ************************************************************************

function tgListDictionary.Next(): boolean;
   begin
      // Starting a new iteration?
      if( (CurrentNode = nil) and (MyRoot <> nil)) then begin
         CurrentNode:= MyRoot.First;
      end else if( CurrentNode <> nil) then begin
         CurrentNode:= CurrentNode.Next;
      end;

      result:= (CurrentNode <> nil)
   end; /// Next()


// ************************************************************************
// * Key() - Return the Key of the current node in the tree.True
// ************************************************************************

function tgListDictionary.Key(): K;
   begin
      // Starting a new iteration?
      if( CurrentNode = nil) then begin
         raise lbpContainerException.Create( 'Attempt to access the current tree node''s key outside of an enumeration.');
      end;
      result:= CurrentNode.Key;
   end; // Key()


// ************************************************************************
// * Value() - Return the value of the current node in the tree.True
// ************************************************************************

function tgListDictionary.Value(): V;
   begin
      // Starting a new iteration?
      if( CurrentNode = nil) then begin
         raise lbpContainerException.Create( 'Attempt to access the current tree node''s value outside of an enumeration.');
      end;
      result:= CurrentNode.Value;
   end; /// Value()


// ************************************************************************
// * Sorted() - Get the sorted order value enumberator
// ************************************************************************

function tgListDictionary.Sorted(): tSortedEnumerator;
   begin
      result:= tSortedEnumerator.Create( Self);
   end; // Sorted()


// ************************************************************************
// * ReverseSorted() - Gets the reverse sorted order value enumerator
// ************************************************************************

function tgListDictionary.ReverseSorted(): tReverseSortedEnumerator;
   begin
      result:= tReverseSortedEnumerator.Create( Self);
   end; // ReverseSorted()


// ************************************************************************
// * KeyEnum() - Gets the Key enumerator
// ************************************************************************

function tgListDictionary.KeyEnum(): tKeyEnumerator;
   begin
      result:= tKeyEnumerator.Create( Self);
   end; // KeyEnum()


// ************************************************************************
// * ReverseKeyEnum() - Gets the reverse order enumerator
// ************************************************************************

function tgListDictionary.ReverseKeyEnum(): tReverseKeyEnumerator;
   begin
      result:= tReverseKeyEnumerator.Create( Self);
   end; // Reverse()


// ************************************************************************
// * Dump() - prints the tree for troubleshooting
// ************************************************************************


procedure tgListDictionary.Dump( N:       tNode = nil;
                          Prefix:  string       = ''); 
   var
      Temp: string;
   begin
      if( MyNodeToString = nil) then 
         writeln( 'The tree can not be dumped because ''NodeToString'' has not be set!');

      // Take care of the start condition and the empty cases
      if( N = nil) then begin
         if( MyRoot = nil) then exit;
         N:= MyRoot;
      end;

      // Convert the value to something printable
      Temp:= MyNodeToString( N.Key);
      if( Length( Temp) > 4) then SetLength( Temp, 4);
      PadLeft( Temp, 4);

      // Print N's value
      write( Temp);

      // Process the Left Branch
      if( N.LeftChild = nil) then begin
         writeln;
      end else begin
         write( ' -> ');
         Dump( N.LeftChild, Prefix + '   |    ');
      end;

      // Process the Right Branch
      if( N.RightChild <> nil) then begin
         write( Prefix, '    \-> ');
         Dump( N.RightChild, Prefix + '        ');
      end;
   end; // Dump


// ************************************************************************
// * FindNode() - Returns a node which contains iKey.  Return nil if no
// *              node is found.  Used internally.
// ************************************************************************

function tgListDictionary.FindNode( iKey: K): tNode;
   var 
      Comp: integer;
   begin
      Result:=MyRoot;
      while( Result <> nil) do begin
        Comp:= MyCompare( iKey, Result.Key);
        if Comp=0 then exit;
        if Comp<0 then begin
            Result:=Result.LeftChild;
         end else begin
            Result:=Result.RightChild;
         end;
      end; // while
   end; // FindNode()


// ************************************************************************
// * FindItem() - Returns a node which contains iKey.  Return nil if no
// *              node is found.  Used internally.
// ************************************************************************

function tgListDictionary.FindItem( iKey: K): V;
   var
      N: tNode;
   begin
      N:= FindNode( iKey);
      if( N = nil) then raise lbpContainerException.create( 'Index key does not exist in this Dictionary!');
      result:= N.Value;
   end; // FindItem()


// ************************************************************************
// * RemoveNode() - Remove the passed node from the tree
// ************************************************************************

procedure tgListDictionary.RemoveNode( N: tNode);
   var 
      OldParent:     tNode;
      OldLeft:       tNode;
      OldRight:      tNode;
      Successor:     tNode;
      OldSuccParent: tNode;
      OldSuccLeft:   tNode;
      OldSuccRight:  tNode;
      OldBalance:    integer;
   begin
   OldParent:=N.Parent;
   OldBalance:=N.Balance;
   N.Parent:=nil;
   N.Balance:=0;
   if( (N.LeftChild = nil) and (N.RightChild = nil)) then begin
      // Node is Leaf (no children)
      if( OldParent <> nil) then begin
         // Node has parent
         if( OldParent.LeftChild = N) then begin
            // Node is left Son of OldParent
            OldParent.LeftChild:= nil;
            Inc( OldParent.Balance);
         end else begin
            // Node is right Son of OldParent
            OldParent.RightChild:= nil;
            Dec( OldParent.Balance);
         end;
         RebalanceAfterRemove( OldParent);
      end else begin
         // Node is the only node of tree
         MyRoot:= nil;
      end;
      dec( MyCount);
      N.Destroy;
      exit;
   end;
   if( N.RightChild = nil) then begin
      // Left is only son
      // and because DelNode is AVL, Right has no childrens
      // replace DelNode with Left
      OldLeft:= N.LeftChild;
      N.LeftChild:= nil;
      OldLeft.Parent:= OldParent;
      if( OldParent <> nil) then begin
         if( OldParent.LeftChild = N) then begin
            OldParent.LeftChild:= OldLeft;
            Inc( OldParent.Balance);
         end else begin
            OldParent.RightChild:= OldLeft;
            Dec( OldParent.Balance);
         end;
         RebalanceAfterRemove( OldParent);
      end else begin
         MyRoot:= OldLeft;
      end;
      dec( MyCount);
      N.Destroy;
      exit;
   end;
   if( N.LeftChild = nil) then begin
      // Right is only son
      // and because DelNode is AVL, Left has no childrens
      // replace DelNode with Right
      OldRight:= N.RightChild;
      N.RightChild:= nil;
      OldRight.Parent:= OldParent;
      if( OldParent <> nil) then begin
         if( OldParent.LeftChild = N) then begin
            OldParent.LeftChild:= OldRight;
            Inc( OldParent.Balance);
         end else begin
            OldParent.RightChild:= OldRight;
            Dec( OldParent.Balance);
         end;
         RebalanceAfterRemove( OldParent);
      end else begin
         MyRoot:=OldRight;
      end;
      dec( MyCount);
      N.Destroy;
      exit;
   end;
   // DelNode has both: Left and Right
   // Replace N with symmetric Successor
   Successor:= N.Next();
   OldLeft:= N.LeftChild;
   OldRight:= N.RightChild;
   OldSuccParent:= Successor.Parent;
   OldSuccLeft:= Successor.LeftChild;
   OldSuccRight:= Successor.RightChild;
   N.Balance:= Successor.Balance;
   Successor.Balance:= OldBalance;
   if( OldSuccParent <> N) then begin
      // at least one node between N and Successor
      N.Parent:= Successor.Parent;
      if( OldSuccParent.LeftChild = Successor) then
         OldSuccParent.LeftChild:= N
      else
         OldSuccParent.RightChild:= N;
      Successor.RightChild:= OldRight;
      OldRight.Parent:= Successor;
   end else begin
      // Successor is right son of N
      N.Parent:= Successor;
      Successor.RightChild:= N;
   end;
   Successor.LeftChild:= OldLeft;
   if( OldLeft <> nil) then
      OldLeft.Parent:= Successor;
   Successor.Parent:= OldParent;
   N.LeftChild:= OldSuccLeft;
   if( N.LeftChild <> nil) then
      N.LeftChild.Parent:= N;
   N.RightChild:= OldSuccRight;
   if( N.RightChild <> nil) then
      N.RightChild.Parent:= N;
   if( OldParent <> nil) then begin
      if( OldParent.LeftChild = N) then
         OldParent.LeftChild:= Successor
      else
         OldParent.RightChild:= Successor;
   end else
      MyRoot:= Successor;
   // delete Node as usual
   RemoveNode( N);
end; // RemoveNode()


// ************************************************************************
// * IsEmpty() - Returns true if the tree is empty.
// ************************************************************************

function tgListDictionary.IsEmpty(): V;
   begin
      result:= (MyCount = 0);
   end; // First()


// ************************************************************************
// * RemoveSubtree() - Helper for RemoveAll
// ************************************************************************

procedure tgListDictionary.RemoveSubtree( StRoot: tNode; DestroyElements: boolean);
   begin
      if( StRoot.LeftChild <> nil) then begin
         RemoveSubtree( StRoot.LeftChild, DestroyElements);
      end;
      if( StRoot.RightChild <> nil) then begin 
         RemoveSubtree( StRoot.RightChild, DestroyElements);
      end;
      if( DestroyElements) then DestroyValue( [StRoot.Value]);
      StRoot.Destroy;
   end; // RemoveSubtree()


// ************************************************************************
// * RebalanceAfterAdd() - Rebalance the tree after an Add()
// ************************************************************************

procedure tgListDictionary.RebalanceAfterAdd( N: tNode);
   var 
      OldParent:       tNode;
      OldParentParent: tNode;
      OldRight:        tNode;
      OldRightLeft:    tNode;
      OldRightRight:   tNode;
      OldLeft:         tNode;
      OldLeftLeft:     tNode;
      OldLeftRight:    tNode;
   begin
      OldParent:= N.Parent;
      if( OldParent = nil) then exit;
      if( OldParent.LeftChild = N) then begin
         // Node is left son
         dec( OldParent.Balance);
         if( OldParent.Balance = 0) then exit;
         if( OldParent.Balance = -1) then begin
            RebalanceAfterAdd( OldParent);
            exit;
         end;
         // OldParent.Balance=-2
         if( N.Balance = -1) then begin
            // rotate
            OldRight:= N.RightChild;
            OldParentParent:= OldParent.Parent;
            if( OldParentParent <> nil) then begin
               // OldParent has GrandParent. GrandParent gets new child
               if( OldParentParent.LeftChild = OldParent) then
                  OldParentParent.LeftChild:= N
               else
                  OldParentParent.RightChild:= N;
            end else begin
               // OldParent was root node. New root node
               MyRoot:= N;
            end;
            N.Parent:= OldParentParent;
            N.RightChild:= OldParent;
            OldParent.Parent:= N;
            OldParent.LeftChild:= OldRight;
            if( OldRight <> nil) then
               OldRight.Parent:=OldParent;
            N.Balance:= 0;
            OldParent.Balance:= 0;
         end else begin
            // Node.Balance = +1
            // double rotate
            OldParentParent:= OldParent.Parent;
            OldRight:= N.RightChild;
            OldRightLeft:= OldRight.LeftChild;
            OldRightRight:= OldRight.RightChild;
            if( OldParentParent <> nil) then begin
               // OldParent has GrandParent. GrandParent gets new child
               if( OldParentParent.LeftChild = OldParent) then
                  OldParentParent.LeftChild:= OldRight
               else
                  OldParentParent.RightChild:= OldRight;
            end else begin
               // OldParent was root node. new root node
               MyRoot:= OldRight;
            end;
            OldRight.Parent:= OldParentParent;
            OldRight.LeftChild:= N;
            OldRight.RightChild:= OldParent;
            N.Parent:= OldRight;
            N.RightChild:= OldRightLeft;
            OldParent.Parent:= OldRight;
            OldParent.LeftChild:= OldRightRight;
            if( OldRightLeft <> nil) then
               OldRightLeft.Parent:= N;
            if( OldRightRight <> nil) then
               OldRightRight.Parent:= OldParent;
            if( OldRight.Balance <= 0) then
               N.Balance:= 0
            else
               N.Balance:= -1;
            if( OldRight.Balance = -1) then
               OldParent.Balance:= 1
            else
               OldParent.Balance:= 0;
            OldRight.Balance:= 0;
         end;
      end else begin
         // Node is right son
         Inc(OldParent.Balance);
         if( OldParent.Balance = 0) then exit;
         if( OldParent.Balance = +1) then begin
            RebalanceAfterAdd( OldParent);
            exit;
         end;
         // OldParent.Balance = +2
         if( N.Balance = +1) then begin
            // rotate
            OldLeft:= N.LeftChild;
            OldParentParent:= OldParent.Parent;
            if( OldParentParent <> nil) then begin
               // Parent has GrandParent . GrandParent gets new child
               if( OldParentParent.LeftChild = OldParent) then
                  OldParentParent.LeftChild:= N
               else
                  OldParentParent.RightChild:= N;
            end else begin
               // OldParent was root node . new root node
               MyRoot:= N;
            end;
            N.Parent:= OldParentParent;
            N.LeftChild:= OldParent;
            OldParent.Parent:= N;
            OldParent.RightChild:= OldLeft;
            if( OldLeft <> nil) then
               OldLeft.Parent:= OldParent;
            N.Balance:= 0;
            OldParent.Balance:= 0;
         end else begin
            // Node.Balance = -1
            // double rotate
            OldLeft:= N.LeftChild;
            OldParentParent:= OldParent.Parent;
            OldLeftLeft:= OldLeft.LeftChild;
            OldLeftRight:= OldLeft.RightChild;
            if( OldParentParent <> nil) then begin
               // OldParent has GrandParent . GrandParent gets new child
               if( OldParentParent.LeftChild = OldParent) then
                  OldParentParent.LeftChild:= OldLeft
               else
                  OldParentParent.RightChild:= OldLeft;
            end else begin
               // OldParent was root node . new root node
               MyRoot:= OldLeft;
            end;
            OldLeft.Parent:= OldParentParent;
            OldLeft.LeftChild:= OldParent;
            OldLeft.RightChild:= N;
            N.Parent:= OldLeft;
            N.LeftChild:= OldLeftRight;
            OldParent.Parent:= OldLeft;
            OldParent.RightChild:= OldLeftLeft;
            if( OldLeftLeft <> nil) then
               OldLeftLeft.Parent:= OldParent;
            if( OldLeftRight <> nil) then
               OldLeftRight.Parent:= N;
            if( OldLeft.Balance >= 0) then
               N.Balance:= 0
            else
               N.Balance:= +1;
            if(OldLeft.Balance = +1) then
               OldParent.Balance:= -1
            else
               OldParent.Balance:= 0;
            OldLeft.Balance:= 0;
         end;
      end;
   end; // RebalanceAfterAdd()


// ************************************************************************
// * RebalanceAfterRemove() - Rebalance the tree after a Remove()
// ************************************************************************

procedure tgListDictionary.RebalanceAfterRemove( N: tNode);
   var 
      OldParent:         tNode;
      OldRight:          tNode;
      OldRightLeft:      tNode;
      OldLeft:           tNode;
      OldLeftRight:      tNode;
      OldRightLeftLeft:  tNode;
      OldRightLeftRight: tNode;
      OldLeftRightLeft:  tNode;
      OldLeftRightRight: tNode;
   begin
      if( N = nil) then exit;
      if( (N.Balance = +1) or (N.Balance = -1)) then exit;
      OldParent:= N.Parent;
      if( N.Balance = 0) then begin
         // Treeheight has decreased by one
         if(OldParent <> nil) then begin
            if( OldParent.LeftChild = N) then
               Inc( OldParent.Balance)
            else
               Dec( OldParent.Balance);
            RebalanceAfterRemove( OldParent);
         end;
         exit;
      end;
      if( N.Balance = +2) then begin
         // Node is overweighted to the right
         OldRight:= N.RightChild;
         if( OldRight.Balance >= 0) then begin
            // OldRight.Balance=={0 or -1}
            // rotate left
            OldRightLeft := OldRight.LeftChild;
            if( OldParent <> nil) then begin
               if( OldParent.LeftChild = N) then
                  OldParent.LeftChild:= OldRight
               else
                  OldParent.RightChild:= OldRight;
            end else
               MyRoot:= OldRight;
            N.Parent:= OldRight;
            N.RightChild:= OldRightLeft;
            OldRight.Parent:= OldParent;
            OldRight.LeftChild:= N;
            if( OldRightLeft <> nil) then
               OldRightLeft.Parent:= N;
            N.Balance:= (1-OldRight.Balance);
            Dec( OldRight.Balance);
            RebalanceAfterRemove( OldRight);
         end else begin
            // OldRight.Balance=-1
            // double rotate right left
            OldRightLeft:= OldRight.LeftChild;
            OldRightLeftLeft:= OldRightLeft.LeftChild;
            OldRightLeftRight:= OldRightLeft.RightChild;
            if( OldParent <> nil) then begin
               if( OldParent.LeftChild = N) then
                  OldParent.LeftChild:= OldRightLeft
                else
                  OldParent.RightChild:= OldRightLeft;
            end else
               MyRoot:= OldRightLeft;
            N.Parent:= OldRightLeft;
            N.RightChild:= OldRightLeftLeft;
            OldRight.Parent:= OldRightLeft;
            OldRight.LeftChild:= OldRightLeftRight;
            OldRightLeft.Parent:= OldParent;
            OldRightLeft.LeftChild:= N;
            OldRightLeft.RightChild:= OldRight;
            if( OldRightLeftLeft <> nil) then
               OldRightLeftLeft.Parent:= N;
            if( OldRightLeftRight <> nil) then
               OldRightLeftRight.Parent:= OldRight;
            if( OldRightLeft.Balance <= 0) then
               N.Balance:= 0
            else
               N.Balance:= -1;
            if( OldRightLeft.Balance >= 0) then
               OldRight.Balance:= 0
            else
               OldRight.Balance:=+ 1;
            OldRightLeft.Balance:= 0;
            RebalanceAfterRemove( OldRightLeft);
         end;
      end else begin
         // Node.Balance=-2
         // Node is overweighted to the left
         OldLeft:= N.LeftChild;
         if( OldLeft.Balance <= 0) then begin
            // rotate right
            OldLeftRight:= OldLeft.RightChild;
            if (OldParent <> nil) then begin
               if( OldParent.LeftChild = N) then
                  OldParent.LeftChild:= OldLeft
               else
                  OldParent.RightChild:= OldLeft;
            end else
               MyRoot:= OldLeft;
            N.Parent:= OldLeft;
            N.LeftChild:= OldLeftRight;
            OldLeft.Parent:= OldParent;
            OldLeft.RightChild:= N;
            if( OldLeftRight <> nil) then
               OldLeftRight.Parent:= N;
            N.Balance:=( -1 - OldLeft.Balance);
            Inc( OldLeft.Balance);
            RebalanceAfterRemove( OldLeft);
         end else begin
            // OldLeft.Balance = 1
            // double rotate left right
            OldLeftRight:= OldLeft.RightChild;
            OldLeftRightLeft:= OldLeftRight.LeftChild;
            OldLeftRightRight:= OldLeftRight.RightChild;
            if( OldParent <> nil) then begin
               if( OldParent.LeftChild = N) then
                  OldParent.LeftChild:= OldLeftRight
               else
                  OldParent.RightChild:= OldLeftRight;
            end else
               MyRoot:= OldLeftRight;
            N.Parent:= OldLeftRight;
            N.LeftChild:= OldLeftRightRight;
            OldLeft.Parent:= OldLeftRight;
            OldLeft.RightChild:= OldLeftRightLeft;
            OldLeftRight.Parent:= OldParent;
            OldLeftRight.LeftChild:= OldLeft;
            OldLeftRight.RightChild:= N;
            if( OldLeftRightLeft <> nil) then
               OldLeftRightLeft.Parent:= OldLeft;
            if( OldLeftRightRight <> nil) then
               OldLeftRightRight.Parent:= N;
            if( OldLeftRight.Balance >= 0) then
               N.Balance:= 0
            else
               N.Balance:= +1;
            if( OldLeftRight.Balance <=0) then
               OldLeft.Balance:= 0
            else
               OldLeft.Balance:= -1;
            OldLeftRight.Balance:= 0;
            RebalanceAfterRemove( OldLeftRight);
         end;
      end;
   end; // RebalanceAfterRemove()


// ************************************************************************
// * DestroyValue() - If the passed value is a class, call its destructor
// *                  This should only be used internally and will always
// *                  be passed a single value.
// ************************************************************************

procedure tgListDictionary.DestroyValue( Args: array of const);
   begin
      if( Args[ 0].vtype = vtClass) then tObject( Args[ 0].vClass).Destroy();
   end; // DestroyValue;



// ************************************************************************

end. // lbp_list_tree unit
