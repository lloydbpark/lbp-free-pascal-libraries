program string_to_unix_time;

{$include lbp_standard_modes.inc}

uses
   lbp_current_time,
   baseunix,
   unixtype,
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
// * GetMS1970() - Returns the timezone adjustment in MS
// ************************************************************************

function ms1970(): comp;
   var
      dt1970:    tDateTime;
      ts1970:    tTimeStamp;
   begin
      dt1970:= StrToDateTime( '01-01-70 00:00:00');
      ts1970:= DateTimeToTimeStamp( dt1970);
      result:= TimeStampToMSecs( ts1970) - (GMTOffset * 3600000);
   end; // ms1970()


// ************************************************************************
// * DateTimeToUnixTime() - Convert the pascal DateTime variable to a 
// ************************************************************************

function DateTimeToUnixTime( const DateTime: tDateTime): time_t;
   var
      TimeStamp: tTimeStamp;
      ms:        comp;
            
   begin
      TimeStamp:= DateTimeToTimeStamp( DateTime);
      ms:= TimeStampToMSecs( TimeStamp);
      result:= trunc((ms - ms1970) / 1000);
   end; // DateTimeToUnixTime()
   

// ************************************************************************
// * UnixTimeToDateTime() - Convert UNIX seconds since 1970-01-01 to a
// *                        pascal tDateTime variable.
// ************************************************************************

function UnixTimeToDateTime( UnixTime: time_t): tDateTime;
   var
      TimeStamp: tTimeStamp;
      ms:        comp;
   begin
      ms:= (comp( UnixTime) * comp(1000)) + ms1970;
      TimeStamp:= MSecsToTimeStamp( ms);
      result:= TimeStampToDateTime( TimeStamp);
   end; // UnixTimeToDateTime()            


// ************************************************************************
// * main() 
// ************************************************************************

var
   P:         string;  // First parameter on the command line.
   UnixTime:  time_t;
   Code:      word;    // Conversion errors
   lbpDT:    tlbpTimeClass;   
begin
   if( ParamCount <> 1) then begin
      Usage(); // Aborts the program
   end;
   lbpDT:= tlbpTimeClass.Create();
   
   P:= ParamStr( 1);
   if( Pos( ':', P) > 0) then begin
      lbpDT.Str:= P;
      writeln(  DateTimetoUnixTime( lbpDT.TimeOfDay));
   end else begin
      Val( P, UnixTime, Code); // Convert the string representation of UnixTime to a time_t;
      if( Code > 0) then begin
         Usage();  // Aborts the program
      end;
      lbpDT.TimeOfDay:= UnixTimeToDateTime( UnixTime);
      writeln( lbpDT.Str); 
   end;
   lbpDT.Destroy();
end.  // string_to_unix_time program
