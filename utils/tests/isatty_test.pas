program isatty_test;

uses
   lbp_types,
{$ifdef UNIX}
   baseunix,
   termio;   // isatty()
{$else}
   jwawinbase;
{$endif}


// ************************************************************************
// * IsATTY() - Returns true if the passed file handle is a terminal as
// *            opposed to a file or pipe.
// ************************************************************************

{$ifdef UNIX}
function IsATTY( Handle: Longint): Boolean;
   var
      t : Termios;
   begin
      result:= (TCGetAttr( Handle, t) = 0);
   end;
{$else} // Windows version
function IsATTY( Handle: Word64): Boolean;
   var
      FileType: dword;
      WinHandle: Word64;
   begin
      writeln( '_isatty = ', _isatty( 0));
      WinHandle:= GetStdHandle( Handle);
      writeln( 'Handle    = ', Handle);
      writeln( 'WinHandle = ', WinHandle);
      WinHandle:= 0;
      FileType:= GetFileType( Handle);
      writeln( 'FileType = ', FileType);
      result:= not (FileType = FILE_TYPE_PIPE);
   end;
{$endif}

// 4294967286
// 2147483647

// ************************************************************************
// * main()
// ************************************************************************

begin
   if( IsATTY( 0)) then writeln( 'Input is from the console.')
   else writeln( 'Input is from a pipe.');  
end. // isatty_test program
