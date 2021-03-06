{* ***************************************************************************

Copyright (c) 2020 by Lloyd B. Park

Renames selected fields in the CSV field/column header.

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

program csv_rename_fields;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_csv,
   lbp_csv_filter,
   lbp_csv_io_filters;


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'csv_rename_fields renames selected fields in a CSV file.  The input and ');
      InsertUsage( '         field(s) which need renamed must be specified on the command line.');
      InsertUsage( '         The new names for the output fields must be specified in the same');
      InsertUsage( '         order as the input filed(s) which they replace.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_rename_fields --if <input field(s)> --of <output field(s)>');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      InsertParam( ['if','input-fields'], true, '', 'The comma separated list of input field'); 
      InsertUsage( '                                 names which will be renamed');
      InsertParam( ['of','output-fields'], true, '', 'The comma separated list of replacement');
      InsertUsage( '                                 field names');
      InsertUsage();

      ParseParams();  // parse the command line
   end; // InitArgvParser();


// ************************************************************************
// * main()
// ************************************************************************

var
   FieldError:    string = 
   'Valid input-fields and output-fields must be specified on the command line!';
   InputFields:   string;
   OutputFields:  string;
   RenameFilter:  tCsvRenameFilter;
begin
   InitArgvParser();
   
   InputFields:=   GetParam( 'if');
   OutputFields:=  GetParam( 'of');
   if( (Length( InputFields) < 1) or (Length( OutputFields) < 1)) then begin
      Usage( true, FieldError);
   end;
   RenameFilter:= tCsvRenameFilter.Create( InputFields, OutputFields);
   
   CsvFilterQueue.Queue:= CsvInputFilter;
   CsvFilterQueue.Queue:= RenameFilter;
   CsvFilterQueue.Queue:= CsvOutputFilter;
   CsvFilterQueue.Go();

   // Cleanup happens automatically in the  lbp_csv_filters unit.
end.  // csv_rename_fields program
