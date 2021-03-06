{* ***************************************************************************

Copyright (c) 2019 by Lloyd B. Park

Sorts a .csv file according to the values in one field

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


program csv_sort;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_csv,
   lbp_csv_filter,
   lbp_csv_io_filters,
   lbp_generic_containers;


// ************************************************************************
// * Command line parameters
// ************************************************************************

var
   FieldName:    string = '';
   IgnoreCase:   boolean = false;
   ReverseOrder: boolean = false;
   IgnoreError:  boolean = false;
   ByInt32:      boolean = false;
   ByInt64:      boolean = false;
   ByWord32:     boolean = false;
   ByWord64:     boolean = false;
   ByCurrency:   boolean = false;
   ByFloat:      boolean = false;
   ByDate:       boolean = false;
   ByIpv4:       boolean = false;


// ************************************************************************

var
   NoHeaderError:  string = 'The header paramter must be a valid header field name!';
   SortParamError: string = 'Only one ''by-'' parameter can be selected at once!';
   NotImplemented: string = 'The sort ''by-'' parameter you entered is not yet implemented!';


// ************************************************************************
// * ReadParams
// ************************************************************************

procedure ReadParams();
   var
      Count:  integer = 0;
   begin
      FieldName:=    GetParam( 'h');
      if( FieldName = '') then lbp_argv.Usage( true, NoHeaderError);

      IgnoreCase:=   ParamSet( 'ignore-case');
      ReverseOrder:= ParamSet( 'reverse-order');
      ByInt32:=      ParamSet( 'by-int32');
      ByInt64:=      ParamSet( 'by-int64');
      ByWord32:=     ParamSet( 'by-word32');
      ByWord64:=     ParamSet( 'by-word64');
      ByCurrency:=   ParamSet( 'by-currency');
      ByFloat:=      ParamSet( 'by-float');
      ByDate:=       ParamSet( 'by-date');
      ByIpv4:=       ParamSet( 'by-ipv4');
      IgnoreError:=  ParamSet( 'ignore-error');
      
      // Check to make sure only one 'by-' Parameter is set;
      if(  ByInt32)    then inc( Count);
      if(  ByInt64)    then inc( Count);
      if(  Byword32)   then inc( Count);
      if(  Byword64)   then inc( Count);
      if(  ByCurrency) then inc( Count);
      if(  ByFloat)    then inc( Count);
      if(  ByDate)     then inc( Count);
      if(  ByIpv4)     then inc( Count);
      if( Count > 1) then lbp_argv.Usage( true, SortParamError);
   end; // ReadParams()


// ************************************************************************
// * GetSortByFilter() - create the proper tCsvFilter based on the command
// *                     line parameters.
// ************************************************************************

function GetSortByFilter(): tCsvFilter;
   begin
      result:= nil; // Only needed until they all are implemented
      if( ByInt32) then begin 
         result:= tCsvInt32SortFilter.Create( FieldName, ReverseOrder);
      end else if( ByInt64) then begin
         result:= tCsvInt64SortFilter.Create( FieldName, ReverseOrder);
      end else if( ByWord32) then begin
         result:= tCsvWord32SortFilter.Create( FieldName, ReverseOrder);
      end else if( ByWord64) then begin
         result:= tCsvWord64SortFilter.Create( FieldName, ReverseOrder);
      end else if( ByCurrency) then begin
         result:= tCsvCurrencySortFilter.Create( FieldName, ReverseOrder);
      end else if( ByFloat) then begin
         lbp_argv.Usage( true, NotImplemented);
         // result:= tCsvExtendedSortFilter.Create( FieldName, ReverseOrder);
      end else if( ByDate) then begin
         lbp_argv.Usage( true, NotImplemented);
         // result:= tCsvDateSortFilter.Create( FieldName, ReverseOrder);
      end else if( ByIpv4) then begin
         result:= tCsvIpv4SortFilter.Create( FieldName, ReverseOrder, IgnoreError);
      end else begin
         result:= tCsvStringSortFilter.Create( FieldName, ReverseOrder, IgnoreCase);
      end;
   end; // GetSortByFilter()


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'csv_sort reads a CSV file and outputs it sorted by the specified header field.');
      InsertUsage( 'The sorting is done in memory, so very large files may fail to sort.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_sort [--header <header field name>] [-f <input file name>] [-o <output file name>]');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      InsertParam( ['h', 'header'], true, '', 'The signle header field you are sorting by.');
      InsertParam( ['i', 'ignore-case'], false, '', 'Perform a case insensitive sort.');
      InsertParam( ['r', 'reverse-order'], false, '', 'Outputs in decending order.');
      InsertParam( ['by-int32'], false, '', 'The passed field is a 32 bit signed integer.');
      InsertParam( ['by-int64'], false, '', 'The passed field is a 64 bit signed integer.');
      InsertParam( ['by-word32'], false, '', 'The passed field is a 32 bit unsigned integer.');
      InsertParam( ['by-word64'], false, '', 'The passed field is a 64 bit unsigned integer.');
      InsertParam( ['by-currency'], false, '', 'The passed field is a currency amount.');
      InsertParam( ['by-float'], false, '', 'The passed field is a floating point number.');
      InsertParam( ['by-date'], false, '', 'The passed field is a date.');
      InsertParam( ['by-ipv4'], false, '', 'The passed field is an IPv4 address.');
      InsertParam( ['ignore-error'], false, '', 'Currently for Ipv4 only, if set, conversion');
      InsertUsage( '                                 errors are treated as the ''0.0.0.0'' address.');
      InsertUsage();
      ParseParams();
   end; // InitArgvParser();


// ************************************************************************
// * main()
// ************************************************************************

var
   CsvSortFilter: tCsvFilter;

begin
   InitArgvParser();
   ReadParams();

   CsvSortFilter:= GetSortByFilter();
   
   CsvFilterQueue.Queue:= CsvInputFilter;
   CsvFilterQueue.Queue:= CsvSortFilter;
   CsvFilterQueue.Queue:= CsvOutputFilter;
   CsvFilterQueue.Go();

   // Cleanup happens automatically in the  lbp_csv_filters unit.
end.  // csv_sort program
