program string_to_unix_time;

{$include lbp_standard_modes.inc}

uses
   lbp_current_time,
   lbp_types,
   dateutils,
   sysutils;

const
   GMToffset = 4;
      

// ************************************************************************
// * Usage()
// ************************************************************************

procedure Usage();
   begin
      writeln();
      writeln();
      writeln( 'usage:  string_to_unix_time <date time>');
      writeln( '            where <date time> is enclosed in quotes and');
      writeln( '            has the format:  ''yyyy-mm-dd hh:mm:ss''');
      writeln( 'or:     string_to_unix_time <UNIX time>');
      writeln( '            where <UNIX time> is the number of seconds since');
      writeln( '            Midnight January 1, 1970');
      writeln();
      halt;
   end; // Usage()
   
   
// ************************************************************************
// * main() 
// ************************************************************************

var
   P:         string;  // First parameter on the command line.
   UnixTime:  word64;
   Code:      word;    // Conversion errors
   lbpDT:     tlbpTimeClass;   
begin
   if( ParamCount <> 1) then begin
      Usage(); // Aborts the program
   end;
   lbpDT:= tlbpTimeClass.Create();
   
   P:= ParamStr( 1);
   if( Pos( ':', P) > 0) then begin
      lbpDT.Str:= P;
      writeln(  DateTimetoUnix( lbpDT.TimeOfDay));
   end else begin
      Val( P, UnixTime, Code); // Convert the string representation of UnixTime to a time_t;
      if( Code > 0) then begin
         Usage();  // Aborts the program
      end;
      lbpDT.TimeOfDay:= UnixToDateTime( UnixTime);
      writeln( lbpDT.Str); 
   end;
   lbpDT.Destroy();
end.  // string_to_unix_time program
