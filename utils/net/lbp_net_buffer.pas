{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Creates classes to hold manipulate network packets used to read/write to RAW 
sockets.

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

// Create lists of NetField to be used to read and write a packet
// on the network.
unit lbp_net_buffer;

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

// Notes about raw sockets
{
   use packet_socket = socket(PF_PACKET, int socket_type, int protocol);
          to send broadcast packets out the local interface.
      - man PF_PACKET

   See dhcp-3.0.2/common/raw.c line 129-142 for an example for
         using writev to write the packet in sections (eth hdr, ip hdr,
         dhcp packet

   See dhcp-3.0.2/common/packet.c line 129 for an example of
        assembling a UDP header

   See dhcp-3.0.2/common/packet.c line 129 for an example of
        decoding a UDP header


}

interface

uses
   lbp_types,
   lbp_log,
   lbp_lists,
   lbp_utils,        // EthernetWord32ToString(), etc
   lbp_net_fields;


// ************************************************************************

const
   EthernetMaxPacketSize        = 1600; // A little big just to be safe


// ************************************************************************

type
   PacketException = class( lbp_exception);
   tEthernetPacketBuffer = class
      public
         HeaderFields: DoubleLinkedList; // Working Header Fields - Create time
         Fields:       DoubleLinkedList;  // Working fields
         AllFields:    DoubleLinkedList;  // Children should place all their
                                          // Fields here.
         BufferPos:  word32;
         DataPos:    word32;            // Start of data. 1st byte after Header
         RawMode:    boolean;           // Set to true if we will be reading
                                          // and writing Ethernet headers.
         EthHdr:     tEthHeaderNetField;  // The ethernet header fields
      public
         Buffer:       tNetBuffer;
         BuffEndPos:   word32;  // Should be set by apps which read a packet
                                // into Buffer.
         PayloadStart: word32;  // Index of the first byte of payload
         ID:           word16;  // A unique number for this buffer.
         IDStr:        String;
         PacketID:     word32;

         constructor  Create();
         destructor   Destroy();          override;
         procedure    AddBaseFields();    virtual;
         procedure    DecodeHeader();     virtual;
         procedure    EncodeHeader();     virtual;
         procedure    Decode();           virtual;
         procedure    Encode();           virtual;
         procedure    LogFullPacket;      virtual;
         procedure    HexDump( StartIndex: word32;
                               EndIndex:   word32); virtual;
         procedure    HexDump();          virtual;

//         function     GetFirstField(): tNetField; virtual;
//         function     GetNextField():  tNetField;  virtual;
//         procedure    EnqueueField( F: tNetField); virtual;
      private

      end; // tEthernetPacketBuffer


// ************************************************************************

type
   tIPPacketBuffer = class( tEthernetPacketBuffer)
      public
         IPHdr:       tIPHeaderNetfield;
      public
         constructor  Create();
      end; // tIPPacketBuffer


// ************************************************************************

type
   tUDPPacketBuffer = class( tIPPacketBuffer)
      private
         PseudoHdr:   tNetBuffer;   // Used for checksums
      public
         UDPHdr:      tUDPHeaderNetfield;
      public
         constructor  Create();
         procedure    Decode();  override;
         procedure    Encode();  override;
         procedure    SetLengthsAndChecksums(); virtual;
         function     CalculateCheckSum(): word16;
      end; // tUDPPacketBuffer


// ************************************************************************

implementation

var
   NextBufferID: word16 = 0;


// ========================================================================
// = tEthernetPacketBuffer
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tEthernetPacketBuffer.Create();
   begin
      RawMode:= false;  // Calling program must set this to true if
                        // using raw (packet) sockets.
      SetLength( Buffer,EthernetMaxPacketSize);
      // Set the Unique Identifier
      inc( NextBufferID);
      if( NextBufferID > 999) then begin
         NextBufferID:= 0;
      end;
      ID:= NextBufferID;
      IDStr:= '';
      Str( ID:3, IDStr);

      // Initialize our lists of fields.
      HeaderFields:= DoubleLinkedList.Create();
      Fields:=       DoubleLinkedList.Create();
      AllFields:=    DoubleLinkedList.Create();

      EthHdr:= tEthHeaderNetField.Create();
      AllFields.Enqueue( EthHdr);
      HeaderFields.Enqueue( EthHdr);
   end; // Create()


// ************************************************************************
// * Destroy() - Destructor
// ************************************************************************

destructor tEthernetPacketBuffer.Destroy();
   var
      Temp: tNetField;
   begin
      IDStr:= '';

      // Empty the Fields and FixedFields lists;
      Fields.RemoveAll();
      Fields.Destroy();
      HeaderFields.RemoveAll();
      HeaderFields.Destroy();

      while( not AllFields.Empty()) do begin
         Temp:= tNetField( AllFields.Dequeue());
         Temp.Destroy();
      end;
      AllFields.Destroy();
   end; // Destroy()


// ************************************************************************
// * AddBaseFields() - Should be called before encoding or decoding a packet.
// *                   It places the minimum fields needed to perform an
// *                   Encode or Decode in Fields.  Children should override
// *                   this and call inherited Decode BEFORE performing
// *                   their own steps.
// ************************************************************************

procedure tEthernetPacketBuffer.AddBaseFields();
   begin
      Fields.RemoveAll();
   end; // AddBaseFields()


// ************************************************************************
// * DecodeHeader() - Extracts the header data from the buffer.
// ************************************************************************

procedure tEthernetPacketBuffer.DecodeHeader();
   var
      TempField: tNetField;
   begin
      BufferPos:= 0;

      // Decode the fixed fields
      TempField:= tNetField( HeaderFields.GetFirst());
      while( TempField <> nil) do begin
         TempField.Read( Buffer, BufferPos);
         if( BufferPos > (BuffEndPos + 1)) then begin
            raise PacketException.Create(
                  'Field data appears to extend beyond the end of the packet!');
         end;
         TempField:= tNetField( HeaderFields.GetNext());
      end;
   end; // DecodeHeader()


// ************************************************************************
// * EncodeHeader() - Places field data into the buffer.
// *            NOTE:  The user must place ALL fields to be encoded into
// *                   the Fields variable before calling this routine.
// ************************************************************************

procedure tEthernetPacketBuffer.EncodeHeader();
   var
      TempField: tNetField;
   begin
      BufferPos:= 0;
      // Encode each of the fields
      TempField:= tNetField( HeaderFields.GetFirst());
      while( TempField <> nil) do begin
         TempField.Write( Buffer, BufferPos);
         TempField:= tNetField( HeaderFields.GetNext());
      end;
      BuffEndPos:= BufferPos - 1;
      PayloadStart:= BufferPos;
      DataPos:= BufferPos;
   end; // EncodeHeader()


// ************************************************************************
// * Decode() - Extracts the data from the buffer.
// ************************************************************************

procedure tEthernetPacketBuffer.Decode();
   var
      TempField: tNetField;
   begin
      if( RawMode) then begin
         DecodeHeader();
      end else begin
         BufferPos:= 0;
      end;

      // Decode the fixed fields
      TempField:= tNetField( Fields.GetFirst());
      while( TempField <> nil) do begin
         TempField.Read( Buffer, BufferPos);
         if( BufferPos > (BuffEndPos + 1)) then begin
            raise PacketException.Create(
                  'Field data appears to extend beyond the end of the packet!');
         end;
         TempField:= tNetField( Fields.GetNext());
      end;
   end; // Decode()


// ************************************************************************
// * Encode() - Places field data into the buffer.
// *            NOTE:  The user must place ALL fields to be encoded into
// *                   the Fields variable before calling this routine.
// ************************************************************************

procedure tEthernetPacketBuffer.Encode();
   var
      TempField: tNetField;
   begin
      if( RawMode) then begin
         EncodeHeader();
      end else begin
         BufferPos:= 0;
         DataPos:= 0;
      end;

      // Encode each of the fields
      TempField:= tNetField( Fields.GetFirst());
      while( TempField <> nil) do begin
         TempField.Write( Buffer, BufferPos);
         TempField:= tNetField( Fields.GetNext());
      end;

      // If we were unable to encode anything
      if( BufferPos = 0) then begin
         raise PacketException.Create( 'Attempt to encode an empty packet!');
      end;

      BuffEndPos:= BufferPos - 1;
   end; // Encode()


// ************************************************************************
// * LogFullPacket() - Sends the packet to the Log using one line per field
// *                   Assumes the packet has been decoded or fields have
// *                   been enqueued in Fields.
// ************************************************************************

procedure tEthernetPacketBuffer.LogFullPacket();
   var
      TempField:    tNetField;
      TempID:       word32;
   begin
      TempID:= ID * word32( 1000) + PacketID;
      EnterCriticalSection( LogCS);
      // Log the header if needed.
      if( RawMode) then begin
         TempField:= tNetField( HeaderFields.GetFirst());
         while( TempField <> nil) do begin
            TempField.Log( LOG_DEBUG, TempID);
            TempField:= tNetField( HeaderFields.GetNext());
         end;
      end; // if RawMode

      TempField:= tNetField( Fields.GetFirst());
      while( TempField <> nil) do begin
         TempField.Log( LOG_DEBUG, TempID);
         TempField:= tNetField( Fields.GetNext());
      end;
      LeaveCriticalSection( LogCS);
   end; // LogFullPacket()



// ************************************************************************
// * HexDumpRange() - Dump a range of the buffer to standard out.
// ************************************************************************

procedure tEthernetPacketBuffer.HexDump( StartIndex: word32;
                                         EndIndex:   word32);
   var
      i: word32;
   begin
      for i:= StartIndex to EndIndex do begin
         write( HexStr( longint( Buffer[ i]), 2), ' ');
         if( (i mod 8) = 7) then begin
            write( ' ');
            if( (i mod 16) = 15) then begin
               writeln;
            end;
         end;
      end;
      writeln();
   end; // HexDump()


// ------------------------------------------------------------------------

procedure tEthernetPacketBuffer.HexDump();
   begin
      HexDump( 0, BuffEndPos);
   end; // HexDump()


// ========================================================================
// = tIPPacketBuffer
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tIPPacketBuffer.Create();
   begin
      inherited Create();

      IPHdr:= tIPHeaderNetField.Create();
      AllFields.Enqueue( IPHdr);
      HeaderFields.Enqueue( IPHdr);
   end; // Create()



// ========================================================================
// = tUDPPacketBuffer
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tUDPPacketBuffer.Create();
   begin
      inherited Create();

      UDPHdr:= tUDPHeaderNetField.Create();
      AllFields.Enqueue( UDPHdr);
      HeaderFields.Enqueue( UDPHdr);
      SetLength( PseudoHdr, 12);
   end; // Create()


// ************************************************************************
// * Decode() - Extracts the data from the buffer.
// ************************************************************************

procedure tUDPPacketBuffer.Decode();
   var
//      IPPayloadLength:  word16;
      Temp:             word16;
   begin
      inherited Decode();

      // Take care of checksums and lengths if needed.
      if( RawMode) then begin
         // Calculate the lengths
//         IPPayloadLength:= (BuffEndPos + 1) - UDPHdr.StartPos;

         // Test the UDP checksum
         with UDPHdr do begin
            if( CalculateChecksum() <> 0) then begin
               raise NetFieldException.Create( 'UDP checksum failed!');
            end;
         end;

         // Test the IP Header Checksum
         with( IPHdr) do begin
            Temp:= IPchecksum( Buffer, StartPos, UDPHdr.StartPos - 1);
            if( Temp <> 0) then begin
               raise NetFieldException.Create( 'IP header checksum failed!');
            end;
         end;
      end; // If RawMode
   end; // Decode()


// ************************************************************************
// * Encode() - Write the fields into the byte array.
// ************************************************************************

procedure tUDPPacketBuffer.Encode();
   begin
      if( RawMode) then begin
         UDPHdr.UDPChkSum.Value:= 0;
         IPHdr.IPHdrChkSum.Value:= 0;
      end;

      inherited Encode();
   end;

// ************************************************************************
// * SetLengthsAndChecksums() - This should be called after encoding a raw
// *                            packet.  It fills in the IP and UPD lengths
// *                            and checksums in the packet.
// ************************************************************************

procedure tUDPPacketBuffer.SetLengthsAndChecksums();
   var
      EthPayloadLength: word16;
      IPPayloadLength:  word16;
   begin
      // Take care of checksums and lengths if needed.
      if( RawMode) then begin
         // Calculate the lengths
         EthPayloadLength:= (BuffEndPos + 1) - EthHdr.Length;
         IPPayloadLength:= (BuffEndPos + 1) - UDPHdr.StartPos;

         // Set the IP Header Length and Checksum
         with( IPHdr) do begin
            IPLength.Value:= EthPayloadLength;
            IPLength.Write( Buffer);
            IPHdrChkSum.Value:= IPchecksum( Buffer, StartPos,
                                            UDPHdr.StartPos -1);
            IPHdrChkSum.Write( Buffer);
         end;

         // Set the UDP Header length and checksum
         with UDPHdr do begin
            UDPLength.Value:= IPPayloadLength;
            UDPLength.Write( Buffer);
            UDPChkSum.value:= CalculateChecksum();
            UDPChkSum.Write( Buffer);
         end;
      end; // if RawMode
   end; // SetLengthsAndChecksums()


// ************************************************************************
// * CalculateChecksum() - Returns the UDP checksum for the packet.  The
// *                       checksum is weird because it uses only some of
// *                       data from the IPHdr and uses a second copy of
// *                       UPD length in its calculation!
// ************************************************************************

function tUDPPacketBuffer.CalculateChecksum(): word16;
   var
      i:        word32;
      Temp:     word16;
   begin
      // Populate the pseudo IPHdr with values from the real packet.
      i:= 0;
      with IPHdr do begin
         SrcIP.Write( PseudoHdr, i);
         DstIP.Write( PseudoHdr, i);
         PseudoHdr[ i]:= 0;
         inc( i);
         IPProtocol.Write( PseudoHdr, i);
         UDPHdr.UDPLength.Write( PseudoHdr, i);
      end; // with

      Temp:= PartialIPChecksum( 0, PseudoHdr, 0, i - 1);
      Temp:= PartialIPChecksum( Temp, Buffer, UDPHdr.StartPos, BuffEndPos);
      result:= FinalizeIPchecksum( Temp);
   end; // CalculateChecksum()



// ************************************************************************

end.  // lbp_net_buffer unit
