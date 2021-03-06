program iplookup;

// ************************************************************************
{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_input_file,
   sysutils;

type
   CharSet = set of char;

var
   DoFullEncode:  boolean = false;
   DoDecode:      boolean = false;
   ReservedChars: CharSet;
   HexCharsStr:   string = '0123456789ABCDEF';       
   ReservedStr:   string = '!*''();:@&=+$,/?#[]"%-.<>\^`{|}~' + chr(10) + chr( 13);
   

// ************************************************************************
// * StringToSet() - Creates a set from a string
// ************************************************************************

function StringToSet( S: string): CharSet;
   var
      C: char;
   begin
      result:= [];
      for C in S do begin
         Include( result, C);
      end;   
   end;  // StringToSet()


// ************************************************************************
// * ProcessText()
// ************************************************************************

procedure ProcessText( T: string);
   var
      i:    integer;
      C:    Char;
      iMax: integer; // Length of T
      R:    string = ''; // result
      Temp: string;
   begin
      iMax:= Length( T);
      i:= 1;
      while( i <= iMax) do begin
         C:= T[ i];

         if( DoDecode) then begin
            if( C = '+') then begin
               C:= ' ';
            end else if( C = '%') then begin
               if( iMax < (i + 2)) then raise lbp_exception.Create( 'Malformed % escape');
               inc( i);
               Temp:= '$' + UpperCase( Copy( T, i, 2));
               C:= char( StrToInt( Temp));
               inc( i);
            end;
            R:= R + C;
         end else begin
            // Encode
            if( C = ' ') then begin
               R:= R + '+';
            end else if( DoFullEncode or (C in ReservedChars)) then begin
               R:= R + '%' + HexStr( ord( T[ i]),2);
            end else begin
               R:= R + C;
            end;
         end;
         inc( i);
      end;

      writeln( R);
   end; // Process Text;

// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'url_encode takes a text parameter from the command line and encodes or decodes');
      InsertUsage( '         it for use in parameters and paths in a URL.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   url_encode [text to convert]');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      SetInputFileParam( false, true, false);
      InsertParam( ['d','decode'], false, '', 'Decode the text rather than the default of encodeing');
      InsertParam( ['a','all'], false, '', '% escape all characters');
      InsertUsage( '');

      ParseParams();
   end; // InitArgvParser()


// ************************************************************************
// * main()
// ************************************************************************
var
   T:      string = '';
begin
   InitArgvParser();
   DoFullEncode:= ParamSet( 'a');
   DoDecode:= ParamSet( 'd');
   ReservedChars:= StringToSet( ReservedStr);

   // Process the command line first
   for T in UnnamedParams do begin
      ProcessText( T);
   end;

   // Process the IPs in the file
   while( lbp_input_file.InputAvailable and not EOF( InputFile)) do begin
      ReadLn( InputFile, T);
      ProcessText( T);
   end; // while

end.  // url_encode()
