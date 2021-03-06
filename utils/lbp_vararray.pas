{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Variable length arrays implemented as classes

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

unit lbp_vararray;
// This was created years ago before Free Pascal had variable length
// arrays.  Any code using this needs updated.


interface

{$include lbp_standard_modes.inc}

uses
   lbp_types,
   SysUtils;    // Format() function - an sprintf() like function

// ************************************************************************

type
   ArrayException = class( lbp_exception);


// ========================================================================

type
   BigByteArrayPtr = ^BigByteArray;
   BigByteArray = Array[ 0..(High( int16))] of byte;

   // The Maximum size is rounded up to multiples of MemBlockSize.
   // If MemBlockSize is 32, then a MaximumSize of 3 will be rounded to 32
   // and Indexes from 0 to 31 will be valid.

   // StartingSize is the initial amount of memory allocated.  You can't access
   // any element until you store a value in that element or into a higher
   // indexed element.
   ByteArray = class
      protected
         A:                 BigByteArrayPtr;
         MemoryUsed:        int32;   // How many bytes were assigned
         MaxSize:           int32;   // The maximum 'length' to which the
                                        // array will be allowd to grow.
         MaxUsed:           int32;    // The maximum index used
         function           iGet( i: int32): byte; virtual;
         procedure          iSet( i: int32; X: byte); virtual;
         procedure          Resize( NewIndex: int32); virtual;
         procedure          SetMaxUsed( i: int32); virtual;
      public
         constructor Create();
         constructor Create( StartingSize: int32);
         constructor Create( StartingSize: int32; MaximumSize: int32);
         destructor  Destroy(); override;
         procedure   Clear(); virtual;
         property    UpperBound: int32 read MaxUsed write SetMaxUsed;
         property    Value[ i: int32]: byte read iGet write iSet; default;
      end;


// ========================================================================

type
   BigWord32ArrayPtr = ^BigWord32Array;
   BigWord32Array = Array[ 0..(High( word16))] of Word32;

   Word32Array = class
      private
         A:                 BigWord32ArrayPtr;
         BytesAllocated:    int32;   // How much storage are we currently
                                       // allocated.
         ElementsAllocated: int32;   // How many elements will our current
                                       // allocation support?
         MaxSize:           int32;   // The maximum 'length' to which the
                                        // array will be allowd to grow.
         MaxUsed:           int32;    // The maximum index used
         function           iGet( i: int32): Word32; virtual;
         procedure          iSet( i: int32; X: Word32); virtual;
         procedure          Resize( NewIndex: int32); virtual;
         procedure          SetMaxUsed( i: int32); virtual;
      public
         constructor Create();
         constructor Create( StartingSize: int32);
         constructor Create( StartingSize: int32; MaximumSize: int32);
         destructor  Destroy(); override;
         procedure   Clear(); virtual;
         property    UpperBound: int32 read MaxUsed write SetMaxUsed;
         property    Value[ i: int32]: Word32 read iGet write iSet; default;
      end;


// ========================================================================

type
   BigWord64ArrayPtr = ^BigWord64Array;
   BigWord64Array = Array[ 0..(High( word16))] of word64;

   Word64Array = class
      private
         A:                 BigWord64ArrayPtr;
         BytesAllocated:    int32;   // How much storage are we currently
                                       // allocated.
         ElementsAllocated: int32;   // How many elements will our current
                                       // allocation support?
         MaxSize:           int32;   // The maximum 'length' to which the
                                        // array will be allowd to grow.
         MaxUsed:           int32;    // The maximum index used
         StackPos:          int32;
         function           iGet( i: int32): word64; virtual;
         procedure          iSet( i: int32; X: word64); virtual;
         procedure          Resize( NewIndex: int32); virtual;
         procedure          SetMaxUsed( i: int32); virtual;
      public
         constructor Create();
         constructor Create( StartingSize: int32);
         constructor Create( StartingSize: int32; MaximumSize: int32);
         destructor  Destroy(); override;
         procedure   Clear(); virtual;

         // Stack procedures
         function    StackEmpty(): boolean;
         procedure   Push( x: word64);
         function    Pop(): word64;

         property    UpperBound: int32 read MaxUsed write SetMaxUsed;
         property    Value[ i: int32]: word64 read iGet write iSet; default;
      end;


// ========================================================================

type
   BigPointerArrayPtr = ^BigPointerArray;
   BigPointerArray = Array[ 0..(High( word16))] of Pointer;

   PointerArray = class
      private
         A:                 BigPointerArrayPtr;
         BytesAllocated:    int32;   // How much storage are we currently
                                       // allocated.
         ElementsAllocated: int32;   // How many elements will our current
                                       // allocation support?
         MaxSize:           int32;   // The maximum 'length' to which the
                                        // array will be allowd to grow.
         MaxUsed:           int32;    // The maximum index used
         function           iGet( i: int32): Pointer; virtual;
         procedure          iSet( i: int32; X: Pointer); virtual;
         procedure          Resize( NewIndex: int32); virtual;
         procedure          SetMaxUsed( i: int32); virtual;
      public
         constructor Create();
         constructor Create( StartingSize: int32);
         constructor Create( StartingSize: int32; MaximumSize: int32);
         destructor  Destroy(); override;
         procedure   Clear(); virtual;
         property    UpperBound: int32 read MaxUsed write SetMaxUsed;
         property    Value[ i: int32]: Pointer read iGet write iSet; default;
      end;

   ObjectArray = PointerArray;


// ========================================================================

   // Used to create arrays which can be sorted.
   Int64SortElement = class
      public
         SortValue:   Int64;
         constructor  Create( iSortValue: Int64);
         destructor   Destroy(); override;
      end; // Int64SortElement


// ************************************************************************

// Use with care!  Assumes the PointerArray contains nothing but
// Int64SortElements or child classes
procedure SortInfoArray( A: PointerArray);
function LookupInInfoArray( KeyValue: int64; A: PointerArray): Int64SortElement;
function LookupInInfoArray( KeyValue:   int64;
                            A:          PointerArray;
                            FirstIndex: int32;
                            LastIndex:  int32): Int64SortElement;


// ************************************************************************

implementation

const
   MemBlockSize: int32 = 32;

// ========================================================================
// = ByteArray
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor ByteArray.Create();
   begin
      Create( -1, High( int32));
   end;


// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor ByteArray.Create( StartingSize: int32);
   begin
      Create( StartingSize, High( int32));
   end; // Create()


// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor ByteArray.Create( StartingSize: int32; MaximumSize: int32);
   begin
      A:= nil;
      if( MaximumSize < MemBlockSize) then begin
         MaximumSize:= MemBlockSize;
      end;
      MaxSize:= MaximumSize;

      if( StartingSize > 0) then begin
         if( (StartingSize < MemBlockSize)) then begin
            StartingSize:= MemBlockSize;
         end;

         if( MaximumSize < StartingSize) then begin
            raise ArrayException.Create(
               'Array''s initial size is out of bounds!');
         end;

         Resize( StartingSize - 1);
      end;
      MaxUsed:= -1;

   end; // Create()


// ************************************************************************
// * Destroy() - Destructor
// ************************************************************************

destructor ByteArray.Destroy();
   begin
      if( A <> nil) then begin
         FreeMem( A);
      end;
   end; // Destroy()



// ************************************************************************
// * Clear() - Deallocate memory used by the array and set it's UpperBound
// *           to -1.
// ************************************************************************

procedure ByteArray.Clear();
   begin
      MaxUsed:= -1;

      if( A <> nil) then begin
         FreeMem( A);
      end;
   end; // Clear()


// ************************************************************************
// * Resize() - Make the array bigger if needed
// ************************************************************************

procedure ByteArray.Resize( NewIndex: int32);
   var
      BlocksNeeded: int32;
      BytesNeeded:  int32;
      NewSize:      int32;
      Temp:         BigByteArrayPtr;
   begin
      // Figure out how much to allocate
      NewSize:= NewIndex + 1;
      BlocksNeeded:= NewSize div MemBlockSize;
      if( (NewSize mod MemBlockSize) > 0) then begin
         inc( BlocksNeeded);
      end;
      BytesNeeded:= BlocksNeeded * MemBlockSize;

      // Is this bigger than the maximum we want to allow?
      if( BytesNeeded - MemBlockSize >= MaxSize) then begin
         raise ArrayException.Create( 'Array index is out of bounds!');
      end;

      // Allocate the memory
      GetMem( Temp, BytesNeeded);
      if( Temp = nil) then begin
         raise ArrayException.Create( 'Out of heap for array creation!');
      end;
      FillByte( Temp^, BytesNeeded, 0);

      // Move the old data into the new array
      if( A <> nil) then begin
         move( A^, Temp^, MemoryUsed);
         FreeMem( A);
      end;
      A:= Temp;

      MemoryUsed:= BytesNeeded;
   end;  // Resize()


// ************************************************************************
// * SetMaxUsed - Sets the Upper Bound of the array to a new value without
// *              resizing the physical storage.  The passed value must be
// *              between -1 and the current UpperBound.
// ************************************************************************

procedure ByteArray.SetMaxUsed( i: int32);
   var
      Temp: string;
   begin
      Temp:= '';
      if( (i < -1) or (i > MaxUsed)) then begin
         Str( MaxUsed, Temp);
         raise ArrayException.Create(
               'Attempted to set UpperBound out of range (-1 - ' +
               Temp + ')!');
      end;
      MaxUsed:= i;
   end; // SetMaxUsed()


// ************************************************************************
// * iGet() - Return an element in the array
// ************************************************************************

function ByteArray.iGet( i: int32): byte;
   begin
      if( (i >= MemoryUsed) or (i > MaxUsed) or ( i < 0)) then begin
         raise ArrayException.Create( 'Array index is out of bounds!');
      end;

      iGet:= A^[ i];
   end; // iGet()



// ************************************************************************
// * iSet() - Set the (i)th element of the array.
// ************************************************************************

procedure ByteArray.iSet( i: int32; X: byte);
   begin
      if( i < 0) then begin
         raise ArrayException.Create( 'Array index is out of bounds!');
      end;

      // Get more storage if we have exceeded our current storage.
      if( i >= MemoryUsed) then begin
         Resize( i);
      end;

      if( i > MaxUsed) then begin
         MaxUsed:= i;
      end;

      A^[ i]:= X;
   end; // iSet()



// ========================================================================
// = Word32Array
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor Word32Array.Create();
   begin
      Create( -1, High( int32));
   end;


// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor Word32Array.Create( StartingSize: int32);
   begin
      Create( StartingSize, High( int32));
   end; // Create()


// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor Word32Array.Create( StartingSize: int32; MaximumSize: int32);
   begin
      if( MaximumSize < MemBlockSize) then begin
         MaximumSize:= MemBlockSize;
      end;
      MaxSize:= MaximumSize;

      if( StartingSize > 0) then begin
         if( (StartingSize < MemBlockSize)) then begin
            StartingSize:= MemBlockSize;
         end;

         if( MaximumSize < StartingSize) then begin
            raise ArrayException.Create(
               'Array''s initial size is out of bounds!');
         end;

         Resize( StartingSize - 1);
      end;
      MaxUsed:= -1;

   end; // Create()


// ************************************************************************
// * Destroy() - Destructor
// ************************************************************************

destructor Word32Array.Destroy();
   begin
      if( A <> nil) then begin
         FreeMem( A);
      end;
   end; // Destroy()



// ************************************************************************
// * Clear() - Deallocate memory used by the array and set it's UpperBound
// *           to -1.
// ************************************************************************

procedure Word32Array.Clear();
   begin
      MaxUsed:= -1;

      if( A <> nil) then begin
         FreeMem( A);
      end;
   end; // Clear()


// ************************************************************************
// * Resize() - Make the array bigger if needed
// ************************************************************************

procedure Word32Array.Resize( NewIndex: int32);
   var
      BytesNeeded:    int32;
      BlocksNeeded:   int32;
      NewSize:        int32;
      Temp:           BigWord32ArrayPtr;
   begin
      // Figure out how much to allocate
      NewSize:= (NewIndex + 1) * sizeof( Word32);
      BlocksNeeded:= NewSize div MemBlockSize;
      if( (NewSize mod MemBlockSize) > 0) then begin
         inc( BlocksNeeded);
      end;
      BytesNeeded:= BlocksNeeded * MemBlockSize;

      // Is this bigger than the maximum we want to allow?
      if( BytesNeeded - MemBlockSize >= MaxSize) then begin
         raise ArrayException.Create( 'Array index is out of bounds!');
      end;

      // Allocate the memory
      GetMem( Temp, BytesNeeded);
      if( Temp = nil) then begin
         raise ArrayException.Create( 'Out of heap for array creation!');
      end;
      FillByte( Temp^, BytesNeeded, 0);

      // Move the old data into the new array
      if( A <> nil) then begin
         move( A^, Temp^, BytesAllocated);
         FreeMem( A);
      end;
      A:= Temp;

      BytesAllocated:= BytesNeeded;
      ElementsAllocated:= BytesAllocated div SizeOf( Word32);
   end;  // Resize()


// ************************************************************************
// * SetMaxUsed - Sets the Upper Bound of the array to a new value without
// *              resizing the physical storage.  The passed value must be
// *              between -1 and the current UpperBound.
// ************************************************************************

procedure Word32Array.SetMaxUsed( i: int32);
   var
      Temp: string;
   begin
      Temp:= '';
      if( (i < -1) or (i > MaxUsed)) then begin
         Str( MaxUsed, Temp);
         raise ArrayException.Create(
               'Attempted to set UpperBound out of range (-1 - ' +
               Temp + ')!');
      end;
      MaxUsed:= i;
   end; // SetMaxUsed()


// ************************************************************************
// * iGet() - Return an element in the array
// ************************************************************************

function Word32Array.iGet( i: int32): Word32;
   begin
      if( (i > MaxUsed) or ( i < 0)) then begin
         raise ArrayException.Create( 'Array index is out of bounds!');
      end;

      iGet:= A^[ i];
   end; // iGet()



// ************************************************************************
// * iSet() - Set the (i)th element of the array.
// ************************************************************************

procedure Word32Array.iSet( i: int32; X: Word32);
   begin
      if( i < 0) then begin
         raise ArrayException.Create( 'Array index is out of bounds!');
      end;

      // Get more storage if we have exceeded our current storage.
      if( i >= ElementsAllocated) then begin
         Resize( i);
      end;

      if( i > MaxUsed) then begin
         MaxUsed:= i;
      end;

      A^[ i]:= X;
   end; // iSet()


// ========================================================================
// = Word64Array
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor Word64Array.Create();
   begin
      Create( -1, High( int32));
   end;


// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor Word64Array.Create( StartingSize: int32);
   begin
      Create( StartingSize, High( int32));
   end; // Create()


// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor Word64Array.Create( StartingSize: int32; MaximumSize: int32);
   begin
      if( MaximumSize < MemBlockSize) then begin
         MaximumSize:= MemBlockSize;
      end;
      MaxSize:= MaximumSize;

      if( StartingSize > 0) then begin
         if( (StartingSize < MemBlockSize)) then begin
            StartingSize:= MemBlockSize;
         end;

         if( MaximumSize < StartingSize) then begin
            raise ArrayException.Create(
               'Array''s initial size is out of bounds!');
         end;

         Resize( StartingSize - 1);
      end;
      MaxUsed:= -1;
      StackPos:= -1;
   end; // Create()


// ************************************************************************
// * Destroy() - Destructor
// ************************************************************************

destructor Word64Array.Destroy();
   begin
      if( A <> nil) then begin
         FreeMem( A);
      end;
   end; // Destroy()



// ************************************************************************
// * StackEmpty() - Returns true if the stack is empty
// ************************************************************************

function Word64Array.StackEmpty(): boolean;
   begin
      exit( StackPos < 0);
   end; // StackEmpty()

// ************************************************************************
// * Push() - push a value onto the stack
// ************************************************************************

procedure Word64Array.Push( X: word64);
   begin
      inc( StackPos);
      iSet( StackPos, X);
   end; // Push


// ************************************************************************
// * Pop() - Pop a value off the stack
// ************************************************************************

function Word64Array.Pop(): word64;
   begin
      Pop:= iGet( StackPos);
      dec( StackPos);
   end; // Pop()


// ************************************************************************
// * Clear() - Deallocate memory used by the array and set it's UpperBound
// *           to -1.
// ************************************************************************

procedure Word64Array.Clear();
   begin
      MaxUsed:= -1;

      if( A <> nil) then begin
         FreeMem( A);
      end;
   end; // Clear()


// ************************************************************************
// * Resize() - Make the array bigger if needed
// ************************************************************************

procedure Word64Array.Resize( NewIndex: int32);
   var
      BytesNeeded:    int32;
      BlocksNeeded:   int32;
      NewSize:        int32;
      Temp:           BigWord64ArrayPtr;
   begin
      // Figure out how much to allocate
      NewSize:= (NewIndex + 1) * sizeof( word64);
      BlocksNeeded:= NewSize div MemBlockSize;
      if( (NewSize mod MemBlockSize) > 0) then begin
         inc( BlocksNeeded);
      end;
      BytesNeeded:= BlocksNeeded * MemBlockSize;

      // Is this bigger than the maximum we want to allow?
      if( BytesNeeded - MemBlockSize >= MaxSize) then begin
         raise ArrayException.Create( 'Array index is out of bounds!');
      end;

      // Allocate the memory
      GetMem( Temp, BytesNeeded);
      if( Temp = nil) then begin
         raise ArrayException.Create( 'Out of heap for array creation!');
      end;
      FillByte( Temp^, BytesNeeded, 0);

      // Move the old data into the new array
      if( A <> nil) then begin
         move( A^, Temp^, BytesAllocated);
         FreeMem( A);
      end;
      A:= Temp;

      BytesAllocated:= BytesNeeded;
      ElementsAllocated:= BytesAllocated div SizeOf( Word64);
   end;  // Resize()


// ************************************************************************
// * SetMaxUsed - Sets the Upper Bound of the array to a new value without
// *              resizing the physical storage.  The passed value must be
// *              between -1 and the current UpperBound.
// ************************************************************************

procedure Word64Array.SetMaxUsed( i: int32);
   var
      Temp: string;
   begin
      Temp:= '';
      if( (i < -1) or (i > MaxUsed)) then begin
         Str( MaxUsed, Temp);
         raise ArrayException.Create(
               'Attempted to set UpperBound out of range (-1 - ' +
               Temp + ')!');
      end;
      MaxUsed:= i;
   end; // SetMaxUsed()


// ************************************************************************
// * iGet() - Return an element in the array
// ************************************************************************

function Word64Array.iGet( i: int32): word64;
   begin
      if( (i > MaxUsed) or ( i < 0)) then begin
         raise ArrayException.Create( 'Array index is out of bounds!');
      end;

      iGet:= A^[ i];
   end; // iGet()



// ************************************************************************
// * iSet() - Set the (i)th element of the array.
// ************************************************************************

procedure Word64Array.iSet( i: int32; X: word64);
   begin
      if( i < 0) then begin
         raise ArrayException.Create( 'Array index is out of bounds!');
      end;

      // Get more storage if we have exceeded our current storage.
      if( i >= ElementsAllocated) then begin
         Resize( i);
      end;

      if( i > MaxUsed) then begin
         MaxUsed:= i;
      end;

      A^[ i]:= X;
   end; // iSet()



// ========================================================================
// = PointerArray
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor PointerArray.Create();
   begin
      Create( -1, High( int32));
   end;


// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor PointerArray.Create( StartingSize: int32);
   begin
      Create( StartingSize, High( int32));
   end; // Create()


// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor PointerArray.Create( StartingSize: int32; MaximumSize: int32);
   begin
      if( MaximumSize < MemBlockSize) then begin
         MaximumSize:= MemBlockSize;
      end;
      MaxSize:= MaximumSize;

      if( StartingSize > 0) then begin
         if( (StartingSize < MemBlockSize)) then begin
            StartingSize:= MemBlockSize;
         end;

         if( MaximumSize < StartingSize) then begin
            raise ArrayException.Create(
               'Array''s initial size is out of bounds!');
         end;

         Resize( StartingSize - 1);
      end;
      MaxUsed:= -1;

   end; // Create()


// ************************************************************************
// * Destroy() - Destructor
// ************************************************************************

destructor PointerArray.Destroy();
   begin
      if( A <> nil) then begin
         FreeMem( A);
      end;
   end; // Destroy()



// ************************************************************************
// * Clear() - Deallocate memory used by the array and set it's UpperBound
// *           to -1.
// ************************************************************************

procedure PointerArray.Clear();
   begin
      MaxUsed:= -1;

      if( A <> nil) then begin
         FreeMem( A);
      end;
   end; // Clear()


// ************************************************************************
// * Resize() - Make the array bigger if needed
// ************************************************************************

procedure PointerArray.Resize( NewIndex: int32);
   var
      BytesNeeded:    int32;
      BlocksNeeded:   int32;
      NewSize:        int32;
      Temp:           BigPointerArrayPtr;
   begin
      // Figure out how much to allocate
      NewSize:= (NewIndex + 1) * sizeof( Pointer);
      BlocksNeeded:= NewSize div MemBlockSize;
      if( (NewSize mod MemBlockSize) > 0) then begin
         inc( BlocksNeeded);
      end;
      BytesNeeded:= BlocksNeeded * MemBlockSize;

      // Is this bigger than the maximum we want to allow?
      if( BytesNeeded - MemBlockSize >= MaxSize) then begin
         raise ArrayException.Create( 'Array index is out of bounds!');
      end;

      // Allocate the memory
      GetMem( Temp, BytesNeeded);
      if( Temp = nil) then begin
         raise ArrayException.Create( 'Out of heap for array creation!');
      end;
      FillByte( Temp^, BytesNeeded, 0);

      // Move the old data into the new array
      if( A <> nil) then begin
         move( A^, Temp^, BytesAllocated);
         FreeMem( A);
      end;
      A:= Temp;

      BytesAllocated:= BytesNeeded;
      ElementsAllocated:= BytesAllocated div SizeOf( Pointer);
   end;  // Resize()


// ************************************************************************
// * SetMaxUsed - Sets the Upper Bound of the array to a new value without
// *              resizing the physical storage.  The passed value must be
// *              between -1 and the current UpperBound.
// ************************************************************************

procedure PointerArray.SetMaxUsed( i: int32);
   var
      Temp: string;
   begin
      Temp:= '';
      if( (i < -1) or (i > MaxUsed)) then begin
         Str( MaxUsed, Temp);
         raise ArrayException.Create(
               'Attempted to set UpperBound out of range (-1 - ' +
               Temp + ')!');
      end;
      MaxUsed:= i;
   end; // SetMaxUsed()


// ************************************************************************
// * iGet() - Return an element in the array
// ************************************************************************

function PointerArray.iGet( i: int32): Pointer;
   begin
      if( (i > MaxUsed) or ( i < 0)) then begin
         raise ArrayException.Create( 'Array index is out of bounds!');
      end;

      iGet:= A^[ i];
   end; // iGet()



// ************************************************************************
// * iSet() - Set the (i)th element of the array.
// ************************************************************************

procedure PointerArray.iSet( i: int32; X: Pointer);
   begin
      if( i < 0) then begin
         raise ArrayException.Create( 'Array index is out of bounds!');
      end;

      // Get more storage if we have exceeded our current storage.
      if( i >= ElementsAllocated) then begin
         Resize( i);
      end;

      if( i > MaxUsed) then begin
         MaxUsed:= i;
      end;

      A^[ i]:= X;
   end; // iSet()


// =========================================================================
// = Int64SortElement - Base element stored in a sorted array
// =========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor Int64SortElement.Create( iSortValue: Int64);
   begin
      SortValue:= iSortValue;
   end; // Constructor


// *************************************************************************
// * Destroy() - Destructor
// *************************************************************************

destructor Int64SortElement.Destroy();
   begin
   end; // Destructor


// ========================================================================
// = Global functions
// ========================================================================
// *************************************************************************
// * InsertSort() - Sort the sub array using the Insert Sort method
// *************************************************************************

procedure InsertSort( A: PointerArray; Start: integer; Finish: integer);
   var
      i:    integer;
      j:    integer;
      Temp: pointer;
   begin
      if( Finish > Start) then begin
         for i:= Start + 1 to Finish do begin
            for j:= i downto Start + 1 do begin
               if( Int64SortElement( A[ j]).SortValue <
                   Int64SortElement( A[ j - 1]).SortValue) then begin
                  // Exchange A[ j] and A[ j - 1]
                  Temp:= A[ j];
                  A[ j]:= A[ j - 1];
                  A[ j - 1]:= Temp;
               end else begin
                  break;
               end; // else
            end; // for j
         end; // for i
      end;
   end; // InsertSort()


// *************************************************************************
// * QuickSort() - Sort the sub array using the Quicksort method
// *************************************************************************

procedure QuickSort( A: PointerArray; Start: integer; Finish: integer);
   var
      Pivot:       int64;
      StartValue:  int64;
      MidValue:    int64;
      FinishValue: int64;

      ma:     integer;
      mi:     integer;
      Temp:   pointer;
   begin
      // Choose the pivot
      StartValue:=  Int64SortElement( A[ Start]).SortValue;
      MidValue:=    Int64SortElement( A[ (Start + Finish) div 2]).SortValue;
      FinishValue:= Int64SortElement( A[ Finish]).SortValue;
      if( FinishValue > StartValue) then begin
         if( MidValue > FinishValue) then begin
            Pivot:= FinishValue;
         end else begin
            if( MidValue > StartValue) then begin
               Pivot:= MidValue;
            end else begin
               Pivot:= StartValue;
            end;
         end;
      end else begin
         if( MidValue > StartValue) then begin
            Pivot:= StartValue;
         end else begin
            if( MidValue > FinishValue) then begin
               Pivot:= MidValue;
            end else begin
               Pivot:= FinishValue;
            end;
         end;
      end;

      ma:= Finish;
      mi:= Start;
      repeat
         while( Pivot < Int64SortElement( A[ ma]).SortValue) do begin
            dec( ma);
         end;
         while( Pivot > Int64SortElement( A[ mi]).SortValue) do begin
            inc( mi);
         end;
         if( mi <= ma) then begin
            if( mi <> ma) then begin
               // Exchange A[ ma] and A[ mi]
               Temp:= A[ ma];
               A[ ma]:= A[ mi];
               A[ mi]:= Temp;
            end;
            dec( ma);
            inc( mi);
         end;
      until( ma < mi);

      // If the array is small, do insetion sort
      if( (ma - Start) > 10) then begin
         QuickSort( A, Start, ma);
      end else begin
         InsertSort( A, Start, ma);
      end;

      if( (Finish - mi) > 10) then begin
         QuickSort( A, mi, Finish);
      end else begin
         InsertSort( A, mi, Finish);
      end;
   end; // QuickSort()


// *************************************************************************
// * Sort() - Sort the items in the array
// *************************************************************************

procedure SortInfoArray( A: PointerArray);
   begin
      if( A.UpperBound < 0) then begin
         exit;
      end;

      QuickSort( A, 0, A.UpperBound);
   end; // Sort()


// *************************************************************************
// * LookupInInfoArray() - Given an Int64 key value, looks up the
// *                       Int64SortElement in the array.
// *                       Raises an exception if not found.
// *************************************************************************

function LookupInInfoArray( KeyValue:   int64;
                            A:          PointerArray;
                            FirstIndex: int32;
                            LastIndex:  int32): Int64SortElement;
   var
      Element: Int64SortElement;
      i:       int32;
   begin
      // Make sure our slice of the array has at least one element.
      while( LastIndex >= FirstIndex) do begin
         i:= FirstIndex + ((LastIndex - FirstIndex) div 2);
         Element:= Int64SortElement( A[ i]);
         if Element.SortValue = KeyValue then begin
            exit( Element);
         end else if( Element.SortValue > KeyValue) then begin
            LastIndex:= pred( i);
         end else begin
            FirstIndex:= succ( i);
         end;
      end;

      // We only get here if we didn't find the element
      raise ArrayException.Create( Format( 'Unable to find an ' +
         'Int64SortElement in the array with a sort value of %d!',
         [KeyValue]));
   end; // LookupInInfoArray()

// -------------------------------------------------------------------------


function LookupInInfoArray( KeyValue: int64; A: PointerArray): Int64SortElement;
   begin
      exit( LookUpInInfoArray( KeyValue, A, 0, A.UpperBound));
   end; // LookupInInfoArray()


// ************************************************************************

end. // lbp_vararray unit
