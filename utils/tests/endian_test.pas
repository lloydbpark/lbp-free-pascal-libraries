program endian_test;

begin
{$ifdef FPC_BIG_ENDIAN}
   writeln( 'FPC_BIG_ENDIAN is defined.');
{$endif}
{$ifdef FPC_LITTLE_ENDIAN}
   writeln( 'FPC_LITTLE_ENDIAN is defined.');
{$endif}

{$ifdef ENDIAN_BIG}
   writeln( 'ENDIAN_BIG is defined.');
{$endif}
{$ifdef ENDIAN_LITTLE}
   writeln( 'ENDIAN_LITTLE is defined.');
{$endif}

end.