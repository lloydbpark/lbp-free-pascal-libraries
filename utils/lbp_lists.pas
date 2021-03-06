{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Classes to hold linked lists

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

unit lbp_Lists;
// Creates generic lists of pointers to items.
//
// Push and Enqueue do the same thing, add to the end of the list.
//    AddToFront does the oposite.
// Pop removes from the end of the list
// Dequeue removes from the beginning of the list.

interface

{$include lbp_standard_modes.inc}
//{$V-}    //Added by LP because it says so below
//{$R-}    //Range checking off
//{$S-}    //Stack checking off
//{$I-}    //I/O checking off
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   sysutils,       // Exceptions
   lbp_types,     // int32
   lbp_vararray;  // Int64SortElement


// ************************************************************************

   type
      // Used to implement a double linked lists of pointers
      ListNodePtr = ^ListNodeType;
      ListNodeType = record
         Item:    pointer;
         Prev:    ListNodePtr;
         Next:    ListNodePtr;
      end;


// ************************************************************************

      DoubleLinkedListException = class( Exception);
      DoubleLinkedList = class // A class is always a pointer.
         public
            Name:          String;
         private
            FirstNode:     ListNodePtr;
            LastNode:      ListNodePtr;
            CurrentNode:   ListNodePtr;
            ListLength:    Int32;
         public
            constructor    Create;
            constructor    Create( const iName: String);
            destructor     Destroy; override;
            procedure      Push( MyPointer: pointer); virtual; // Add to back
            procedure      AddFront( MyPointer: Pointer); virtual; // Add to front
            procedure      Enqueue( MyPointer: Pointer); virtual; // Add to back
            procedure      InsertBeforeCurrent( MyPointer: pointer); virtual;
            procedure      InsertAfterCurrent( MyPointer: pointer); virtual;
            function       Pop():      pointer; virtual;       // Remove from back
            function       DeQueue():  pointer; virtual;       // Remove from front
            procedure      Replace( OldPointer, NewPointer: pointer); virtual;
            procedure      Replace( NewPointer: pointer); virtual;
            procedure      Remove( MyPointer: pointer); virtual;
            procedure      Remove(); virtual;
            procedure      RemoveAll( DestroyElements: boolean = false); virtual; // Remove all elements from the list.
            function       Empty():    boolean; virtual;
            function       First():    boolean; virtual; // True if CurrentNode is First
            function       Last():     boolean; virtual;
            function       GetCurrent(): pointer; virtual; // Returns the data pointer at CurrentNode
            function       GetFirst(): pointer; virtual;
            function       GetLast():  pointer; virtual;
            function       GetNext():  pointer; virtual;
            function       GetPrev():  pointer; virtual;
            function       Length():   Int32;   virtual;
      end; // Double Linked List


// ************************************************************************

   Int64SortElementList = class( DoubleLinkedList)
      private
         DuplicatesAllowed: boolean;
      public
         constructor    Create( iDuplicatesAllowed: boolean);
         constructor    Create( iDuplicatesAllowed: boolean;
                                const iName: String);
         procedure Insert( IE: Int64SortElement);
      end; // Int64SortElementList


// ************************************************************************

implementation

// ************************************************************************
// * Constructors
// ************************************************************************

constructor DoubleLinkedList.Create;
  // Makes a new and empty  List
  begin
     FirstNode:= Nil;
     LastNode:= Nil;
     CurrentNode:= Nil;
     Name:= 'Unknown';
     ListLength:= 0;
  end; // Create()

// ------------------------------------------------------------------------

constructor DoubleLinkedList.Create( const iName: String);
  // Makes a new and empty List
  begin
     FirstNode:= Nil;
     LastNode:= Nil;
     CurrentNode:= Nil;
     Name:= iName;
     ListLength:= 0;
  end; // Create()


// ************************************************************************
// * Destructor
// ************************************************************************

destructor DoubleLinkedList.Destroy;

   begin
      if( not Empty) then begin
         Raise DoubleLinkedListException.Create(
            'List ' + Name + ' is not empty and can not be destroyed!');
      end;
   end; // Destroy();


// ************************************************************************
// * Push() - Adds the object to the end of the list.
// *          Pushes an object on the stack.
// ************************************************************************

procedure DoubleLinkedList.Push( MyPointer: pointer);
   var N: ListNodePtr;

   begin
//      writeln( 'DoubleLinkedList.Push():  Pushing address ', int32( MyPointer), ' onto ', Name);
      new( N);
      N^.Item:= MyPointer;
      N^.Next:= Nil;
      if Empty then begin
         N^.Prev:= Nil;
         FirstNode:= N;
      end
      else begin
         LastNode^.Next:= N;
         N^.Prev:= LastNode;
      end;
     LastNode:= N;
     CurrentNode:= FirstNode;
     ListLength += 1;
   end; // Push()


// ************************************************************************
// * AddFront()  - Adds an Object to the front of the list
// ************************************************************************

procedure DoubleLinkedList.AddFront(MyPointer: pointer);
   var N: ListNodePtr;

   begin
      new(N);
      N^.Item:= MyPointer;
      N^.Prev:= Nil;
      if Empty then begin
         N^.Next:= Nil;
         LastNode:= N;
      end
      else begin
         FirstNode^.Prev:= N;
         N^.Next:= FirstNode;
      end;
     FirstNode:= N;
     CurrentNode:= FirstNode;
     ListLength += 1;
   end; // AddFront()


// ************************************************************************
// * Enqueue()  - Adds an Object to the end of the list (Same as Push())
// ************************************************************************

procedure DoubleLinkedList.Enqueue( MyPointer: pointer);
   begin
      Push( MyPointer);
   end; // Enqueue()


// ************************************************************************
// * InsertBeforeCurrent()  - Places an object in the list in front
// *                          of the current object.
// ************************************************************************

procedure DoubleLinkedList.InsertBeforeCurrent( MyPointer: pointer);
   var
      N:  ListNodePtr;
   begin
      if Empty or First then begin
         AddFront( MyPointer);
      end
      else begin // There is a node in front of the current node
         new( N);
         N^.Item:= MyPointer;
         // Insert N in between the node in front of current and current
         N^.Next:= CurrentNode;
         N^.Prev:= CurrentNode^.Prev;
         N^.Prev^.Next:= N;
         N^.Next^.Prev:= N;
         CurrentNode:= N;
         ListLength += 1;
      end;
   end; // InsertBeforeCurrent()


// ************************************************************************
// * InsertAfterCurrent()  - Places an object in the list behind
// *                         the current object.
// ************************************************************************

procedure DoubleLinkedList.InsertAfterCurrent( MyPointer: pointer);
   var
      N:  ListNodePtr;
   begin
      if Empty or Last then begin
         Push( MyPointer);  // Add to tail
      end
      else begin // There is a node after the current node
         new( N);
         N^.Item:= MyPointer;
         // Insert N in between the node after the current and current
         N^.Next:= CurrentNode^.Next;
         N^.Prev:= CurrentNode;
         N^.Prev^.Next:= N;
         N^.Next^.Prev:= N;
         CurrentNode:= N;
         ListLength += 1;
      end;
   end; // InsertAfterCurrent()


// ************************************************************************
// * Pop()  - Returns the last element in the list.
// *          Pop an element off the stack.
// ************************************************************************

function DoubleLinkedList.Pop: pointer;
   var
      N: ListNodePtr;
   begin
      if Empty then Pop:= Nil
      else begin
         N:= LastNode;
         // Adjust Pointers
         // If only one element in list
         if FirstNode = LastNode then begin
            LastNode:= Nil;
            FirstNode:=Nil;
         end
         else begin
            LastNode^.Prev^.Next:= Nil;
            LastNode:= LastNode^.Prev;
         end;
         Pop:= N^.Item;
//         writeln( 'DoubleLinkedList.Pop():  Popping address ', int32( N^.Item), ' off of ', Name);

         dispose(N);
         ListLength -= 1;
      end; // if Empty
      CurrentNode:= LastNode;
   end;  // Pop()


// ************************************************************************
// * Replace()  - Replaces the first occurance of OldObj with NewObj.
// ************************************************************************

procedure DoubleLinkedList.Replace( OldPointer, NewPointer: pointer);
   var
      N: ListNodePtr;
   begin
      if Empty then Exit
      else begin
         // Find the node
         N:= FirstNode;
         while (N <> nil) and (N^.Item <> OldPointer) do
            N:= N^.Next;
         if (N <> nil) then begin
            N^.Item:= NewPointer;
         end;
         CurrentNode:= N;
      end;
   end; // DoubleLinkedList.Replace


// ------------------------------------------------------------------------

procedure DoubleLinkedList.Replace( NewPointer: pointer);
   begin
      if( CurrentNode <> nil) then begin
         CurrentNode^.Item:= NewPointer;
      end;
   end; // Replace()


// ************************************************************************
// * Remove()  - Removes the first occurance of Obj in the list.
// ************************************************************************

procedure DoubleLinkedList.Remove( MyPointer: pointer);
   var
      N: ListNodePtr;
   begin
      if Empty then exit
      else begin
         // Find the node
         N:= FirstNode;
         while (N <> nil) and (N^.Item <> MyPointer) do
            N:= N^.Next;
         if (N = nil) then exit;

         // Adjust Pointers
         if N^.Next = Nil then LastNode:= N^.Prev
         else N^.Next^.Prev:= N^.Prev;
         if N^.Prev = Nil then FirstNode:= N^.Next
         else N^.Prev^.Next:= N^.Next;
         dispose(N);
         ListLength -= 1;
      end; // else not Empty
      CurrentNode:= LastNode;
   end;  // Remove ()


// ------------------------------------------------------------------------

procedure DoubleLinkedList.Remove();
   begin
      if (CurrentNode = nil) then exit;

      // Adjust Pointers
      if CurrentNode^.Next = Nil then LastNode:= CurrentNode^.Prev
      else CurrentNode^.Next^.Prev:= CurrentNode^.Prev;
      if CurrentNode^.Prev = Nil then FirstNode:= CurrentNode^.Next
      else CurrentNode^.Prev^.Next:= CurrentNode^.Next;
      dispose(CurrentNode);
      ListLength -= 1;
      CurrentNode:= LastNode;
   end;  // Remove()


// ************************************************************************
// * RemoveAll()  - Removes all elements from the list.  It is up to the
// *                user to make sure each element is properly discarded.
// *                If DestroyElements is true, it is assumed each element
// *                is an instance of some class.
// ************************************************************************

procedure DoubleLinkedList.RemoveAll( DestroyElements: boolean = false);
   var
      E: tObject;
   begin
      while( not Empty()) do begin
         E:= tObject( Dequeue());
         if( DestroyElements) then E.Destroy();
      end;
   end; // RemoveAll()


// ************************************************************************
// * Dequeue()  - Returns the first element in the list.
// *              Removes an element from the queue.
// ************************************************************************

function DoubleLinkedList.Dequeue(): pointer;
   var
      N: ListNodePtr;
   begin
      if Empty then begin
         Dequeue:= Nil;
      end
      else begin
         N:= FirstNode;
         // Adjust Pointers
         // If only one element in list
         if FirstNode = LastNode then begin
            LastNode:= Nil;
            FirstNode:=Nil;
         end
         else begin
            FirstNode^.Next^.Prev:= Nil;
            FirstNode:= FirstNode^.Next;
         end;
         Dequeue:= N^.Item;
         dispose(N);
         ListLength -= 1;
      end; // if Empty
      CurrentNode:= LastNode;
   end;  // Dequeue()


// ************************************************************************
// * Empty()  - Returns true if the list is empty
// ************************************************************************

function DoubleLinkedList.Empty(): boolean;
   // Tests to see if the list is empty
   begin
     Empty:= (FirstNode = NIL);
   end; // Empty()


// ************************************************************************
// * First()  - Returns true if the current item is also first
// ************************************************************************

function DoubleLinkedList.First(): boolean;
   begin
     First:= (not Empty) and (CurrentNode = FirstNode);
   end; // First()


// ************************************************************************
// * Last()  - Returns true if the current item is also last
// ************************************************************************

function DoubleLinkedList.Last(): boolean;
   begin
     Last:= (not Empty) and (CurrentNode = LastNode);
   end; // Last()


// ************************************************************************
// * GetCurrent()  - Returns the current item in the list.
// *                 Does not remove it from the list.
// ************************************************************************

function DoubleLinkedList.GetCurrent(): pointer;
   begin
      if CurrentNode = nil then
         GetCurrent:= nil
      else
         GetCurrent:= CurrentNode^.Item;
   End; // GetCurrent()


// ************************************************************************
// * GetFirst()  - Returns the first item in the list.
// *               Does not remove it from the list.
// ************************************************************************

function DoubleLinkedList.GetFirst(): pointer;
   begin
      CurrentNode:= FirstNode;
      If FirstNode= nil then
         GetFirst:= nil
      else
         GetFirst:= CurrentNode^.Item;
   End; // GetFirst()

// ************************************************************************
// * GetLast()  - Returns the last item in the list.
// *               Does not remove it from the list.
// ************************************************************************

function DoubleLinkedList.GetLast(): pointer;
   begin
      CurrentNode:= LastNode;
      if LastNode = nil then
         GetLast:= nil
      else
         GetLast:= CurrentNode^.Item;
   End; // GetLast()


// ************************************************************************
// * GetNext()  - Returns the next item in the list.
// *               Does not remove it from the list.
// ************************************************************************

function DoubleLinkedList.GetNext(): pointer;
   begin
      if CurrentNode^.Next <> Nil then begin
         CurrentNode:= CurrentNode^.Next;
         GetNext:= CurrentNode^.item;
      end
      else GetNext:= Nil
   End; // GetNext()


// ************************************************************************
// * GetPrev()   - Returns the previous item in the list.
// *               Does not remove it from the list.
// ************************************************************************

function DoubleLinkedList.GetPrev(): pointer;
   begin
      if CurrentNode^.Prev <> Nil then begin
         CurrentNode:= CurrentNode^.Prev;
         GetPrev:= CurrentNode^.item;
      end
      else GetPrev:= Nil
   End; // GetPrev()


// ************************************************************************
// * length()    - Returns the number of elements in the list.
// ************************************************************************

function DoubleLinkedList.Length(): Int32;
   begin
      Length:= ListLength;
   end; // Length()


// =========================================================================
// = Int64SortElementList - A list of info elements.
// =========================================================================
// ************************************************************************
// * Constructors
// ************************************************************************

constructor Int64SortElementList.Create( iDuplicatesAllowed: boolean);
  begin
     inherited Create();
     DuplicatesAllowed:= iDuplicatesAllowed;
  end; // Create()

// ------------------------------------------------------------------------

constructor Int64SortElementList.Create( iDuplicatesAllowed: boolean;
                                         const iName: String);
  begin
     inherited Create( iName);
     DuplicatesAllowed:= iDuplicatesAllowed;
  end; // Create()


// *************************************************************************
// * Insert() - Insert the new element in sorted order.
// *************************************************************************

procedure Int64SortElementList.Insert( IE: Int64SortElement);
   var
      Temp:  Int64SortElement;
   begin
      Temp:= Int64SortElement( GetFirst());
      while( (Temp <> nil) and (Temp.SortValue < IE.SortValue)) do begin
         Temp:= Int64SortElement( GetNext());
      end;

      if( Temp = nil) then begin
         Enqueue( IE);
      end else begin

         // Check for duplicates
         if( (not DuplicatesAllowed) and
             (Temp.SortValue = IE.SortValue)) then begin
            exit;
         end;

         InsertBeforeCurrent( IE);
      end;
   end; // Insert()


// ************************************************************************

end. // lbp_lists unit
