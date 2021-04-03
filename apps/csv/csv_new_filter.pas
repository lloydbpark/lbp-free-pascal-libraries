{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

This is my workspace for building new CSV filters.  Its a little easier to
build them here in a small file rather than in the large lbp_csv_filter.pas
file.

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

unit csv_new_filter;

// This is a temporary location to hold new filters as they are being built
// and tested.

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_argv,
   lbp_types,
   lbp_generic_containers,
   lbp_parse_helper, // CurrencyChrs
   lbp_csv_filter_aux,
   lbp_csv_filter,
   lbp_csv,
   lbp_ip_utils,
   sysutils;


// *************************************************************************
// * tCsvFixZeroFilter()
// *************************************************************************

type
   tCsvFixZeroFilter = class( tCsvFilter)
      private
         Fields:       tCsvCellArray; 
         Indexes:      Array of integer;
         FieldLength:  integer; 
      public
         constructor Create( iFieldCsv: string);
         procedure   SetInputHeader( Header: tCsvCellArray); override;
         procedure   SetRow( Row: tCsvCellArray); override;
      end; // tCsvFixZeroFilter


// *************************************************************************

implementation

// ========================================================================
// = tCsvFixZeroFilter class - Replace any zero's in the passed iFieldCSV
// =                   cells with the empty string.
// ========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCsvFixZeroFilter.Create( iFieldCsv: string);
   begin
      inherited Create();
      Fields:= StringToCsvCellArray( iFieldCsv);
      FieldLength:= Length( Fields);
      SetLength( Indexes, FieldLength);
   end; // Create() 


// *************************************************************************
// * SetInputHeader()
// *************************************************************************

procedure tCsvFixZeroFilter.SetInputHeader( Header: tCsvCellArray);
   var 
      HL:       integer; // Header Length
      HI:       integer; // Header index
      FI:       integer; // Fields index;
      Found:    boolean;
      ErrorMsg: string;
   begin
      // If an empty Fields was passed to Create(), then we use all the fields
      HL:=  Length( Header);

      // For each  Field
      FI:= 0;
      while( FI < FieldLength) do begin
         HI:= 0;
         Found:= false;
  
         // for each Header
         while( (not found) and (HI < HL)) do begin
            if( Header[ HI] = Fields[ FI]) then begin
               Found:= true;
               Indexes[ FI]:= HI;
            end;
            inc( HI);
         end; // while Header
  
         if( not Found) then begin
            ErrorMsg:= Format( HeaderUnknownField, [Fields[ FI]]);
            lbp_argv.Usage( true, ErrorMsg);
         end;

         inc( FI);  
      end; // while Fields

      NextFilter.SetInputHeader( Header);
   end; // SetInputHeader


// *************************************************************************
// * SetRow() - Add the row to the tree
// *************************************************************************

procedure tCsvFixZeroFilter.SetRow( Row: tCsvCellArray);
   var
      i:      integer;
      iMax:   integer;
      iCell:  integer;
   begin
      // For each cell we need to check
      for i in Indexes do if( Row[ i] = '0') then Row[ i]:= '';
      
      NextFilter.SetRow( Row);
   end; // SetRow();


// *************************************************************************

end.  // csv_new_filter unit
