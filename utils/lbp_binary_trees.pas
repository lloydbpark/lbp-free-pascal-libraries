{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Classes to implement binary trees.

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

unit lbp_binary_trees;
// Creates a balanced binary tree of pointers.  Makes use of a comparison

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

interface

uses
   sysutils,      // Format() - string format function
   lbp_lists,
   lbp_types;      // int32, lbp_exception


// *************************************************************************

type
   lbpBinaryTreeException = class( lbp_exception);

// -------------------------------------------------------------------------

   tTreeNode = class
      public
         Item:       tObject;
         Parent:     tTreeNode;
         Left:       tTreeNode;
         Right:      tTreeNode;
         Balance:    int8;
         constructor Create( iItem: tObject);
         destructor  Destroy(); override;
      end; // tTreeNode


// -------------------------------------------------------------------------

   tBalancedBinaryTree = class
      private
         Root:            tTreeNode;
         DuplicateOK:     boolean;
         CurrentNode:     tTreeNode;
         MyCount:         integer;
      protected
         Compare:         tCompareProcedure;
      public
         Name:            string;
         constructor      Create(     iCompare:     tCompareProcedure);
         constructor      Create(     iCompare:     tCompareProcedure;
                                      iDuplicateOK: boolean);
         constructor      Create(     iCompare:     tCompareProcedure;
                                      iDuplicateOK: boolean;
                                      OtherTree: tBalancedBinaryTree);
         destructor       Destroy();  override;
         procedure        Copy(       OtherTree: tBalancedBinaryTree); virtual;
         procedure        Add(        Item: tObject); virtual;
         function         Find(       Item: tObject): tObject; virtual;
         function         GetFirst(): tObject; virtual;
         function         GetLast():  tObject; virtual;
         function         GetNext():  tObject; virtual;
         function         GetPrevious(): tObject; virtual;
         procedure        RemoveAll(  DestroyElements: boolean = false); virtual;
         procedure        ForEach(    P: tObjProcedure); virtual;
         procedure        Remove(     DestroyElement: boolean = false); virtual;
         procedure        Remove(     SearchItem:     tObject;
                                      DestroyElement: boolean = false); virtual;
         function         IsEmpty():  boolean; virtual;
         function         GetRoot():  tTreeNode; virtual;
      public
         property         AllowDuplicates: boolean
                                read DuplicateOK write DuplicateOK;
         property         Empty: boolean read IsEmpty write RemoveAll;
         property         Count: integer read MyCount;
      end; // tBalancedBinaryTree


// *************************************************************************

function AVLInsert(        Item:          tObject;
                       var Root:          tTreeNode;
                           Compare: tCompareProcedure;
                       var HasGrown:      boolean;
                           DuplicatesOK:  boolean): tTreeNode;
function AVLFind(           Item:    tObject;
                            Root:    tTreeNode;
                            Compare: tCompareProcedure): tTreeNode;
procedure AVLDelete(    var Root:           tTreeNode;
                        var HasShrunk:      boolean;
                            DestroyElement: boolean);
 procedure AVLDelete(       SearchItem:     tObject;
                        var Root:           tTreeNode;
                            Compare: tCompareProcedure;
                        var HasShrunk:      boolean;
                            DestroyElement: boolean);
procedure AVLDeleteAll( var Root:            tTreeNode;
                            DestroyElements: boolean);
procedure AVLForEach(   var Root: tTreeNode; P: tObjProcedure);


// *************************************************************************

implementation


// =========================================================================
// = Global procedures
// =========================================================================
// *************************************************************************
// * AVLInsert() - Insertion routine for AVL tree
// *               (recursive)  - First call should have HasGrown = false
// *************************************************************************

function AVLInsert(     Item:          tObject;
                    var Root:          tTreeNode;
                        Compare:       tCompareProcedure;
                    var HasGrown:      boolean;
                        DuplicatesOK:  boolean): tTreeNode;
   var
      N1:            tTreeNode;
      N2:            tTreeNode;
      CompareResult: int8;
   begin
      // check for an empty tree
      if( Root = nil) then begin
         Root:= tTreeNode.Create( Item);
         HasGrown:= true;
         result:= Root;
      end else begin

         // Non-empty tree
         CompareResult:= Compare( Root.Item, Item);

         // Test for illegal duplicates!
         if( (not DuplicatesOK) and ( CompareResult = 0)) then begin
            raise lbpBinaryTreeException.Create(
            'lbpBinaryTree.AVLInsert():  Attempt to add a duplicate element!');
         end;

         // Insert to the left?
         if( CompareResult >= 0) then begin
            result:= AVLInsert( Item, Root.Left, Compare,
                                HasGrown, DuplicatesOK);
            Root.Left.Parent:= Root;
            if( HasGrown) then begin
               // The left branch has grown.
               case Root.Balance of
                  1:  begin
                         Root.Balance:= 0;
                         HasGrown:=     false;
                      end;
                  0:  begin
                         Root.Balance:= -1;
                      end;
                  -1: begin
                         // Rebalance
                         N1:= Root.Left;
                         if( N1.Balance = -1) then begin
                            // Single LL rotation
                            Root.Left:=    N1.Right;
                            if( N1.Right <> nil) then begin
                               N1.Right.Parent:= Root;
                            end;
                            N1.Right:=     Root;     Root.Parent:=     N1;
                            Root.Balance:= 0;
                            Root:=         N1;
                         end else begin
                            // Double LR Rotation
                            N2:= N1.Right;
                            N1.Right:=     N2.Left;
                            if( N2.Left <> nil) then begin
                               N2.Left.Parent:=  N1;
                            end;
                            N2.Left:=      N1;       N1.Parent:=       N2;
                            Root.Left:=    N2.Right;
                            if( N2.Right <> nil) then begin
                               N2.Right.Parent:= Root;
                            end;
                            N2.Right:=     root;     Root.Parent:=     N2;
                            if( N2.Balance = -1) then begin
                               Root.Balance:= 1;
                            end else begin
                               Root.Balance:= 0;
                            end;
                            if( N2.Balance = 1) then begin
                               N1.Balance:= -1;
                            end else begin
                               N1.Balance:= 0;
                            end;
                            Root:= N2;
                         end;
                         Root.Balance:= 0;
                         HasGrown:= False;
                      end;
               end; // case
            end;  // if HasGrown
         end else begin

            // Insert to the right
            result:= AVLInsert( Item, Root.Right, Compare,
                                HasGrown, DuplicatesOK);
            Root.Right.Parent:= Root;
            if( HasGrown) then begin
               // The right branch has grown.
               case Root.Balance of
                  -1:  begin
                         Root.Balance:= 0;
                         HasGrown:=     false;
                      end;
                  0:  begin
                         Root.Balance:= 1;
                      end;
                  1:  begin
                         // Rebalance
                         N1:= Root.Right;
                         if( N1.Balance = 1) then begin
                            // Single RR rotation
                            Root.Right:=   N1.Left;
                            if( N1.Left <> nil) then begin
                               N1.Left.Parent:=   Root;
                            end;
                            N1.Left:=      Root;    Root.Parent:=      N1;
                            Root.Balance:= 0;
                            Root:=         N1;
                         end else begin
                            // Double RL Rotation
                            N2:= N1.Left;
                            N1.Left:=      N2.Right;
                            if( N2.Right <> nil) then begin
                               N2.Right.Parent:= N1;
                            end;
                            N2.Right:=     N1;       N1.Parent:=       N2;
                            Root.Right:=   N2.Left;
                            if( N2.Left <> nil) then begin
                               N2.Left.Parent:= Root;
                            end;
                            N2.Left:=      root;     Root.Parent:=     N2;
                            if( N2.Balance = 1) then begin
                               Root.Balance:= -1;
                            end else begin
                               Root.Balance:= 0;
                            end;
                            if( N2.Balance = -1) then begin
                               N1.Balance:= 1;
                            end else begin
                               N1.Balance:= 0;
                            end;
                            Root:= N2;
                         end;
                         Root.Balance:= 0;
                         HasGrown:= false;
                      end;
               end; // case
            end; // if HasGrown
         end; // else Insert to the right
         Root.Parent:= nil;
      end; // else non-empty tree
   end; // AVLInsert()


// *************************************************************************
// * AVLFind() - Find an Item in the list where Compare = 0 and return it.
// *             Return nill if no match is found.
// *************************************************************************

function AVLFind( Item:    tObject;
                  Root:    tTreeNode;
                  Compare: tCompareProcedure): tTreeNode;
   var
      CompareResult:  int8;
   begin
      if( Root = nil) then begin
         result:= nil;
         exit;
      end else begin

         CompareResult:= Compare( Root.Item, Item);

         if( CompareResult > 0) then begin
            exit( AVLFind( Item, Root.Left, Compare));
         end else if( CompareResult < 0) then begin
            exit( AVLFind( Item, Root.Right, Compare));
         end else begin
            // We found the node
            exit( Root);
         end; // else we found the node
      end; // else
   end; // AVLFind()


// *************************************************************************
// * AVLBalanceRight() - Right branch has shrunk
// *************************************************************************

procedure AVLBalanceRight( var Root:      tTreeNode;
                           var HasShrunk: boolean);
   var
      N1:  tTreeNode;
      N2:  tTreeNode;
      B1:  int8;
      B2:  int8;
   begin
      case Root.Balance of
          1:  begin
                 Root.Balance:= 0;
              end;
          0:  begin
                 Root.Balance:= -1;
                 HasShrunk:= false;
              end;
         -1:  begin
                 // Rebalance
                 N1:= Root.Left;
                 B1:= N1.Balance;
                 if( B1 <= 0) then begin
                    // Single LL Rotation
                    Root.Left:= N1.Right;
                    N1.Right:= Root;
                    if( B1 = 0) then begin
                       Root.Balance:= -1;
                       N1.Balance:= 1;
                       HasShrunk:= false;
                    end else begin
                       Root.Balance:= 0;
                       N1.Balance:= 0;
                    end; // Else B1 > 0
                    Root:= N1;
                 end else begin
                    // Double LR rotation
                    N2:= N1.Right;
                    B2:= N2.Balance;
                    N1.Right:= N2.Left;
                    N2.Left:= N1;
                    Root.Left:= N2.Right;
                    N2.Right:= Root;
                    if( B2 = -1) then begin
                       Root.Balance:= 1;
                    end else begin
                       Root.Balance:= 0;
                    end;
                    if( B2 = 1) then begin
                       N1.Balance:= -1;
                    end else begin
                       N1.Balance:= 0;
                    end;
                    Root:= N2;
                    N2.Balance:= 0;
                 end; // else B1 < 0
              end;  // case of 1:
      end; // case Root.Balance of
   end; // AVLBalanceRight


// *************************************************************************
// * AVLBalanceLeft() - Left branch has shrunk
// *************************************************************************

procedure AVLBalanceLeft( var Root:      tTreeNode;
                          var HasShrunk: boolean);
   var
      N1:  tTreeNode;
      N2:  tTreeNode;
      B1:  int8;
      B2:  int8;
   begin
      case Root.Balance of
         -1:  begin
                 Root.Balance:= 0;
              end;
          0:  begin
                 Root.Balance:= 1;
                 HasShrunk:= false;
              end;
          1:  begin
                 // Rebalance
                 N1:= Root.Right;
                 B1:= N1.Balance;
                 if( B1 >= 0) then begin
                    // Single RR Rotation
                    Root.Right:= N1.Left;
                    N1.Left:= Root;
                    if( B1 = 0) then begin
                       Root.Balance:= 1;
                       N1.Balance:= -1;
                       HasShrunk:= false;
                    end else begin
                       Root.Balance:= 0;
                       N1.Balance:= 0;
                    end; // Else B1 > 0
                    Root:= N1;
                 end else begin
                    // Double RL rotation
                    N2:= N1.Left;
                    B2:= N2.Balance;
                    N1.Left:= N2.Right;
                    N2.Right:= N1;
                    Root.Right:= N2.Left;
                    N2.Left:= Root;
                    if( B2 = 1) then begin
                       Root.Balance:= -1;
                    end else begin
                       Root.Balance:= 0;
                    end;
                    if( B2 = -1) then begin
                       N1.Balance:= 1;
                    end else begin
                       N1.Balance:= 0;
                    end;
                    Root:= N2;
                    N2.Balance:= 0;
                 end; // else B1 < 0
              end;  // case of 1:
      end; // case Root.Balance of
   end; // AVLBalanceLeft


// *************************************************************************
// * AVLDelete() - This version deletes Node Q from the tree and optionaly
// *               destroys the object contained in Q (Q.Item)
// *************************************************************************

procedure AVLDelete( var Root:           tTreeNode;
                     var HasShrunk:      boolean;
                         DestroyElement: boolean);
   var
      Q:           tTreeNode;
      FoundItem:      tObject;

   // ----------------------------------------------------------------------

   procedure DeleteSub( var R:         tTreeNode;
                        var HasShrunk: boolean);
      begin
         if( R.Right <> nil) then begin
            DeleteSub( R.Right, HasShrunk);
            if( HasShrunk) then begin
               AVLBalanceRight( R, HasShrunk);
            end;
         end else begin
            Q.Item:= R.Item;
            Q:= R;
            R:= R.Left;
            HasShrunk:= true;
         end;
      end; // DeleteSub()

   // ----------------------------------------------------------------------

   begin
      Q:= Root;
      FoundItem:= Q.Item;

      if( Q.Right = nil) then begin
         Root:= Q.Left;
         HasShrunk:= true;
      end else if( Q.Left = nil) then begin
         Root:= Q.Right;
         HasShrunk:= true;
      end else begin
         DeleteSub( Q.Left, HasShrunk);
         if( HasShrunk) then begin
            AVLBalanceLeft( Root, HasShrunk);
         end;
      end;

      if( DestroyElement) then begin
         FoundItem.Destroy()
      end;
      Q.Destroy();
   end; // AVLDelete()


// *************************************************************************
// * AVLDelete() - Find Item where SearchItem.Compare( Item) = 0 and delete
// *               that Item from the tree.  If DestroyItem is true, then
// *               destroy (remove from memory) the found Item.
// *               (recursive)  - First call should have HasShrunk = false
// *************************************************************************

procedure AVLDelete(     SearchItem:     tObject;
                     var Root:           tTreeNode;
                         Compare:        tCompareProcedure;
                     var HasShrunk:      boolean;
                         DestroyElement: boolean);
   var
      CompareResult:  int8;

   begin // AVLDelete()
      if( Root = nil) then begin
         raise lbpBinaryTreeException.Create(
             'lbpBinaryTree.Remove():  SearchItem not found in the tree!');
      end;

      CompareResult:= Compare( Root.Item, SearchItem);
      if( CompareResult > 0) then begin
         AVLDelete( SearchItem, Root.Left, Compare, HasShrunk, DestroyElement);
         if( HasShrunk) then begin
            AVLBalanceLeft( Root, HasShrunk);
         end;
      end else if( CompareResult < 0) then begin
         AVLDelete( SearchItem, Root.Right, Compare, HasShrunk, DestroyElement);
         if( HasShrunk) then begin
            AVLBalanceRight( Root, HasShrunk);
         end;
      end else begin
         // We found the node to be deleted
         AVLDelete( Root, HasShrunk, DestroyElement);

      end; // else we found the node
   end; // AVLDelete()


// *************************************************************************
// * AVLDeleteAll() - Delete tTreeNodes from the subtree starting at root.
// *                  Optionaly dispose of the Items pointed to by the node.
// *                  ( recursive )
// *************************************************************************

procedure AVLDeleteAll( var Root:            tTreeNode;
                            DestroyElements: boolean);
   begin
      if( Root <> nil) then begin
         AVLDeleteAll( Root.Left, DestroyElements);
         if( DestroyElements) then begin
            Root.Item.Destroy();
         end;
         AVLDeleteAll( Root.Right, DestroyElements);
         Root.Destroy();
      end;
   end; // AVLDeleteAll()


// *************************************************************************
// * AVLForEach() - Execute procedure P for each element in the subtree
// *                starting at Root.  ( recursive )
// *************************************************************************

procedure AVLForEach( var Root: tTreeNode; P: tObjProcedure);
   begin
      if( Root <> nil) then begin
         AVLForEach( Root.Left, P);
         P( Root.Item);
         AVLForEach( Root.Right, P);
      end;
   end; // AVLForEach()



// =========================================================================
// = tTreeNode
// =========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tTreeNode.Create( iItem: tObject);
   begin
      Item:=    iItem;
      Parent:=  nil;
      Left:=    nil;
      Right:=   nil;
      Balance:= 0;
   end; // Create()


// *************************************************************************
// * Destroy() - Destructor
// *************************************************************************

destructor tTreeNode.Destroy();
   begin
      Item:=   nil;
      Parent:= nil;
      Left:=   nil;
      Right:=  nil;
   end; // Destroy()


// =========================================================================
// = tBalancedBinaryTree
// =========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tBalancedBinaryTree.Create( iCompare:     tCompareProcedure);
   begin
      Root:= nil;
      Compare:= iCompare;
      DuplicateOK:= false;
      CurrentNode:= nil;
      Name:= '';
   end; // Create()


// -------------------------------------------------------------------------

constructor tBalancedBinaryTree.Create( iCompare:     tCompareProcedure;
                                        iDuplicateOK: boolean);
   begin
      Root:= nil;
      Compare:= iCompare;
      DuplicateOK:= iDuplicateOK;
      CurrentNode:= nil;
      Name:= '';
   end; // Create()


// -------------------------------------------------------------------------
// - Copy all OtherTree nodes into self
// -------------------------------------------------------------------------
constructor tBalancedBinaryTree.Create( iCompare:     tCompareProcedure;
                                        iDuplicateOK: boolean;
                                        OtherTree:    tBalancedBinaryTree);
   begin
      Root:= nil;
      Compare:= iCompare;
      DuplicateOK:= iDuplicateOK;
      CurrentNode:= nil;

      OtherTree.Copy( self);
      Name:= '';
      MyCount:= 0;
   end; // Create()


// *************************************************************************
// * Destroy() - Destructor
// *************************************************************************

destructor tBalancedBinaryTree.Destroy();
   begin
      RemoveAll();
      Root:= nil;
   end; // Destroy()


// *************************************************************************
// * Copy() - Add all the items in this tree to OtherTree
// *          NOTE!  Care must be take to make sure the
// *************************************************************************

procedure tBalancedBinaryTree.Copy( OtherTree: tBalancedBinaryTree);
   var
      Item: tObject;
   begin
      Item:= GetFirst();
      while( Item <> nil) do begin
         OtherTree.Add( Item);
         Item:= GetNext();
      end;
   end; // Copy()


// *************************************************************************
// * Add() - Add an element to the TreeNode
// *************************************************************************

procedure tBalancedBinaryTree.Add( Item: tObject);
   var
      HasGrown: boolean = false;
   begin
      CurrentNode:= AVLInsert( Item, Root, Compare,
                               HasGrown, DuplicateOK);
      Inc( MyCount);
   end; // Add()


// *************************************************************************
// * Find() - Find Item where SearchItem.Compare( Item) = 0
// *************************************************************************

function tBalancedBinaryTree.Find( Item: tObject): tObject;
   var
      Temp: tTreeNode;
   begin
      Temp:= AVLFind( Item, Root, Compare);
      if( Temp = nil) then begin
         result:= nil;
      end else begin
         result:= Temp.Item;
      end;
      CurrentNode:= nil;
   end; // Find()


// *************************************************************************
// * GetFirst() - Get the first item in the tree
// *************************************************************************

function tBalancedBinaryTree.GetFirst(): tObject;
   begin
      if( Root = nil) then begin
         CurrentNode:= nil;
         result:= CurrentNode;
         exit;
      end;

      CurrentNode:= root;
      while( CurrentNode.Left <> nil) do begin
         CurrentNode:= CurrentNode.Left;
      end;
      result:= CurrentNode.Item;
   end; // GetFirst()


// *************************************************************************
// * GetLast() - Get the last item in the tree
// *************************************************************************

function tBalancedBinaryTree.GetLast(): tObject;
   begin
      if( Root = nil) then begin
         CurrentNode:= nil;
         result:= CurrentNode;
         exit;
      end;

      CurrentNode:= root;
      while( CurrentNode.Right <> nil) do begin
         CurrentNode:= CurrentNode.Right;
      end;

      result:= CurrentNode.Item;
   end; // GetLast()


// *************************************************************************
// * GetNext() - Get the next item in the tree
// *************************************************************************

function tBalancedBinaryTree.GetNext(): tObject;
   var
      PreviousNode: tTreeNode;
   begin
      if( Root = nil) then begin
         CurrentNode:= nil;
         result:= CurrentNode;
         exit;
      end;


      if( CurrentNode = nil) then begin
         result:= GetFirst();
         exit;
      end;

      PreviousNode:= CurrentNode;

      // Two choices - 1 Right child is available  2 try from our parent
      if( CurrentNode.Right <> nil) then begin

         // Right child is available
         CurrentNode:= CurrentNode.Right;

         // Need to head left from here like GetFirst()
         while( CurrentNode.Left <> nil) do begin
            CurrentNode:= CurrentNode.Left;
         end;

      end else begin

         // Try from our parent
         repeat
            PreviousNode:= CurrentNode;
            CurrentNode:= CurrentNode.Parent;
         until( (CurrentNode = nil) or (CurrentNode.Left = PreviousNode));
      end;

      if( CurrentNode = nil) then begin
         result:= nil;
      end else begin
         result:= CurrentNode.Item;
      end;
   end; // GetNext()


// *************************************************************************
// * GetPrevious() - Get the previous item in the tree
// *************************************************************************

function tBalancedBinaryTree.GetPrevious(): tObject;
   var
      PreviousNode: tTreeNode;
   begin
      if( Root = nil) then begin
         CurrentNode:= nil;
         result:= CurrentNode;
         exit;
      end;


      if( CurrentNode = nil) then begin
         result:= GetLast();
         exit;
      end;

      PreviousNode:= CurrentNode;

      // Two choices - 1 Left child is available  2: try parent
      if( CurrentNode.Left <> nil) then begin

         // Right child is available
         CurrentNode:= CurrentNode.Left;

         // Need to head left from here like GetLast()
         while( CurrentNode.Right <> nil) do begin
            CurrentNode:= CurrentNode.Right;
         end;

      end else begin

         // Try from our parent
         repeat
            PreviousNode:= CurrentNode;
            CurrentNode:= CurrentNode.Parent;
         until( (CurrentNode = nil) or (CurrentNode.Right = PreviousNode));
      end;

      if( CurrentNode = nil) then begin
         result:= nil;
      end else begin
         result:= CurrentNode.Item;
      end;
   end; // GetPrevious()


// *************************************************************************
// * Remove() - Remove an element from the tree.
// *************************************************************************

procedure tBalancedBinaryTree.Remove( DestroyElement: boolean = false);
   var
      HasShrunk: boolean;
   begin
      HasShrunk:= false;
      AVLDelete( CurrentNode, HasShrunk, DestroyElement);
      CurrentNode:= nil;
      Dec( MyCount);
   end; // Remove()


// -------------------------------------------------------------------------

procedure tBalancedBinaryTree.Remove( SearchItem:     tObject;
                                      DestroyElement: boolean = false);
   var
      Shorter: boolean;
   begin
      AVLDelete( SearchItem, Root, Compare, Shorter, DestroyElement);
      CurrentNode:= nil;
      Dec( MyCount);
   end; // Remove()


// *************************************************************************
// * RemoveAll - Removes all elements from the tree.  Optionaly call the
// *             destructor for each element.
// *************************************************************************

procedure tBalancedBinaryTree.RemoveAll( DestroyElements: boolean = false);
   begin
      AVLDeleteAll( Root, DestroyElements);
      Root:= nil;
      CurrentNode:= nil;
      MyCount:= 0;
   end; // RemoveAll()


// *************************************************************************
// * ForEach() - Execute procedure P for each element in the tree.
// *************************************************************************

procedure tBalancedBinaryTree.ForEach( P: tObjProcedure);
   begin
      AVLForEach( Root, P);
   end; // ForEach()


// *************************************************************************
// * IsEmpty() - Returns true if the tree is empty.
// *************************************************************************

function tBalancedBinaryTree.IsEmpty(): boolean;
   begin
      IsEmpty:= (Root = nil);
   end; // IsEmpty()


// *************************************************************************
// * GetRoot() - Returns the current root of the tree.
// *************************************************************************

function tBalancedBinaryTree.GetRoot(): tTreeNode;
   begin
      GetRoot:= Root;
   end; // GetRoot()


// *************************************************************************

end. // lbp_binary_trees unit
