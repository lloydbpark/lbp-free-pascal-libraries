// This is a duplicate of bpf_to_pascal - delete it from the repository!!!

{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Duplicate of bpf_to_pascal

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or 
    (at your option) any later version.


    This program is distributed in the hope that it will be useful,but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU Lesser General Public 
    License along with this program.  If not, see 
    <http://www.gnu.org/licenses/>.

*************************************************************************** *}

program tcpdump_to_bpf_code;
// Reads the results of a tcpdump tcpdump -dd command such as this one:
//      tcpdump -n -s 1522 -ddd port bootpc and ether dst '00:0c:29:24:15:75'
// from standard input and produces pascal code to initialize an array of 
// fpsock_filter called BPF_code.  BPF_code is then applied to a Linux raw 
// socket to filter incomming packets.

uses
   lbp_net_socket_helper,
   lbp_types,
   lbp_lists,
   sysutils;

var
   Max:      integer = 0;
   First:    boolean = true;
   TmpFilt:  fpsock_filter;
   jtStr:    string;
   jfStr:    string;

begin
   // check to see if we are getting STDIN from a console as opposed to a pipe.
//    if( IsATTY( INPUT)) do begin
//       // Print the usage
//       writeln; writeln;
//       writeln( 'This program reads the results of a tcpdump -dd command such as');
//       writeln( 'this one:');
//       writeln( '   tcpdump -n -s 1522 -ddd port bootpc and ether dst ''00:0c:29:24:15:75''');
//       writeln( 'piped to standard input and produces pascal code to initialize an ');
//       writeln( 'array of fpsock_filter called BPF_code.  BPF_code whill then be');
//       writeln( 'applied to a Linux raw socket to filter incomming packets.');
//       writeln( '
//       writeln( 'Change the tcpdump filter statements to match the packets you');
//       writeln( 'wish to read with your program.');
//       writeln;
//       halt;
//    end;


   if( not EOF()) then begin
      readln( Max);
      writeln( '   BPF_code: array [1..', Max, '] of fpsock_filter = (');
   end;

   while not EOF() do with TmpFilt do begin
      readln( code, jt, jf, k);
      if( not First) then writeln( ','); 

      jtStr:= Format( 'jt:%0:d;', [ jt]);
      jfStr:= Format( 'jf:%0:d;', [ jf]);
      write( Format( '      ( code:$%0:2.2x; %1:-7s %2:-7s k:$%3:8.8x )', [ code, jtStr, jfStr, k]));

      First:= false;
   end; // for each line
   
   if( not First) then begin
      writeln();
      writeln( '   ); // BPF_code');
   end;

end. // tcpdump_to_bpf_code program
