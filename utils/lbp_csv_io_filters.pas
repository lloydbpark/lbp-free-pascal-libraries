{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Helps simplify the common case of where lbp_input_file and lbp_output units
are used to create a simple CSV filter.  The FilterQueue, InputFileFilter and
OutputFileFilter are created and destroyed by this unit.  It is up to the user
to add all the filters to the FilterQueue and call FilterQueue.Go();

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
unit lbp_csv_io_filters;

// Classes to handle Comma Separated Value strings and files.

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_argv,
   lbp_types,
   lbp_csv,
   lbp_csv_filter,
   lbp_input_file,
   lbp_output_file;


// *************************************************************************

var
   CsvInputFilter:   tCsvInputFileFilter;
   CsvOutputFilter:  tCsvOutputFileFilter;
   CsvFilterQueue:   tCsvFilterQueue;


// *************************************************************************

implementation

// ========================================================================
// * Unit initialization and finalization.
// ========================================================================
// *************************************************************************
// * ParseArgV() - Create the filters and queue
// *************************************************************************

procedure ParseArgv();
   var
      Delimiter: string;
   begin
      if( lbp_types.show_init) then writeln( 'lbp_csv_io_filters.ParseArgV:  begin');
      CsvInputFilter:= tCsvInputFileFilter.Create( lbp_input_file.InputStream, False);
      CsvOutputFilter:= tCsvOutputFileFilter.Create( OutputFile);
      CsvFilterQueue:= tCsvFilterQueue.Create();

      // Set SkipNonPrintable
      CsvInputFilter.SetSkipNonPrintable( ParamSet( 's'));

      // Set the input delimiter
      if( ParamSet( 'id')) then begin
         Delimiter:= GetParam( 'id');
         if( Length( Delimiter) <> 1) then begin
            raise tCsvException.Create( 'The delimiter must be a singele character!');
         end;
         CsvInputFilter.SetInputDelimiter( Delimiter[ 1]);
         CsvOutputFilter.SetOutputDelimiter( Delimiter[ 1]);
      end;

      // Set the output delimiter
      if( ParamSet( 'od')) then begin
         Delimiter:= GetParam( 'od');
         if( Length( Delimiter) <> 1) then begin
            raise tCsvException.Create( 'The delimiter must be a singele character!');
         end;
         CsvOutputFilter.SetOutputDelimiter( Delimiter[ 1]);
      end; 

      if( lbp_types.show_init) then writeln( 'lbp_csv_io_filters.ParseArgV:  end');
   end; // ParseArgV


// *************************************************************************

var
   CsvFilter: tCsvFilter;

// *************************************************************************

initialization
   begin
      // Add Usage messages
      if( lbp_types.show_init) then writeln( 'lbp_output_file.initialization:  begin');
      SetInputFileParam( true, true, true, true);
      SetOutputFileParam( false, true, true, true);

      AddUsage( '   ========== Generic CSV Filter Options ==========');
      AddParam( ['d', 'id','input-delimiter'], true, ',', 'The character which separates fields on a line.'); 
      AddParam( ['od','output-delimiter'], true, ',', 'The character which separates fields on a line.'); 
      AddParam( ['s', 'skip-non-printable'], false, '', 'Try to fix files with some unicode characters.');
      AddUsage();

      AddPostParseProcedure( @ParseArgv);
      if( lbp_types.show_init) then writeln( 'lbp_output_file.initialization:  end');
   end;


// ************************************************************************

finalization
   begin
      if( lbp_types.show_init) then writeln( 'lbp_output_file.finalization:  begin');
      while( not CsvFilterQueue.IsEmpty()) do begin
         CsvFilter:= CsvFilterQueue.DeQueue;
         CsvFilter.Destroy();
      end;
      CsvFilterQueue.Destroy();
      if( lbp_types.show_init) then writeln( 'lbp_output_file.finalization:  end');
   end;

// *************************************************************************

end. // lbp_csv_io_filters unit
