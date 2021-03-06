program ListTest;

{ This program tests the Lists include file }

type Item_Type = integer;

{$I Lists.pas}



var
   L: List_Type;
   i: Item_Ptr;
begin
   Initialize( L);
   if Empty( L) then writeLn( 'Empty') else WriteLn( 'Not empty');
   new( i);
   i^:= 1;
   Push( i, L);
   new( i);
   i^:= 2;
   Push( i, L);
   new( i);
   i^:= 3;
   Push( i, L);
   new( i);
   i^:= 4;
   Push( i, L);
   new( i);
   i^:= 5;
   Push( i, L);

   WriteLn( 'Get first, next');
   if Last( L) then writeLn( 'Last') else WriteLn( 'Not Last');
   if First( L) then writeLn( 'First') else WriteLn( 'Not First');
   i:= GetFirst( L);
   WriteLn( i^);
   while not Last( L) do begin
      i:= GetNext( L);
      WriteLn( i^);
   end;
   if Last( L) then writeLn( 'Last') else WriteLn( 'Not Last');
   if First( L) then writeLn( 'First') else WriteLn( 'Not First');
   WriteLn;

   WriteLn( 'Get Last, Previous');
   if Last( L) then writeLn( 'Last') else WriteLn( 'Not Last');
   if First( L) then writeLn( 'First') else WriteLn( 'Not First');
   i:= GetFirst( L);
   i:= GetLast( L);
   WriteLn( i^);
   while not First( L) do begin
      i:= GetPrev( L);
      WriteLn( i^);
   end;
   if Last( L) then writeLn( 'Last') else WriteLn( 'Not Last');
   if First( L) then writeLn( 'First') else WriteLn( 'Not First');
   WriteLn;

   while not Empty( L) do begin
      i:= Pop( L);
      WriteLn( i^);
      dispose( i);
   end;

   if Last( L) then writeLn( 'Last') else WriteLn( 'Not Last');
   if First( L) then writeLn( 'First') else WriteLn( 'Not First');
   WriteLn;

   if Empty( L) then writeLn( 'Empty') else WriteLn( 'Not empty');
   new( i);
   i^:= 1;
   Enqueue( i, L);
   new( i);
   i^:= 2;
   Enqueue( i, L);
   new( i);
   i^:= 3;
   Enqueue( i, L);
   new( i);
   i^:= 4;
   Enqueue( i, L);
   new( i);
   i^:= 5;
   Enqueue( i, L);

   WriteLn( 'GetIndexed');
   i:= GetIndexed( 1, L);
   WriteLn( i^);
   i:= GetIndexed( 5, L);
   WriteLn( i^);
   i:= GetIndexed( 3, L);
   WriteLn( i^);
   new( i);
   i^:= 23;
   Replace( i, L);
   WriteLn;

   new( i);
   i^:= -1;
   AddFront( i, L);
   i:= GetIndexed( 3, L);
   new( i);
   i^:= 50;
   InsertBeforeCurrent( i, L);
   new( i);
   i^:= 60;
   InsertAfterCurrent( i, L);
   WriteLn( Number_Of_Items( L));
   WriteLn;


   WriteLn( 'Dequeue');
   while not Empty( L) do begin
      i:= Dequeue( L);
      WriteLn( i^);
      dispose( i);
   end;

   WriteLn;
   WriteLn;


end.

