{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Extends Free Pascal's csvdocument unit to specify columns by name.  It is
assumed all CSV files read with this unit will have a row 0 header which 
names each column.

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

unit lbp_csvdocument;

interface

uses
   csvdocument,
   lbp_binary_trees;


// *************************************************************************

type
   tCsvHeaderNode = class
      public 
         Name:  string;
         Index: integer;
         Constructor Create( iName: string; iIndex: integer);
      end; // tCsvHeaderNode class

      
// *************************************************************************

type
   tCsvHeaderTree = class( tBalancedBinaryTree)
      public
         Constructor Create();
      end; // tCsvHeaderTree class


// *************************************************************************

type
   tLbpCsvDocument = class( tcsvdocument)
      private
      Header: tCsvHeaderTree;
   end; // tLbpCsvDocument class

   
// *************************************************************************

implementation

// =========================================================================
// = tCsvHeaderNode class
// =========================================================================
// *************************************************************************
// * Create()
// *************************************************************************

constructor tCsvHeaderNode.Create( iName: string; iIndex: integer);
   begin
      inherited Create()
      Name:=  iName;
      Index:= iIndex;
   end; // Create()


// =========================================================================
// = tCsvHeaderTree class
// =========================================================================
// *************************************************************************
// * CompareByName()
// *************************************************************************

// *************************************************************************
// * Create()
// *************************************************************************

constructor tCsvHeaderTree.Create();
begin
   inherited Create( @CreateByName);
end; // Create()

// =========================================================================
// = tLbpCsvDocument class
// =========================================================================

type
   tCsvHeaderTree = class( tBalancedBinaryTree);

   
// *************************************************************************

end. // lbp_csvdocument
