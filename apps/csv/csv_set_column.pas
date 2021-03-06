{* ***************************************************************************

Copyright (c) 2020 by Lloyd B. Park

Sets the same value for a column in each row.  This is particularly usefull for
after adding a new column with csv_reorder.  By default it will only set the
value of a column's cell if it currently is empty.  This can bee overridden
with the --all command line parameter.  

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

program csv_set_column;

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
      InsertUsage( 'Sets the same value for a column in each row.  This is particularly usefull for');
      InsertUsage( '         after adding a new column with csv_reorder.  By default it will only');
      InsertUsage( '         set the value of a column''s cell if it currently is empty.  This can ');
      InsertUsage( '         be overridden with the --all command line parameter.');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_set_column [--all] --header=<column names> <column values>');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      InsertParam( ['h','header'], true, '', 'The comma separated list of column names'); 
      InsertParam( ['a', 'all'], false, '', 'Sets the value for a cell even if it currently');
      InsertUsage( '                                 has a value.');
      InsertUsage();

      ParseParams();  // parse the command line
   end; // InitArgvParser();


// ************************************************************************
// * main()
// ************************************************************************

var
   FieldCsv:        string = '';
   ValueCsv:        string = '';
   AllCells:        boolean;
   SetFieldFilter:  tCsvSetFieldFilter;
begin
   InitArgvParser();
   
   if( ParamSet( 'header')) then FieldCsv:= GetParam( 'header');
   if( Length( UnnamedParams) = 1) then ValueCsv:= UnnamedParams[ 0];
   AllCells:= ParamSet( 'all');

   SetFieldFilter:= tCsvSetFieldFilter.Create( FieldCsv, ValueCsv, AllCells);
   
   CsvFilterQueue.Queue:= CsvInputFilter;
   CsvFilterQueue.Queue:= SetFieldFilter;
   CsvFilterQueue.Queue:= CsvOutputFilter;
   CsvFilterQueue.Go();

   // Cleanup happens automatically in the  lbp_csv_filters unit.
end.  // csv_set_column program
