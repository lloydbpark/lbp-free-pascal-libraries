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
function IsATTY( Handle: Longint): Boolean;
   var
      FileType: dword;
   begin
      FileType:= GetFileType( Handle);
      result:= not (FileType = FILE_TYPE_PIPE);
   end;
{$endif}


// ************************************************************************
// * main()
// ************************************************************************

begin
   if( IsATTY( 0)) then writeln( 'Input is from the console.')
   else writeln( 'Input is from a pipe.');  
end. // isatty_test program
