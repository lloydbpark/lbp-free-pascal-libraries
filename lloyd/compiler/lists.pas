{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

The oldest version of my lbp_lists.pas unit

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

{ Lists file                                            Lloyd B. Park  }
{                             January 31, 1992                         }
{                                                                      }
{ This Turbo Pascal code fragment implements double linked lists.      }
{   The code should be 'included' after defining Item_Type.            }
{ NOTE!  Items are added to the list as Item_Ptr's.  It is the         }
{        responsibility of the caller to use new() and dispose() to    }
{        to create and destroy Item_Type variables.                    }

type
   ListNodePtr = ^ListNodeType;
   ListNodeType = record
         Item:    Item_Ptr;
         Prev:    ListNodePtr;
         Next:    ListNodePtr;
      end; { ListNodeType }

   List_Type = record
         FirstNode:   ListNodePtr;
         LastNode:    ListNodePtr;
         CurrentNode: ListNodePtr;
         Count:       integer;
      end; { List_Type }

{ ******************************************************************** }

procedure Initialize( var L: List_Type);
   { Sets a new list to the empty state }
   begin
      L.FirstNode:=   nil;
      L.LastNode:=    nil;
      L.CurrentNode:= nil;
      L.Count:=       0;
   end; { Initialize }

{ ******************************************************************** }

function Empty( var L: List_Type): boolean;
   { True if the list is empty }
   begin
      if (L.FirstNode = nil) then begin
         Empty:= true
      end
      else begin
         Empty:= false;
      end;
   end; { Empty }

{ ******************************************************************** }

function First( var L: List_Type): boolean;
   { True if the current item is first }
   begin
      if Empty( L) then begin
         First:= false;
      end
      else if (L.CurrentNode = L.FirstNode) then begin
         First:= true;
      end
      else begin
         First:= False;
      end;
   end; { First }

{ ******************************************************************** }

function Last( var L: List_Type): boolean;
   { True if the current item is last }
   begin
      if Empty( L) then begin
         Last:= false;
      end
      else if (L.CurrentNode = L.LastNode) then begin
         Last:= true;
      end
      else begin
         Last:= false;
      end;
   end; { Last }

{ ******************************************************************** }

procedure Push( Item: Item_Ptr; var L: List_Type);
   { Add item to the tail of the list.            }
   { CurrentNode is left pointing to item's node. }

   var
      N: ListNodePtr;

   begin
      new( N);
      L.Count:= L.Count + 1;
      N^.Item:= Item;
      N^.Next:= nil;
      if Empty( L) then begin
         N^.Prev:= nil;
         L.FirstNode:= N;
      end
      else begin
         L.LastNode^.Next:= N;
         N^.Prev:= L.LastNode;
      end;
     L.LastNode:= N;
     L.CurrentNode:= N;
   end; { Push }

{ ******************************************************************** }

function Pop( var L: List_Type): Item_Ptr;
   { Return and remove item from the tail of the list.         }
   { CurrentNode is left pointing to the new tail of the list. }
   var
      N:    ListNodePtr;
   begin
      if not Empty( L) then begin
         L.Count:= L.Count - 1;
         N:= L.LastNode;

         { Adjust Pointers }
         { If N was the only element in the list }
         if L.FirstNode = L.LastNode then begin
            L.LastNode:=  nil;
            L.FirstNode:= nil;
         end
         else begin
            L.LastNode^.Prev^.Next:= nil;
            L.LastNode:= L.LastNode^.Prev;
         end;
         Pop:= N^.Item;
         dispose( N);
         L.CurrentNode:= L.LastNode;
      end { if not empty }
      else begin { if empty }
         Pop:= nil;
      end;
   end; { Pop }

{ ******************************************************************** }

procedure Enqueue( Item: Item_Ptr; var L: List_Type);
   { Add item to the tail of the list.            }
   { CurrentNode is left pointing to item's node. }
   begin
      Push( Item, L);
   end; { Enqueue }

{ ******************************************************************** }

function DeQueue( var L: List_Type): Item_Ptr;
   { Return and remove item from the head of the list }
   { CurrentNode is left pointing at the new head     }

   var
      N:    ListNodePtr;

   begin
      if Empty( L) then begin
         DeQueue:= nil;
      end
      else begin { not empty }
         L.Count:= L.Count - 1;
         N:= L.FirstNode;
         { Adjust Pointers }
         { If only one element in list }
         if L.FirstNode = L.LastNode then begin
            L.LastNode:= nil;
            L.FirstNode:=nil;
         end
         else begin
            L.FirstNode^.Next^.Prev:= nil;
            L.FirstNode:= L.FirstNode^.Next;
         end;
         Dequeue:= N^.Item;
         dispose( N);
         L.CurrentNode:= L.FirstNode;
      end; { if not empty }
   end; { DeQueue }

{ ******************************************************************** }

procedure AddFront( Item: Item_Ptr; var L: List_Type);
   { Add item to the head of the list.            }
   { CurrentNode is left pointing to item's node. }
   var
      N: ListNodePtr;

   begin
      new( N);
      L.Count:= L.Count + 1;
      N^.Item:= Item;
      N^.Prev:= nil;
      if Empty( L) then begin
         N^.Next:= nil;
         L.LastNode:= N;
      end
      else begin
         L.FirstNode^.Prev:= N;
         N^.Next:= L.FirstNode;
      end;
     L.FirstNode:= N;
     L.CurrentNode:= L.FirstNode;
   end; { AddFront }

{ ******************************************************************** }

procedure InsertBeforeCurrent( Item: Item_Ptr; var L: List_Type);
   { Inserts Item in the list before the current item; }
   var
      N: ListNodePtr;

   begin
      if Empty( L) or First( L) then begin
         AddFront( Item, L);
      end
      else begin { There is a node in front of the current node }
         new( N);
         N^.Item:= Item;
         L.Count:= L.Count + 1;
         { Insert N in between the node in front of current and current }
         N^.Next:= L.CurrentNode;
         N^.Prev:= L.CurrentNode^.Prev;
         N^.Prev^.Next:= N;
         N^.Next^.Prev:= N;
         L.CurrentNode:= N;         
      end;
   end; { InsertBeforeCurrent }

{ ******************************************************************** }

procedure InsertAfterCurrent( Item: Item_Ptr; var L: List_Type);
   { Inserts Item in the list After the current item }
   var
      N: ListNodePtr;
   begin
      if Empty( L) or Last( L) then begin
         Push( Item, L); { Add to tail }
      end
      else begin { There is a node after the current node }
         new( N);
         N^.Item:= Item;
         L.Count:= L.Count + 1;
         { Insert N in between the node after the current and current }
         N^.Next:= L.CurrentNode^.Next;
         N^.Prev:= L.CurrentNode;
         N^.Prev^.Next:= N;
         N^.Next^.Prev:= N;
         L.CurrentNode:= N;
      end;
   end; { InsertAfterCurrent }

{ ******************************************************************** }

function GetCurrent( var L: List_Type): Item_Ptr;
   { Returns the item at the current node }
   begin
      if Empty( L) then begin
         GetCurrent:= nil;
      end
      else begin
         GetCurrent:= L.CurrentNode^.Item;
      end;
   end; { GetCurrent }

{ ******************************************************************** }

function GetFirst( var L: List_Type): Item_Ptr;
   { Returns the first item in the list }
   begin
      if Empty( L) then begin
         GetFirst:= nil;
      end
      else begin
         L.CurrentNode:= L.FirstNode;
         GetFirst:= L.FirstNode^.Item;
      end;
   end; { GetFirst }

{ ******************************************************************** }

function GetLast( var L: List_Type): Item_Ptr;
   { Returns the last item in the list }
   begin
      if Empty( L) then begin
         GetLast:= nil;
      end
      else begin
         L.CurrentNode:= L.LastNode;
         GetLast:= L.LastNode^.Item;
      end;
   end; { GetLast }

{ ******************************************************************** }

function GetNext( var L: List_Type): Item_Ptr;
   { Returns the next item in the list }
   begin
      if Empty( L) then begin
         GetNext:= nil;
      end
      else if (L.CurrentNode^.Next = nil) then begin
         GetNext:= nil;
      end
      else begin
         L.CurrentNode:= L.CurrentNode^.Next;
         GetNext:= L.CurrentNode^.Item;
      end;
   end; { GetNext }

{ ******************************************************************** }

function GetPrev( var L: List_Type): Item_Ptr;
   { Returns the previous item in the list }
   begin
      if Empty( L) then begin
         GetPrev:= nil;
      end
      else if (L.CurrentNode^.Prev = nil) then begin
         GetPrev:= nil;
      end
      else begin
         L.CurrentNode:= L.CurrentNode^.Prev;
         GetPrev:= L.CurrentNode^.Item;
      end;
   end; { GetPrev }

{ ******************************************************************** }

function GetIndexed( index: integer; var L: List_Type): Item_Ptr;
   { Returns the index th item in the list.  The first item is 1. }
   var
      i:    integer;
      Temp: Item_Ptr;
   begin
      i:= 1;
      if (index < 1) then begin
         GetIndexed:= nil;
      end
      else begin
         Temp:= GetFirst( L);
         while (i < index) do begin
            Temp:= GetNext( L);
            inc( i);
         end;
         GetIndexed:= Temp;
      end;
   end; { GetIndexed }

{ ******************************************************************** }

function Remove( var L: List_Type): Item_Ptr;
   { Removes and returns the current item      }
   { CurrentNode is set to the new L.FirstNode }
   var
      N:    ListNodePtr;
      Temp: Item_Type;
   begin
      if Empty( L) then begin
         Remove:= nil;
      end
      else begin { not empty }
         N:= L.CurrentNode;
         L.Count:= L.Count - 1;
         { Adjust Pointers }
         if N^.Next = nil then begin
            L.LastNode:= N^.Prev;
         end
         else begin
            N^.Next^.Prev:= N^.Prev;
         end;
         if N^.Prev = nil then begin
            L.FirstNode:= N^.Next;
         end
         else begin
            N^.Prev^.Next:= N^.Next;
         end;

         Remove:= N^.Item;
         dispose( N);
         L.CurrentNode:= L.FirstNode;
      end; { if not empty }
   end; { Remove }


{ ******************************************************************** }

procedure Replace( Item: Item_Ptr; var L: List_Type);
   { Replaces the current item in L with Item }
   { CurrentNode is set to the new FirstNode  }
   begin
      if not Empty( L) then begin
         dispose( L.CurrentNode^.Item);
         L.CurrentNode^.Item:= Item;
      end;
   end; { Replace }

{ ******************************************************************** }

function Number_Of_Items( var L: List_Type): integer;
   { Returns the number of items in the list.  0 if empty. }
   begin
      Number_Of_Items:= L.Count;
   end; { Number_Of_Items }

{ ******************************************************************** }

