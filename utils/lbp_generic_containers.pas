{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Generic Lists, AVLTree, and a Dictionary which uses an AVL tree.

AVL (Average Level) tree which uses generics
The AVL Tree is my attempt to make a generic version of Mattias Gaertner's
tAVLTree in the AVL_Tree unit included with Free Pascal.  Since I had written
my own AVL tree very shortly before Mattias' was released, I combined features
of both into this one. 



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

unit lbp_generic_containers;

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
   lbp_utils;     // padleft() - only used for debug code.
   
// ************************************************************************

function CompareStrings(  S1: string;  S2: string):  integer;
function CompareWord64s(  W1: word64;  W2: word64):  integer;
function CompareWord32s(  W1: word32;  W2: word32):  integer;
function CompareIntegers( I1: integer; I2: integer): integer;
function CompareInt64s(   I1: int64;   I2: int64):   integer;
function CompareInt32s(   I1: int32;   I2: int32):   integer;


// ************************************************************************

type
   lbpContainerException = class( lbp_exception);


// ************************************************************************
// * tgList class - Uses a fixed size array to implement a circular list
// ************************************************************************
type
   generic tgList< T> = class( tObject)
      private type
      // ---------------------------------------------------------------
         tEnumerator = class(tObject)
            private
               MyList: tgList;
            public
               constructor Create( List: tgList);
            private
               function GetCurrent(): T;
            public
               function MoveNext(): boolean;
               property Current: T read GetCurrent;
            end; // tEnumerator
      // ---------------------------------------------------------------
      public
         Name:          String;
      protected
         MySize:        integer;
         SizeM:         integer; // MySize - 1
         MyHead:        integer;
         MyTail:        integer;
         CurrentIndex:  integer;
         MyForward:     boolean;
         Items:         array of T;
      public
         constructor    Create( const iSize: integer; iName: string = '');
      protected
         function       IncIndex( I: integer): integer; virtual;
         function       DecIndex( I: integer): integer; virtual;
         procedure      AddHead( Item: T); virtual; // Add to the head of the list
         function       GetHead(): T; virtual;      // Return the head element.
         function       RemoveHead(): T; virtual;      // Return the head element and remove it from the list.
         procedure      AddTail( Item: T); virtual; // Add to the tail of the list
         function       GetTail(): T; virtual;      // Return the tail element
         function       RemoveTail(): T; virtual;      // Return the tail element and remove it from the list.
         function       GetByIndex( i: integer): T; virtual;
         procedure      DestroyValue( Args: array of const); virtual;
         procedure      RemoveAll( DestroyElements: boolean = false); virtual; // Remove all elements from the list.
      public
         procedure      Empty(); virtual;
         procedure      StartEnumeration( Forward: boolean = true); virtual;
         function       Next():           boolean; virtual;
         function       IsEmpty():        boolean; virtual;
         function       IsFull():         boolean; virtual;
         function       IsFirst():        boolean; virtual; // True if CurrentNode is First
         function       IsLast():         boolean; virtual;
         function       GetCurrent():     T;       virtual; // Returns the data pointer at CurrentNode
         procedure      Replace( Item: T); virtual; 
         function       Length():         integer; virtual;
         function       GetEnumerator():  tEnumerator; virtual;
         function       Reverse():        tEnumerator; virtual;
         property       Head:             T read RemoveHead write AddHead;
         property       Tail:             T read RemoveTail write AddTail;
         property       Stack:            T read RemoveTail write AddTail;
         property       Push:             T write AddTail;
         property       Pop:              T read RemoveTail;
         property       Queue:            T read RemoveHead write AddTail;
         property       Enqueue:          T write AddTail;
         property       Dequeue:          T read RemoveHead;
         property       Value:            T read GetCurrent write Replace;
         property       Forward:    boolean read MyForward write MyForward;
         property       Peek[ i: integer]: T read GetByIndex;
   end; // generic tgList


// ************************************************************************
// * tgDoubleLinkiedList
// ************************************************************************

type
   generic tgDoubleLinkedList< T> = class( tObject)
         //public type tListNodePtr = ^tListNode;
      protected type
         // ---------------------------------------------------------------
         tListNode = class( tObject)
            protected
               Item:    T;
               Prev:    tListNode;
               Next:    tListNode;
            public
               constructor  Create( MyItem: T = Default( T));
            end; // tgListNode class
         // ---------------------------------------------------------------
         tEnumerator = class(tObject)
            public
               MyList: tgDoubleLinkedList;
               constructor Create( List: tgDoubleLinkedList);
               function GetCurrent(): T;
               function MoveNext(): boolean;
               property Current: T read GetCurrent;
            end; // tEnumerator
         // ---------------------------------------------------------------
      public
         Name:          String;
      protected
         FirstNode:     tListNode;
         LastNode:      tListNode;
         CurrentNode:   tListNode;
         ListLength:    Int32;
         MyForward:     boolean;
      public
         constructor    Create( const iName: string = '');
         destructor     Destroy; override;
         procedure      AddHead( Item: T); virtual; // Add to the head of the list
         function       GetHead(): T; virtual;      // Return the head element.
         function       DelHead(): T; virtual;      // Return the head element and remove it from the list.
         procedure      AddTail( Item: T); virtual; // Add to the tail of the list
         function       GetTail(): T; virtual;      // Return the tail element
         function       DelTail(): T; virtual;      // Return the tail element and remove it from the list.
         procedure      InsertBeforeCurrent( Item: T); virtual;
         procedure      InsertAfterCurrent( Item: T); virtual;
         procedure      Replace( OldItem, NewItem: T); virtual;
         procedure      Replace( NewItem: T); virtual;
         procedure      Remove( Item: T); virtual;
         procedure      Remove(); virtual;
         procedure      StartEnumeration( Forward: boolean = true); virtual;
         function       Next():           boolean; virtual;
         procedure      RemoveAll( DestroyElements: boolean = false); virtual; // Remove all elements from the list.
         function       IsEmpty():        boolean; virtual;
         function       IsFirst():        boolean; virtual; // True if CurrentNode is First
         function       IsLast():         boolean; virtual;
         function       GetCurrent():     T virtual; // Returns the data pointer at CurrentNode
         function       GetEnumerator():  tEnumerator;
         function       Reverse():        tEnumerator;
      private
         procedure      DestroyValue( Args: array of const);
      public
         property       Head:             T read DelHead write AddHead;
         property       Tail:             T read DelTail write AddTail;
         property       Stack:            T read DelTail write AddTail;
         property       Push:             T write AddTail;
         property       Pop:              T read DelTail;
         property       Queue:            T read DelHead write AddTail;
         property       Enqueue:          T write AddTail;
         property       Dequeue:          T read DelHead;
         property       Value:            T read GetCurrent write Replace;
         property       Length:           Int32 read ListLength;
   end; // generic tgDoubleLinkedList


// ************************************************************************
// * tgAvlTree
// ************************************************************************

type
   generic tgAvlTree< V> = class( tObject)
      protected type
      // ---------------------------------------------------------------
         tNode = class( tObject)
            protected
               Parent:      tNode;
               LeftChild:   tNode;
               RightChild:  tNode;
               Balance:     integer;
               Value:       V;
            public
               constructor  Create( iValue: V);
               procedure    Clear;
               function     TreeDepth(): integer; // longest WAY down. e.g. only one tNode => 0 !
               function     First():    tNode;
               function     Last():     tNode;
               function     Next():     tNode;
               function     Previous(): tNode;
            end; // tNode class
      // ---------------------------------------------------------------
      private type
         tEnumerator = class( tObject)
            private
               Tree:    tgAvlTree;
               Node:    tNode;
            public
               constructor Create( iTree: tgAvlTree);
               function    MoveNext: Boolean;
               function    GetCurrent(): V;
               property    Current: V read GetCurrent;
            end; // enumerator class
      // ---------------------------------------------------------------
      private type
         tReverseEnumerator = class( tObject)
            private
               Tree:    tgAvlTree;
               Node:    tNode;
            public
               constructor Create( iTree: tgAvlTree);
               function    MoveNext: Boolean;
               function    GetEnumerator(): tReverseEnumerator;
               function    GetCurrent(): V;
               property    Current: V read GetCurrent;
            end; // enumerator class
      // ---------------------------------------------------------------


      public
         type
            tCompareFunction = function( const iValue1, iValue2: V): Integer;
            tNodeToStringFunction = function( const iValue: V): string;  
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
         procedure   Add( iValue: V); virtual;
         procedure   RemoveCurrent(); virtual; // Remove the Current Node from the tree
         procedure   Remove( iValue: V);  virtual; // Remove the node which contains T
         function    Find( iValue: V): boolean; virtual;
         procedure   StartEnumeration(); virtual;
         function    Previous():  boolean; virtual;
         function    Next():      boolean; virtual;
         function    Value(): V; virtual;
         function    GetEnumerator(): tEnumerator;
         function    Reverse(): tReverseEnumerator;
         procedure   Dump( N:       tNode = nil; 
                           Prefix:  string = ''); virtual;  // Debug code
      private
         function    FindNode( iValue: V): tNode; virtual;
         procedure   RemoveNode( N: tNode);  virtual; // Remove the passed node
         function    IsEmpty():  boolean; virtual;
         procedure   RemoveSubtree( StRoot: tNode; DestroyElements: boolean); virtual;
         function    FindInsertPosition( iValue: V): tNode; virtual;
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
      end; // tgAvlTree


// ************************************************************************
// * tgDictionary class - A dictionary built with an AVL tree
// ************************************************************************

type
   generic tgDictionary< K, V> = class( tObject)
      private type
      // ---------------------------------------------------------------
         tNode = class( tObject)
            protected
               Parent:      tNode;
               LeftChild:   tNode;
               RightChild:  tNode;
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
         tEnumerator = class( tObject)
            private
               Tree:    tgDictionary;
               Node:    tNode;
            public
               constructor Create( iTree: tgDictionary);
               function    MoveNext: Boolean;
               function    GetCurrent(): V;
               property    Current: V read GetCurrent;
            end; // enumerator class
      // ---------------------------------------------------------------
      private type
         tReverseEnumerator = class( tObject)
            private
               Tree:    tgDictionary;
               Node:    tNode;
            public
               constructor Create( iTree: tgDictionary);
               function    MoveNext: Boolean;
               function    GetEnumerator(): tReverseEnumerator;
               function    GetCurrent(): V;
               property    Current: V read GetCurrent;
            end; // enumerator class
      // ---------------------------------------------------------------
      private type
         tKeyEnumerator = class( tObject)
            private
               Tree:    tgDictionary;
               Node:    tNode;
            public
               constructor Create( iTree: tgDictionary);
               function    MoveNext: Boolean;
               function    GetEnumerator(): tKeyEnumerator;
               function    GetCurrent(): K;
               property    Current: K read GetCurrent;
            end; // enumerator class
      // ---------------------------------------------------------------
      private type
         tReverseKeyEnumerator = class( tObject)
            private
               Tree:    tgDictionary;
               Node:    tNode;
            public
               constructor Create( iTree: tgDictionary);
               function    MoveNext: Boolean;
               function    GetEnumerator(): tReverseKeyEnumerator;
               function    GetCurrent(): K;
               property    Current: K read GetCurrent;
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
         function    GetEnumerator(): tEnumerator;
         function    Reverse(): tReverseEnumerator;
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
      end; // tgDictionary


// ************************************************************************

implementation

// ========================================================================
// = Global functions
// ========================================================================
// *************************************************************************
// * CompareStrings - The most common compare function used by containers
// *************************************************************************

function CompareStrings(  S1: string; S2: string): integer;
   begin
      if( S1 > S2) then begin
         result:= 1;
      end else if( S1 < S2) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareStrings()


// *************************************************************************
// * CompareWord64s - A common compare function used by containers
// *************************************************************************

function CompareWord64s( W1: word64; W2: word64): integer;
   begin
      if( W1 > W2) then begin
         result:= 1;
      end else if( W1 < W2) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareWord64s()


// *************************************************************************
// * CompareWord32s - A common compare function used by containers
// *************************************************************************

function CompareWord32s( W1: word32; W2: word32): integer;
   begin
      if( W1 > W2) then begin
         result:= 1;
      end else if( W1 < W2) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareWord32s()


// *************************************************************************
// * CompareIntegers - A Common compare function used by containers
// *************************************************************************

function CompareIntegers( I1: integer; I2: integer): integer;
   begin
      if( I1 > I2) then begin
         result:= 1;
      end else if( I1 < I2) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareIntegers()



// *************************************************************************
// * CompareInt64 - A Common compare function used by containers
// *************************************************************************

function CompareInt64s( I1: int64; I2: int64): integer;
   begin
      if( I1 > I2) then begin
         result:= 1;
      end else if( I1 < I2) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareInt64()



// *************************************************************************
// * CompareInt32 - A Common compare function used by containers
// *************************************************************************

function CompareInt32s( I1: int32; I2: int32): integer;
   begin
      if( I1 > I2) then begin
         result:= 1;
      end else if( I1 < I2) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareInt32()



// ========================================================================
// = tgList generic class
// ========================================================================
// ************************************************************************
// * Constructors
// ************************************************************************

constructor tgList.Create( const iSize: integer; iName: string = '');
   begin
      inherited Create;
      MySize:= iSize + 2;
      SizeM:=  iSize + 1;
      Name:=   iName;
      SetLength( Items, MySize);
      MyHead:= 0;
      MyTail:= 1;
      MyForward:= true;
      CurrentIndex:= -1;
   end; // Create()


// ************************************************************************
// * IncIndex() - Increment the passed index and return the value
// ************************************************************************

function tgList.IncIndex( I: integer): integer;
   begin
      result:= (I + 1) mod MySize; 
   end; // IncIndex()


// ************************************************************************
// * DecIndex() - Decrement the passed index and return the value
// ************************************************************************

function tgList.DecIndex( I: integer): integer;
   begin
      result:= (I + SizeM) mod MySize; 
   end; // DecIndex();


// ************************************************************************
// * AddHead() - Add an item to the head of the list
// ************************************************************************

procedure tgList.AddHead( Item: T);
   begin
      if( IsFull) then begin
         raise lbpContainerException.Create( 'An attempt was made to add an item to a circular list which is full!');
      end;

      Items[ MyHead]:= Item;
      MyHead:= DecIndex( MyHead);
      CurrentIndex:= -1;
   end; // AddHead()


// ************************************************************************
// * GetHead() - Returns the Item at the Head
// ************************************************************************

function tgList.GetHead(): T;
   begin
      if( IsEmpty) then begin
         raise lbpContainerException.Create( 'An attempt was made to get an item from an empty list');
      end;
      CurrentIndex:= -1;
      result:= Items[ IncIndex( MyHead)];
   end; // GetHead()


// ************************************************************************
// * RemoveHead() - Removes and returns the Item at the Head
// ************************************************************************

function tgList.RemoveHead(): T;
   begin
      if( IsEmpty) then begin
         raise lbpContainerException.Create( 'An attempt was made to get an item from an empty list');
      end;
      MyHead:= IncIndex( MyHead);
      result:= Items[ MyHead];
      CurrentIndex:= -1;
   end; // RemoveHead()


// ************************************************************************
// * AddTail() - Add an item to the Tail of the list
// ************************************************************************

procedure tgList.AddTail( Item: T);
   begin
      if( IsFull) then begin
         raise lbpContainerException.Create( 'An attempt was made to add an item to a circular list which is full!');
      end;

      Items[ MyTail]:= Item;
      MyTail:= IncIndex( MyTail);
      CurrentIndex:= -1;
   end; // AddTail()


// ************************************************************************
// * GetTail() - Returns the Item at the Tail
// ************************************************************************

function tgList.GetTail(): T;
   begin
      if( IsEmpty) then begin
         raise lbpContainerException.Create( 'An attempt was made to get an item from an empty list');
      end;
      CurrentIndex:= -1;
      result:= Items[ DecIndex( MyTail)];
   end; // GetTail()


// ************************************************************************
// * RemoveTail() - Removes and returns the Item at the Tail
// ************************************************************************

function tgList.RemoveTail(): T;
   begin
      if( IsEmpty) then begin
         raise lbpContainerException.Create( 'An attempt was made to get an item from an empty list');
      end;
      MyTail:= DecIndex( MyTail);
      result:= Items[ MyTail];
      CurrentIndex:= -1;
   end; // RemoveTail()


// ************************************************************************
// * GetByIndex() - Return the i'th element.  The first element is #1
// ************************************************************************

function tgList.GetByIndex( i: integer): T;
   begin
      if( (i <= 0) or (i > Length)) then begin
         raise lbpContainerException.Create( 'tgList index out of bounds!');
      end;

      result:= Items[ (MyHead + i) mod MySize];
   end; // GetByIndex()


// ************************************************************************
// * DestroyValue() - If the passed value is a class, call its destructor
// *                  This should only be used internally and will always
// *                  be passed a single value.
// ************************************************************************

procedure tgList.DestroyValue( Args: array of const);
   begin
      if( Args[ 0].vtype = vtObject) then tObject( Args[ 0].vObject).Destroy();
   end; // DestroyValue;


// ************************************************************************
// * RemoveAll()  - Removes all elements from the list.  If DestroyElements
// *                is true, each element's destructor will be called.
// ************************************************************************

procedure tgList.RemoveAll( DestroyElements: boolean);
   var
      N: T;
   begin
      while( not IsEmpty) do begin
         N:= Queue;
         if( DestroyElements) then DestroyValue( [N]);
      end;
   end; // RemoveAll()


// ************************************************************************
// * Empty() - Remove all elements from the list.  No destructors are
//             called!
// ************************************************************************

procedure tgList.Empty;
   begin
      MyHead:= 0;
      MyTail:= 1;
      MyForward:= true;
      CurrentIndex:= -1;   
   end; // RemoveAll


// ************************************************************************
// * StartEnumeration() - Begin the iteration
// ************************************************************************

procedure tgList.StartEnumeration( Forward: boolean);
   begin
      MyForward:= Forward;  // Set the direction
      CurrentIndex:= -1;
   end; // StartEnumeration


// ************************************************************************
// * Next() - Returns true if the buffer is empty
// ************************************************************************

function tgList.Next(): boolean;
   begin
      // If Empty
      if( (MyTail = IncIndex( MyHead))) then begin
         result:= false;
      end else begin
         if( MyForward) then begin
            if( CurrentIndex < 0) then CurrentIndex:= MyHead;
            CurrentIndex:= IncIndex( CurrentIndex);
            if( CurrentIndex = MyTail) then CurrentIndex:= -1;  
         end else begin
            if( CurrentIndex < 0) then CurrentIndex:= MyTail;
            CurrentIndex:= DecIndex( CurrentIndex);
            if( CurrentIndex = MyHead) then CurrentIndex:= -1;  
         end; // else not MyForward
         result:= ( CurrentIndex >= 0);
      end; // else not MyForward
   end; // Next();


// ************************************************************************
// * IsEmpty() - Returns true if the buffer is empty
// ************************************************************************

function tgList.IsEmpty(): boolean;
   begin
      result:= (MyTail = IncIndex( MyHead));
   end; // IsEmpty()


// ************************************************************************
// * IsFull() - Returns true if the buffer is full
// ************************************************************************

function tgList.IsFull(): boolean;
   begin
      result:= (MyHead = IncIndex( MyTail));
   end; // IsFull()


// ************************************************************************
// * IsFirst()  - Returns true if the current item is also first
// ************************************************************************

function tgList.IsFirst(): boolean;
   begin
     result:= (CurrentIndex = IncIndex( MyHead));
   end; // IsFirst()


// ************************************************************************
// * IsLast()  - Returns true if the current item is also last
// ************************************************************************

function tgList.IsLast(): boolean;
   begin
     result:= (CurrentIndex = DecIndex( MyTail));
   end; // IsLast()


// ************************************************************************
// * GetCurrent() - Returns the current element
// ************************************************************************

function tgList.GetCurrent: T;
   begin
      result:= Items[ CurrentIndex];
   end; // GetCurrent;


// ************************************************************************
// * Replace() - Replaces the current element with a new value
// ************************************************************************

procedure tgList.Replace( Item: T);
   begin
      Items[ CurrentIndex]:= Item;   
   end; // Replace()


// ************************************************************************
// * Length() - Returns the number of elements in the list
// ************************************************************************

function tgList.Length(): integer;
   var
      Tl: integer;
   begin
      if( MyTail < MyHead) then Tl:= MyTail + MySize else Tl:= MyTail;
      result:= Tl - MyHead - 1;
   end; // Length()

// ************************************************************************
// * GetEnumerator()  - Returns the enumerator
// ************************************************************************

function tgList.GetEnumerator():  tEnumerator;
   begin
      result:= tEnumerator.Create( Self);
      CurrentIndex:= -1;
      MyForward:= true;
   end; // GetEnumerator()


// ************************************************************************
// * Reverse()  - Returns the enumerator
// ************************************************************************

function tgList.Reverse():  tEnumerator;
   begin
      result:= tEnumerator.Create( Self);
      CurrentIndex:= -1;
      MyForward:= false;
   end; // Reverse()


// ------------------------------------------------------------------------
// -  tEnumerator
// ------------------------------------------------------------------------
// ************************************************************************
// * Create() - constructor
// ************************************************************************

constructor tgList.tEnumerator.Create( List: tgList);
   begin
      inherited Create;
      List.CurrentIndex:= -1;
      MyList:= List;
   end; // Create()


// ************************************************************************
// * GetCurrent() - Return the current list element
// ************************************************************************

function tgList.tEnumerator.GetCurrent(): T;
   begin
      result:= MyList.Items[ MyList.CurrentIndex];
   end; // GetCurrent()


// ************************************************************************
// * MoveNext() - Move to the next element in the list
// ************************************************************************

function tgList.tEnumerator.MoveNext(): T;
   begin
      result:= MyList.Next;
   end; // MoveNext()



// ========================================================================
// = tgDoubleLinkedList.tListNode generic class
// ========================================================================
// ************************************************************************
// * Constructors
// ************************************************************************

constructor tgDoubleLinkedList.tListNode.Create( MyItem: T = Default( T));
  // Makes a new and empty List
  begin
     Item:= MyItem;
     Prev:= nil;
     Next:= nil;
  end; // Create()


// ========================================================================
// = tgDoubleLinkedList.tEnumerator generic class
// ========================================================================
// ************************************************************************
// * Create() - constructor
// ************************************************************************

constructor tgDoubleLinkedList.tEnumerator.Create( List: tgDoubleLinkedList);
   begin
      MyList:= List;
   end; // Create()


// ************************************************************************
// * GetCurrent() - Return the current list element
// ************************************************************************

function tgDoubleLinkedList.tEnumerator.GetCurrent(): T;
   begin
      result:= MyList.CurrentNode.Item;
   end; // GetCurrent()


// ************************************************************************
// * MoveNext() - Move to the next element in the list
// ************************************************************************

function tgDoubleLinkedList.tEnumerator.MoveNext(): T;
   begin
      result:= MyList.Next;
   end; // MoveNext()



// ========================================================================
// = tgDoubleLinkedList generic class
// ========================================================================
// ************************************************************************
// * Constructors
// ************************************************************************

constructor tgDoubleLinkedList.Create( const iName: String);
  // Makes a new and empty List
  begin
     FirstNode:=    Nil;
     LastNode:=     Nil;
     CurrentNode:=  Nil;
     Name:=         iName;
     ListLength:=   0;
     MyForward:=    true;
  end; // Create()


// ************************************************************************
// * Destructor
// ************************************************************************

destructor tgDoubleLinkedList.Destroy;

   begin
      RemoveAll();
      if( FirstNode <> nil) then begin
         raise lbpContainerException.Create(
            'List ' + Name + ' is not empty and can not be destroyed!');
      end;
      inherited Destroy;
   end; // Destroy();


// ************************************************************************
// * AddHead()  - Adds an Object to the front of the list
// ************************************************************************

procedure tgDoubleLinkedList.AddHead( Item: T);
   var
      N: tListNode;
   begin
      N:= tListNode.Create( Item);
      if( FirstNode = nil) then begin
         LastNode:= N;
      end else begin
         FirstNode.Prev:= N;
         N.Next:= FirstNode;
      end;
     FirstNode:= N;
     CurrentNode:= nil;
     ListLength += 1;
   end; // AddHead()


// ************************************************************************
// * GetHead()  - Returns the first element of the list
// ************************************************************************

function tgDoubleLinkedList.GetHead(): T;
   begin
      if( FirstNode = nil) then begin
         raise lbpContainerException.Create( 'Attempt to get an element from an empty list!');
      end else begin
         result:= FirstNode.Item;
      end;
   end;  // GetHead()


// ************************************************************************
// * DelHead()  - Returns the first element and removes it from the list
// ************************************************************************

function tgDoubleLinkedList.DelHead(): T;
   var
      N: tListNode;
   begin
      if( LastNode = nil) then begin
         raise lbpContainerException.Create( 'Attempt to get an element from an empty list!');
      end else begin
         N:= FirstNode;
         // Adjust Pointers
         // If only one element in list
         if FirstNode = LastNode then begin
            LastNode:= nil;
            FirstNode:= nil;
         end
         else begin
            FirstNode.Next.Prev:= nil;
            FirstNode:= FirstNode.Next;
         end;
         result:= N.Item;
         N.Destroy;
         ListLength -= 1;
      end; // if Empty
      CurrentNode:= nil;
   end;  // DelHead()


// ************************************************************************
// * AddTail() - Adds the object to the end of the list.
// *             Pushes an object on the stack.
// ************************************************************************

procedure tgDoubleLinkedList.AddTail( Item: T);
   var
      N: tListNode;
   begin
      N:= tListNode.Create( Item);
      if( LastNode = nil) then begin
         FirstNode:= N;
      end else begin
         LastNode.Next:= N;
         N.Prev:= LastNode;
      end;
     LastNode:= N;
     CurrentNode:= nil;
     ListLength += 1;
   end; // AddTail()


// ************************************************************************
// * GetTail()  - Returns the last element in the list and removes it from
// *              the list.
// ************************************************************************

function tgDoubleLinkedList.GetTail: T;
   begin
      if( LastNode = nil) then begin
         raise lbpContainerException.Create( 'Attempt to get an element from an empty list!');
      end else begin
         result:= LastNode.Item;
      end; // if Empty
   end;  // GetTail()


// ************************************************************************
// * DelTail()  - Returns the last element in the list and removes it from
// *              the list.
// ************************************************************************

function tgDoubleLinkedList.DelTail: T;
   var
      N: tListNode;
   begin
      if( LastNode = nil) then begin
         raise lbpContainerException.Create( 'Attempt to get an element from an empty list!');
      end else begin
         N:= LastNode;
         // Adjust Pointers
         // If only one element in list
         if FirstNode = LastNode then begin
            LastNode:= Nil;
            FirstNode:=Nil;
         end else begin
            LastNode.Prev.Next:= Nil;
            LastNode:= LastNode.Prev;
         end;
         result:= N.Item;

         N.Destroy;
         ListLength -= 1;
      end; // if Empty
      CurrentNode:= nil;
   end;  // DelTail()


// ************************************************************************
// * InsertBeforeCurrent()  - Places an object in the list in front
// *                          of the current object.
// ************************************************************************

procedure tgDoubleLinkedList.InsertBeforeCurrent( Item: T);
   var
      N:  tListNode;
   begin
      if( (CurrentNode = nil) or (CurrentNode = FirstNode)) then begin
         AddHead( Item);
      end else begin // There is a node in front of the current node
         N:= tListNode.Create( Item);
         // Insert N in between the node in front of current and current
         N.Next:= CurrentNode;
         N.Prev:= CurrentNode.Prev;
         N.Prev.Next:= N;
         N.Next.Prev:= N;
         CurrentNode:= nil;
         ListLength += 1;
      end;
   end; // InsertBeforeCurrent()


// ************************************************************************
// * InsertAfterCurrent()  - Places an object in the list behind
// *                         the current object.
// ************************************************************************

procedure tgDoubleLinkedList.InsertAfterCurrent( Item: T);
   var
      N:  tListNode;
   begin
      if( (CurrentNode = nil) or (CurrentNode = LastNode)) then begin
         AddTail( Item);  // Add to tail
      end else begin // There is a node after the current node
         N:= tListNode.Create( Item);
         // Insert N in between the node after the current and current
         N.Next:= CurrentNode.Next;
         N.Prev:= CurrentNode;
         N.Prev.Next:= N;
         N.Next.Prev:= N;
         CurrentNode:= nil;
         ListLength += 1;
      end;
   end; // InsertAfterCurrent()


// ************************************************************************
// * Replace()  - Replaces the first occurance of OldObj with NewObj.
// ************************************************************************

procedure tgDoubleLinkedList.Replace( OldItem, NewItem: T);
   var
      N: tListNode;
   begin
      if( FirstNode = nil) then
         raise lbpContainerException.Create( 'Old Item not found in list')
      else begin
         // Find the node
         N:= FirstNode;
         while (N <> nil) and (N.Item <> OldItem) do
            N:= N.Next;
         if (N = nil) then
            raise lbpContainerException.Create( 'Old Item not found in list')
         else
            N.Item:= NewItem;
         CurrentNode:= nil;
      end;
   end; // DoubleLinkedList.Replace


// ------------------------------------------------------------------------

procedure tgDoubleLinkedList.Replace( NewItem: T);
   begin
      if( CurrentNode <> nil) then begin
         CurrentNode.Item:= NewItem;
      end;
   end; // Replace()


// ************************************************************************
// * Remove()  - Removes the first occurance of Obj in the list.
// ************************************************************************

procedure tgDoubleLinkedList.Remove( Item: T);
   var
      N: tListNode;
   begin
      if( FirstNode = nil) then
         raise lbpContainerException.Create( 'Item not found in list')
      else begin
         // Find the node
         N:= FirstNode;
         while (N <> nil) and (N.Item <> Item) do
            N:= N.Next;
         if (N = nil) then
            raise lbpContainerException.Create( 'Old Item not found in list');

         // Adjust Pointers
         if N.Next = nil then LastNode:= N.Prev
         else N.Next.Prev:= N.Prev;
         if N.Prev = nil then FirstNode:= N.Next
         else N.Prev.Next:= N.Next;
         N.Destroy;
         ListLength -= 1;
      end; // else not Empty
      CurrentNode:= nil;
   end;  // Remove ()


// ------------------------------------------------------------------------

procedure tgDoubleLinkedList.Remove();
   begin
      if (CurrentNode = nil) then exit;
         raise lbpContainerException.Create( 'The is no current item to remove from the list.');

      // Adjust Pointers
      if CurrentNode.Next = Nil then LastNode:= CurrentNode.Prev
      else CurrentNode.Next.Prev:= CurrentNode.Prev;
      if CurrentNode.Prev = Nil then FirstNode:= CurrentNode.Next
      else CurrentNode.Prev.Next:= CurrentNode.Next;
      CurrentNode.Destroy;
      ListLength -= 1;
      CurrentNode:= nil;
   end;  // Remove()


// ************************************************************************
// * RemoveAll()  - Removes all elements from the list.  If DestroyElements
// *                is true, each element's destructor will be called.
// ************************************************************************

procedure tgDoubleLinkedList.RemoveAll( DestroyElements: boolean);
   var
      Item: T;
   begin
      while( FirstNode <> nil) do begin
         Item:= Dequeue;
         if( DestroyElements) then DestroyValue( [Item]);
      end;
   end; // RemoveAll()


// ************************************************************************
// * StartEnumeration() - Begin the iteration
// ************************************************************************

procedure tgDoubleLinkedList.StartEnumeration( Forward: boolean);
   begin
      MyForward:= Forward;  // Set the direction
      CurrentNode:= nil;
   end; // StartEnumeration

// ************************************************************************
// * Next() -
// ************************************************************************

function tgDoubleLinkedList.Next(): boolean;
   begin
      if( CurrentNode = nil) then begin
         if( MyForward) then CurrentNode:= FirstNode else CurrentNode:= LastNode;
      end else begin
         if( MyForward) then CurrentNode:= CurrentNode.Next else CurrentNode:= CurrentNode.Prev;
      end;
      result:= (CurrentNode <> nil);
   end; // Next()


// ************************************************************************
// * IsEmpty()  - Returns true if the list is empty
// ************************************************************************

function tgDoubleLinkedList.IsEmpty(): boolean;
   // Tests to see if the list is empty
   begin
     result:= (FirstNode = nil);
   end; // IsEmpty()


// ************************************************************************
// * IsFirst()  - Returns true if the current item is also first
// ************************************************************************

function tgDoubleLinkedList.IsFirst(): boolean;
   begin
     result:= (FirstNode <> nil) and (CurrentNode = FirstNode);
   end; // IsFirst()


// ************************************************************************
// * IsLast()  - Returns true if the current item is also last
// ************************************************************************

function tgDoubleLinkedList.IsLast(): boolean;
   begin
     result:= (LastNode <> nil) and (CurrentNode = LastNode);
   end; // IsLast()


// ************************************************************************
// * GetCurrent()  - Returns the current item in the list.
// *                 Does not remove it from the list.
// ************************************************************************

function tgDoubleLinkedList.GetCurrent(): T;
   begin
      if CurrentNode = nil then
         raise lbpContainerException.Create( 'The is no current item to remove from the list.')
      else
         result:= CurrentNode.Item;
   End; // GetCurrent()


// ************************************************************************
// * GetEnumerator()  - Returns the enumerator
// ************************************************************************

function tgDoubleLinkedList.GetEnumerator():  tEnumerator;
   begin
      result:= tEnumerator.Create( Self);
      CurrentNode:= nil;
      MyForward:= true;
   end; // GetEnumerator()


// ************************************************************************
// * Reverse()  - Returns the enumerator
// ************************************************************************

function tgDoubleLinkedList.Reverse():  tEnumerator;
   begin
      result:= tEnumerator.Create( Self);
      CurrentNode:= nil;
      MyForward:= false;
   end; // Reverse()


// ************************************************************************
// * DestroyValue() - If the passed value is a class, call its destructor
// *                  This should only be used internally and will always
// *                  be passed a single value.
// ************************************************************************

procedure tgDoubleLinkedList.DestroyValue( Args: array of const);
   begin
      if( Args[ 0].vtype = vtObject) then tObject( Args[ 0].vObject).Destroy();
   end; // DestroyValue;



// ========================================================================
// = tNode generic class
// ========================================================================
// ************************************************************************
// * Create() - constructor
// ************************************************************************
constructor tgAvlTree.tNode.Create( iValue: V);
   begin
      Parent:= nil;
      LeftChild:= nil;
      RightChild:= nil;
      Balance:= 0;
      Value:= iValue;
   end;

// ************************************************************************
// * Clear() - Zero out the fields 
// ************************************************************************

procedure tgAvlTree.tNode.Clear();
   begin
      Parent:= nil;
      LeftChild:= nil;
      RightChild:= nil;
      Balance:= 0;
      {$warning I commented out the line below but it might cause issues when Value is a class.}
//      Value:= nil;
   end;

// ************************************************************************
// * TreeDepth() - Returns the depth of this node.
// ************************************************************************

function tgAvlTree.tNode.TreeDepth(): integer;
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

function tgAvlTree.tNode.First(): tNode;
   begin
      result:= Self;
      while( result.LeftChild <> nil) do result:= result.LeftChild;
   end;


// ************************************************************************
// * Last() - Return the lowest value (rightmost) node of this node's 
// *          subtree. 
// ************************************************************************

function tgAvlTree.tNode.Last(): tNode;
   begin
      result:= Self;
      while( result.RightChild <> nil) do result:= result.RightChild;
   end;


// ************************************************************************
// * Next() - Return the next node in the tree
// ************************************************************************

function tgAvlTree.tNode.Next(): tNode;
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

function tgAvlTree.tNode.Previous(): tNode;
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

constructor tgAvlTree.tEnumerator.Create( iTree: tgAvlTree);
   begin
      Tree:=    iTree;
      Node:=    nil;    
   end; // Create()


// ************************************************************************
// * MoveNext()
// ************************************************************************

function tgAvlTree.tEnumerator.MoveNext(): boolean;
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
// * GetCurrent()
// ************************************************************************

function tgAvlTree.tEnumerator.GetCurrent(): V;
   begin
      result:= Node.Value;
   end; // GetCurrent()



// ========================================================================
// = tReverseEnumerator class
// ========================================================================
// ************************************************************************
// * Create() - constructor
// ************************************************************************

constructor tgAvlTree.tReverseEnumerator.Create( iTree: tgAvlTree);
   begin
      Tree:=    iTree;
      Node:=    nil;    
   end; // Create()


// ************************************************************************
// * MoveNext()
// ************************************************************************

function tgAvlTree.tReverseEnumerator.MoveNext(): boolean;
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
// * GenEnumerator()
// ************************************************************************

function tgAvlTree.tReverseEnumerator.GetEnumerator: tReverseEnumerator;
   begin
      result:= self;  
   end; // GetEnumerator()


// ************************************************************************
// * GetCurrent()
// ************************************************************************

function tgAvlTree.tReverseEnumerator.GetCurrent(): V;
   begin
      result:= Node.Value;
   end; // GetCurrent()



// ========================================================================
// = tgAvlTree generic class
// ========================================================================
// ************************************************************************
// * Create() - Constructors
// ************************************************************************

constructor tgAvlTree.Create( iCompare:     tCompareFunction;
                                  iAllowDuplicates: boolean = false);
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

Destructor tgAvlTree.Destroy();
   begin
      RemoveAll;
      inherited Destroy();
   end;


// ************************************************************************
// * RemoveAll() - Remove all the elements from the tree and optionally 
// *               Destroy() the elements.
// ************************************************************************

procedure tgAvlTree.RemoveAll( DestroyElements: boolean);
   begin
      if( MyRoot <> nil) then RemoveSubtree( MyRoot, DestroyElements);
      MyRoot:= nil;
   end; // RemoveAll()


// ************************************************************************
// * FindInsertPosition() - Find the node to which this new iValue will be 
// *                        a child.
// ************************************************************************

function tgAvlTree.FindInsertPosition( iValue: V): tNode;
   var 
      Comp: integer;
   begin
      Result:= MyRoot;
      while( Result <> nil) do begin
         Comp:= MyCompare( iValue, Result.Value);
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

procedure tgAvlTree.Add( iValue: V);
   var 
      InsertPos:   tNode;
      Comp:        integer;
      NewNode:     tNode;
   begin
      NewNode:= tNode.create( iValue);
      inc( MyCount);
      if MyRoot <> nil then begin
         InsertPos:= FindInsertPosition( iValue);
         Comp:= MyCompare( iValue, InsertPos.Value);
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
   end; // TgAvlTree.Add()


// ************************************************************************
// * Remove() - Remove the current node from the tree
// ************************************************************************

procedure tgAvlTree.RemoveCurrent();
   begin
      if( CurrentNode = nil) then begin
         raise lbpContainerException.Create( 'Attempting to delete the current node from the tree when it is empty!');
      end;
      RemoveNode( CurrentNode);
      CurrentNode:=nil;
      dec( MyCount);
   end; // Remove()


// ************************************************************************
// * Remove() - Find a node which contains iValue and remove it.
// ************************************************************************

procedure tgAvlTree.Remove( iValue: V);
   var
      N: tNode;
   begin
      CurrentNode:= nil;
      N:= FindNode( iValue);
      if( N = nil) then begin
         raise lbpContainerException.Create( 'The passed Value was not found in the tree.');
      end;
      RemoveNode( N);
   end; // Remove()


// ************************************************************************
// * Find() - returns true if the passed value is found in the tree
// *          Call Value() to get the found value.
// ************************************************************************

function tgAvlTree.Find( iValue: V): boolean;
   begin
      CurrentNode:= FindNode( iValue);
      result:= (CurrentNode <> nil);
   end; // Find()


// ************************************************************************
// * StartEnumeration() - Prepare for a new enmeration.
// ************************************************************************

procedure tgAvlTree.StartEnumeration();
   begin
      CurrentNode:= nil;
   end; /// StartEnumeration()


// ************************************************************************
// * Previous() - Move to the previous node in the tree and return true if
// *              successful.
// ************************************************************************

function tgAvlTree.Previous(): boolean;
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

function tgAvlTree.Next(): boolean;
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
// * Value() - Return the value of the current node in the tree.True
// ************************************************************************

function tgAvlTree.Value(): V;
   begin
      // Starting a new iteration?
      if( CurrentNode = nil) then begin
         raise lbpContainerException.Create( 'Attempt to access the current tree node''s value outside of an enumeration.');
      end;
      result:= CurrentNode.Value;
   end; /// Value()


// ************************************************************************
// * GetEnumerator()
// ************************************************************************

function tgAvlTree.GetEnumerator(): tEnumerator;
   begin
      result:= tEnumerator.Create( Self);
   end; // GetEnumerator()


// ************************************************************************
// * Reverse() - Gets the reverse order enumerator
// ************************************************************************

function tgAvlTree.Reverse(): tReverseEnumerator;
   begin
      result:= tReverseEnumerator.Create( Self);
   end; // Reverse()


// ************************************************************************
// * DumpNOdes
// ************************************************************************

//  d - b - a
//  |    \- c
//   \- f - e
//       \- g

procedure tgAvlTree.Dump( N:       tNode = nil;
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
      Temp:= MyNodeToString( N.Value);
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
// * FindNode() - Returns a node which contains iValue.  Return nil if no
// *              node is found.  Used internally.
// ************************************************************************

function tgAvlTree.FindNode( iValue: V): tNode;
   var 
      Comp: integer;
   begin
      Result:=MyRoot;
      while( Result <> nil) do begin
        Comp:= MyCompare( iValue, Result.Value);
        if Comp=0 then exit;
        if Comp<0 then begin
            Result:=Result.LeftChild;
         end else begin
            Result:=Result.RightChild;
         end;
      end; // while
   end; // FindNode()


// ************************************************************************
// * RemoveNode() - Remove the passed node from the tree
// ************************************************************************

procedure tgAvlTree.RemoveNode( N: tNode);
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

function tgAvlTree.IsEmpty(): V;
   begin
      result:= (MyCount = 0);
   end; // First()


// ************************************************************************
// * RemoveSubtree() - Helper for RemoveAll
// ************************************************************************

procedure tgAvlTree.RemoveSubtree( StRoot: tNode; DestroyElements: boolean);
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

procedure tgAvlTree.RebalanceAfterAdd( N: tNode);
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

procedure tgAvlTree.RebalanceAfterRemove( N: tNode);
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

procedure tgAvlTree.DestroyValue( Args: array of const);
   begin
      if( Args[ 0].vtype = vtObject) then tObject( Args[ 0].vObject).Destroy();
   end; // DestroyValue;



// ========================================================================
// = tNode generic class
// ========================================================================
// ************************************************************************
// * Create() - constructor
// ************************************************************************
constructor tgDictionary.tNode.Create( iKey: K; iValue: V);
   begin
      Parent:=     nil;
      LeftChild:=  nil;
      RightChild:= nil;
      Balance:=    0;
      Key:=        iKey;
      Value:=      iValue;
   end; // Create()


// ************************************************************************
// * Clear() - Zero out the fields 
// ************************************************************************

procedure tgDictionary.tNode.Clear();
   begin
      Parent:= nil;
      LeftChild:= nil;
      RightChild:= nil;
      Balance:= 0;
      Key:= Default( K);
      Value:= Default( V);
   end; // Clear()

// ************************************************************************
// * TreeDepth() - Returns the depth of this node.
// ************************************************************************

function tgDictionary.tNode.TreeDepth(): integer;
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

function tgDictionary.tNode.First(): tNode;
   begin
      result:= Self;
      while( result.LeftChild <> nil) do result:= result.LeftChild;
   end;


// ************************************************************************
// * Last() - Return the lowest value (rightmost) node of this node's 
// *          subtree. 
// ************************************************************************

function tgDictionary.tNode.Last(): tNode;
   begin
      result:= Self;
      while( result.RightChild <> nil) do result:= result.RightChild;
   end;


// ************************************************************************
// * Next() - Return the next node in the tree
// ************************************************************************

function tgDictionary.tNode.Next(): tNode;
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

function tgDictionary.tNode.Previous(): tNode;
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

constructor tgDictionary.tEnumerator.Create( iTree: tgDictionary);
   begin
      Tree:=    iTree;
      Node:=    nil;    
   end; // Create()


// ************************************************************************
// * MoveNext()
// ************************************************************************

function tgDictionary.tEnumerator.MoveNext(): boolean;
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
// * GetCurrent()
// ************************************************************************

function tgDictionary.tEnumerator.GetCurrent(): V;
   begin
      result:= Node.Value;
   end; // GetCurrent()



// ========================================================================
// = tReverseEnumerator class
// ========================================================================
// ************************************************************************
// * Create() - constructor
// ************************************************************************

constructor tgDictionary.tReverseEnumerator.Create( iTree: tgDictionary);
   begin
      Tree:=    iTree;
      Node:=    nil;    
   end; // Create()


// ************************************************************************
// * MoveNext()
// ************************************************************************

function tgDictionary.tReverseEnumerator.MoveNext(): boolean;
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

function tgDictionary.tReverseEnumerator.GetEnumerator: tReverseEnumerator;
   begin
      result:= self;  
   end; // GetEnumerator()


// ************************************************************************
// * GetCurrent()
// ************************************************************************

function tgDictionary.tReverseEnumerator.GetCurrent(): V;
   begin
      result:= Node.Value;
   end; // GetCurrent()



// ========================================================================
// = tKeyEnumerator class
// ========================================================================
// ************************************************************************
// * Create() - constructor
// ************************************************************************

constructor tgDictionary.tKeyEnumerator.Create( iTree: tgDictionary);
   begin
      Tree:=    iTree;
      Node:=    nil;    
   end; // Create()


// ************************************************************************
// * MoveNext()
// ************************************************************************

function tgDictionary.tKeyEnumerator.MoveNext(): boolean;
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

function tgDictionary.tKeyEnumerator.GetEnumerator: tKeyEnumerator;
   begin
      result:= self;  
   end; // GetEnumerator()


// ************************************************************************
// * GetCurrent()
// ************************************************************************

function tgDictionary.tKeyEnumerator.GetCurrent(): K;
   begin
      result:= Node.Key;
   end; // GetCurrent()



// ========================================================================
// = tReverseKeyEnumerator class
// ========================================================================
// ************************************************************************
// * Create() - constructor
// ************************************************************************

constructor tgDictionary.tReverseKeyEnumerator.Create( iTree: tgDictionary);
   begin
      Tree:=    iTree;
      Node:=    nil;    
   end; // Create()


// ************************************************************************
// * MoveNext()
// ************************************************************************

function tgDictionary.tReverseKeyEnumerator.MoveNext(): boolean;
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

function tgDictionary.tReverseKeyEnumerator.GetEnumerator: tReverseKeyEnumerator;
   begin
      result:= self;  
   end; // GetEnumerator()


// ************************************************************************
// * GetCurrent()
// ************************************************************************

function tgDictionary.tReverseKeyEnumerator.GetCurrent(): K;
   begin
      result:= Node.Key;
   end; // GetCurrent()



// ========================================================================
// = tgDictionary generic class
// ========================================================================
// ************************************************************************
// * Create() - Constructors
// ************************************************************************

constructor tgDictionary.Create( iCompare:     tCompareFunction;
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

Destructor tgDictionary.Destroy();
   begin
      RemoveAll;
      inherited Destroy();
   end;


// ************************************************************************
// * RemoveAll() - Remove all the elements from the tree and optionally 
// *               Destroy() the elements.
// ************************************************************************

procedure tgDictionary.RemoveAll( DestroyElements: boolean);
   begin
      if( MyRoot <> nil) then RemoveSubtree( MyRoot, DestroyElements);
      MyRoot:= nil;
      MyCount:= 0;
   end; // RemoveAll()


// ************************************************************************
// * FindInsertPosition() - Find the node to which this new iKey will be 
// *                        a child.
// ************************************************************************

function tgDictionary.FindInsertPosition( iKey: K): tNode;
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

procedure tgDictionary.Add( iKey: K; iValue: V);
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
              raise lbpContainerException.Create( 'Duplicate key values are not allowed in this dictionary!');
            end;
            // insert to the right
            InsertPos.RightChild:= NewNode;
         end;
         RebalanceAfterAdd( NewNode);
      end else begin
         MyRoot:=NewNode;
      end;
   end; // tgDictionary.Add()


// ************************************************************************
// * Remove() - Remove the current node from the tree
// ************************************************************************

procedure tgDictionary.RemoveCurrent();
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

procedure tgDictionary.Remove( iKey: K);
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

function tgDictionary.Find( iKey: K): boolean;
   begin
      CurrentNode:= FindNode( iKey);
      result:= (CurrentNode <> nil);
   end; // Find()


// ************************************************************************
// * StartEnumeration() - Prepare for a new enmeration.
// ************************************************************************

procedure tgDictionary.StartEnumeration();
   begin
      CurrentNode:= nil;
   end; /// StartEnumeration()


// ************************************************************************
// * Previous() - Move to the previous node in the tree and return true if
// *              successful.
// ************************************************************************

function tgDictionary.Previous(): boolean;
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

function tgDictionary.Next(): boolean;
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

function tgDictionary.Key(): K;
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

function tgDictionary.Value(): V;
   begin
      // Starting a new iteration?
      if( CurrentNode = nil) then begin
         raise lbpContainerException.Create( 'Attempt to access the current tree node''s value outside of an enumeration.');
      end;
      result:= CurrentNode.Value;
   end; /// Value()


// ************************************************************************
// * GetEnumerator()
// ************************************************************************

function tgDictionary.GetEnumerator(): tEnumerator;
   begin
      result:= tEnumerator.Create( Self);
   end; // GetEnumerator()


// ************************************************************************
// * Reverse() - Gets the reverse order enumerator
// ************************************************************************

function tgDictionary.Reverse(): tReverseEnumerator;
   begin
      result:= tReverseEnumerator.Create( Self);
   end; // Reverse()


// ************************************************************************
// * KeyEnum() - Gets the Key enumerator
// ************************************************************************

function tgDictionary.KeyEnum(): tKeyEnumerator;
   begin
      result:= tKeyEnumerator.Create( Self);
   end; // KeyEnum()


// ************************************************************************
// * ReverseKeyEnum() - Gets the reverse order enumerator
// ************************************************************************

function tgDictionary.ReverseKeyEnum(): tReverseKeyEnumerator;
   begin
      result:= tReverseKeyEnumerator.Create( Self);
   end; // Reverse()


// ************************************************************************
// * Dump() - prints the tree for troubleshooting
// ************************************************************************


procedure tgDictionary.Dump( N:       tNode = nil;
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

function tgDictionary.FindNode( iKey: K): tNode;
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

function tgDictionary.FindItem( iKey: K): V;
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

procedure tgDictionary.RemoveNode( N: tNode);
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

function tgDictionary.IsEmpty(): V;
   begin
      result:= (MyCount = 0);
   end; // First()


// ************************************************************************
// * RemoveSubtree() - Helper for RemoveAll
// ************************************************************************

procedure tgDictionary.RemoveSubtree( StRoot: tNode; DestroyElements: boolean);
   begin
      if( StRoot.LeftChild <> nil) then begin
         RemoveSubtree( StRoot.LeftChild, DestroyElements);
      end;
      if( StRoot.RightChild <> nil) then begin 
         RemoveSubtree( StRoot.RightChild, DestroyElements);
      end;
      if( DestroyElements) then DestroyValue( [StRoot.Value]);
      StRoot.Destroy;
      Dec( MyCount);
   end; // RemoveSubtree()


// ************************************************************************
// * RebalanceAfterAdd() - Rebalance the tree after an Add()
// ************************************************************************

procedure tgDictionary.RebalanceAfterAdd( N: tNode);
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

procedure tgDictionary.RebalanceAfterRemove( N: tNode);
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

procedure tgDictionary.DestroyValue( Args: array of const);
   begin
     if( Args[ 0].vtype = vtObject) then tObject( Args[ 0].vObject).Destroy();
   end; // DestroyValue;



// ************************************************************************

end. // lbp_generic_containers unit
