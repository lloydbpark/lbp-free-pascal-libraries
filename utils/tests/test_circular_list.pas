program test_circular_list;

{$include lbp_standard_modes.inc}
//{$V-}    //Added by LP because it says so below
//{$R-}    //Range checking off
//{$S-}    //Stack checking off
//{$I-}    //I/O checking off
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   lbp_generic_lists,
   sysutils,       // Exceptions
   lbp_types;     // int32

// ************************************************************************

type 
   CharList = specialize tgList< char>;


// ************************************************************************
// * FillForward() - Fills L in the forward direction
// ************************************************************************

procedure FillForward( L: CharList; Debug: boolean = False);
   var
      C: char;
   begin
      writeln( 'FillForward()');
      C:= 'a';
      while( not L.IsFull) do begin
         if( Debug) then begin
            if( L.IsEmpty) then writeln( '   Empty');
            writeln( '   Adding ', C);
         end; // if Debug
         L.AddHead( C);
         inc( C);
         if( Debug) then begin
            if( L.IsEmpty) then writeln( '   Empty');
            if( L.IsFull)  then writeln( '   Full');
         end; // if Debug
      end;
   end; // FillForward()


// ************************************************************************
// * FillReverse() - Fills L in the reverse direction
// ************************************************************************

procedure FillReverse( L: CharList; Debug: boolean = False);
   var
      C: char;
   begin
      writeln( 'FillReverse()');
      C:= 'a';
      while( not L.IsFull) do begin
         if( Debug) then begin
            if( L.IsEmpty) then writeln( '   Empty');
            writeln( '   Adding ', C);
         end; // if Debug
         L.AddTail( C);
         inc( C);
         if( Debug) then begin
            if( L.IsEmpty) then writeln( '   Empty');
            if( L.IsFull)  then writeln( '   Full');
         end; // if Debug
      end;
   end; // FillReverse()


// ************************************************************************
// * EmptyForward() - Remove items from L one at a time.
// ************************************************************************

procedure EmptyForward( L: CharList; Debug: boolean = False);
   var
      C: char;
   begin
      writeln( 'EmptyForward()');
      while( not L.IsEmpty) do begin
         if( Debug) then begin
            if( L.IsFull)  then writeln( '   Full');
         end; // if Debug
         C:= L.RemoveTail;
         if( Debug) then begin
            writeln( '   Removed ', C);
            if( L.IsEmpty) then writeln( '   Empty');
         end; // if Debug
      end;
   end; // EmptyForward()


// ************************************************************************
// * EmptyReverse() - Remove items from L one at a time.
// ************************************************************************

procedure EmptyReverse( L: CharList; Debug: boolean = False);
   var
      C: char;
   begin
      writeln( 'EmptyReverse()');
      while( not L.IsEmpty) do begin
         if( Debug) then begin
            if( L.IsFull)  then writeln( '   Full');
         end; // if Debug
         C:= L.RemoveHead;
         if( Debug) then begin
            writeln( '   Removed ', C);
            if( L.IsEmpty) then writeln( '   Empty');
         end; // if Debug
      end;
   end; // EmptyReverse()


// ************************************************************************
// * PushPop()
// ************************************************************************

procedure PushPop( L: CharList; Debug: boolean = False);
   var
      C: char;
   begin
      writeln( 'PushPop()');
      C:= 'a';
      while( not L.IsFull) do begin
         if( Debug) then begin
            if( L.IsEmpty) then writeln( '   Empty');
            writeln( '   Pushed ', C);
         end; // if Debug
         L.Push:= C;
         inc( C);
         if( Debug) then begin
            if( L.IsEmpty) then writeln( '   Empty');
            if( L.IsFull)  then writeln( '   Full');
         end; // if Debug
      end; 

      while( not L.IsEmpty) do begin
         if( Debug) then begin
            if( L.IsFull)  then writeln( '   Full')  else;
         end; // if Debug
         C:= L.Pop;
         if( Debug) then begin
            writeln( '   Popped ', C);
            if( L.IsEmpty) then writeln( '   Empty');
         end; // if Debug
      end;
   end; // PushPop()


// ************************************************************************
// * EnqueueDequeue()
// ************************************************************************

procedure EnqueueDequeue( L: CharList; Debug: boolean = False);
   var
      C:   char;
      Len: integer;
   begin
      writeln( 'EnqueueDequeue()');
      C:= 'a';
      while( not L.IsFull) do begin
         if( Debug) then begin
            if( L.IsEmpty) then writeln( '   Empty');
            writeln( '   Enqueue ', C);
         end; // if Debug
         L.Queue:= C;
         inc( C);
         if( Debug) then begin
            if( L.IsEmpty) then writeln( '   Empty');
            if( L.IsFull)  then writeln( '   Full');
         end; // if Debug
      end; 

      while( not L.IsEmpty) do begin
         Len:= L.Length;
         if( Debug) then begin
            if( L.IsFull)  then writeln( '   Full.         Length = ', Len)  else;
         end; // if Debug
         C:= L.Queue;
         if( Debug) then begin
            writeln( '   Dequeued - ', C, '  Length was ', Len);
            if( L.IsEmpty) then writeln( '   Empty.        Length = ', L.Length);

         end; // if Debug
      end;
   end; // EnqueueDequeue()


// ************************************************************************
// * ForIterate()
// ************************************************************************

procedure ForIterate( L: CharList; Debug: boolean = False);
   var
      C: char;
   begin
      writeln( 'ForIterate()');
      for C in L do begin
         if Debug then Writeln( '   ', C);
      end;
   end; // ForIterate()


// ************************************************************************
// * Iterate()
// ************************************************************************

procedure Iterate( L: CharList; Debug: boolean = False);
   begin
      writeln( 'Iterate()');
      L.StartIteration;
      while (L.Next) do if Debug then writeln( '   ', L.Value);
   end; // Iterate()


// ************************************************************************
// * QueuePeek() - 
// ************************************************************************

procedure QueuePeek( L: CharList; Debug: boolean = False);
   var
      C:   char;
      i:   integer;
      Len: integer;
   begin
      writeln( 'QueuePeek()');
      C:= 'a';
      while( not L.IsFull) do begin
         L.Push:= C;
         inc( C);
      end; 

      Len:= L.Length;
      for i:= 1 to Len do begin
         C:= L.Peek[ i];
         if( Debug) then begin
            writeln( '   Peeked at [ ', i, '] - ', C);
         end; // if Debug
      end;
      L.Empty;
   end; // QueuePeek()


// ************************************************************************
// * main()
// ************************************************************************
var 
   L: CharList;
begin
   L:= CharList.Create( 4, 'Test Char List');

   FillForward( L, true);
   EmptyForward( L, true);
   FillForward( L);
   EmptyReverse( L, true);
   FillReverse( L, true);
   EmptyForward( L, true);
   FillReverse( L);
   EmptyReverse( L, true);

   PushPop( L, true);
   EnqueueDequeue( L, true);
   FillReverse( L);
   ForIterate( L, true);
   Iterate( L, true);
   QueuePeek( L, true);

   L.Destroy();
end. // test_circular_list program
