{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Simple program to read and write XML data.  It tries to represent XML in an
ElementTree like the Python lxml package.  

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

// ========================================================================
// = The unit defines simple classes to read and write XML data. 
// ========================================================================

unit lbp_xml;

interface

{$include lbp_standard_modes.inc}
//{$V-}    //Added by LP because it says so below
//{$R-}    //Range checking off
//{$S-}    //Stack checking off
//{$I-}    //I/O checking off
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   lbp_types,
   lbp_utils,  // lbp_exceptions
   lbp_generic_containers;

// Add my name value pair unit.  It needs modified to use generic containters.


// ************************************************************************
// * tXmlAttribute Class
// ************************************************************************

type 
   tSubXmlAttribute = specialize tgDictionary< string, string>;

   tXmlAttribute = class( tSubXmlAttribute) // Extend Name Value Pair tree)
      // Add parse and write functions
      protected type
         tNodeList = specialize tgDoubleLinkedList< tNode>;
      protected
         NodeList:  tNodeList;
      public 
         constructor Create();
         destructor  Destroy(); Override;
         procedure   Add( iKey: K; iValue: V); override;
      private
         procedure   RemoveNode( N: tNode);  virtual; // Remove the passed node
         function    IsEmpty():  boolean; virtual;
         procedure   RemoveSubtree( StRoot: tNode; DestroyElements: boolean); virtual;

      end; // tXmlAttribute
      
      
// ************************************************************************
// * tXmlElement Class
// ************************************************************************

// type 
//    tXmlElement = class (ttNVPNode)
//       private
//          // Define the Child and attribute trees
//       public
//          Tag:  string;
//          Head: string;
//          Tail: string;
//          Attrib: class that contains a list and a tree of the name/value pairs.
//       end; // tXmlElement

// ************************************************************************

implementation

// ========================================================================
// = tXmlAattribute class
// ========================================================================
// ************************************************************************
// * Constructors
// ************************************************************************

constructor tXmlAttribute.Create();
  begin
     inherited Create( tXmlAttribute.tCompareFunction( @CompareStrings), True);
     NodeList:= tNodeList.Create();
  end; // Create()


// ************************************************************************
// * Destructor
// ************************************************************************

destructor tXmlAttribute.Destroy;

   begin
      NodeList.RemoveAll;
      NodeList.Destroy;
      inherited Destroy;
   end; // Destroy();



end. //unit lbp_xml
