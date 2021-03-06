program rootls;
 
{ Demonstrates using TProcess, redirecting stdout/stderr to our stdout/stderr,
calling sudo on Linux/OSX, and supplying input on stdin}
{$mode objfpc}{$H+}
 
uses
  Classes,
  Math, {for min}
  Process;
 
  procedure RunsLsRoot;
  var
    Proc: TProcess;
    CharBuffer: array [0..511] of char;
    ReadCount: integer;
    ExitCode: integer;
    SudoPassword: string;
  begin
    WriteLn('Please enter the sudo password:');
    Readln(SudoPassword);
    ExitCode := -1; //Start out with failure, let's see later if it works
    Proc := TProcess.Create(nil); //Create a new process
    try
      Proc.Options := [poUsePipes, poStderrToOutPut]; //Use pipes to redirect program stdin,stdout,stderr
      Proc.CommandLine := 'sudo -S ls /root'; //Run ls /root as root using sudo
      // -S causes sudo to read the password from stdin.
      Proc.Execute; //start it. sudo will now probably ask for a password
 
      // write the password to stdin of the sudo program:
      SudoPassword := SudoPassword + LineEnding;
      Proc.Input.Write(SudoPassword[1], Length(SudoPassword));
      SudoPassword := '%*'; //short string, hope this will scramble memory a bit; note: using PChars is more fool-proof
      SudoPassword := ''; // and make the program a bit safer from snooping?!?
 
      // main loop to read output from stdout and stderr of sudo
      while Proc.Running or (Proc.Output.NumBytesAvailable > 0) or
        (Proc.Stderr.NumBytesAvailable > 0) do
      begin
        // read stdout and write to our stdout
        while Proc.Output.NumBytesAvailable > 0 do
        begin
          ReadCount := Min(512, Proc.Output.NumBytesAvailable); //Read up to buffer, not more
          Proc.Output.Read(CharBuffer, ReadCount);
          Write(StdOut, Copy(CharBuffer, 0, ReadCount));
        end;
        // read stderr and write to our stderr
        while Proc.Stderr.NumBytesAvailable > 0 do
        begin
          ReadCount := Min(512, Proc.Stderr.NumBytesAvailable); //Read up to buffer, not more
          Proc.Stderr.Read(CharBuffer, ReadCount);
          Write(StdErr, Copy(CharBuffer, 0, ReadCount));
        end;
      end;
      ExitCode := Proc.ExitStatus;
    finally
      Proc.Free;
      Halt(ExitCode);
    end;
  end;
 
begin
  RunsLsRoot;
end.

Other thoughts: It would no doubt be advisable to see if sudo actually prompts for a password. This can be checked consistently by setting the environment variable SUDO_PROMPT to something we watch for while reading the stdout of TProcess avoiding the problem of the prompt being different for different locales. Setting an environment variable causes the default values to be cleared(inherited from our process) so we have to copy the environment from our program if needed.
Using fdisk with sudo on Linux

The following example shows how to run fdisk on a Linux machine using the sudo command to get root permissions.

program getpartitioninfo;
{Originally contributed by Lazarus forums wjackon153. Please contact him for questions, remarks etc.
Modified from Lazarus snippet to FPC program for ease of understanding/conciseness by BigChimp}
 
Uses
  Classes, SysUtils, FileUtil, Process;
 
var
  hprocess: TProcess;
  sPass: String;
  OutputLines: TStringList;
 
begin  
  sPass := 'yoursudopasswordhere'; // You need to change this to your own sudo password
  OutputLines:=TStringList.Create; //... a try...finally block would be nice to make sure 
  // OutputLines is freed... Same for hProcess.
 
  // The following example will open fdisk in the background and give us partition information
  // Since fdisk requires elevated priviledges we need to 
  // pass our password as a parameter to sudo using the -S
  // option, so it will will wait till our program sends our password to the sudo application
  hProcess := TProcess.Create(nil);
  // On Linux/Unix/OSX, we need specify full path to our executable:
  hProcess.Executable := '/bin/sh';
  // Now we add all the parameters on the command line:
  hprocess.Parameters.Add('-c');
  // Here we pipe the password to the sudo command which then executes fdisk -l: 
  hprocess.Parameters.add('echo ' + sPass  + ' | sudo -S fdisk -l');
  // Run asynchronously (wait for process to exit) and use pipes so we can read the output pipe
  hProcess.Options := hProcess.Options + [poWaitOnExit, poUsePipes];
  // Now run:
  hProcess.Execute;
 
  // hProcess should have now run the external executable (because we use poWaitOnExit).
  // Now you can process the process output (standard output and standard error), eg:
  OutputLines.Add('stdout:');
  OutputLines.LoadFromStream(hprocess.Output);
  OutputLines.Add('stderr:');
  OutputLines.LoadFromStream(hProcess.Stderr);
  // Show output on screen:
  writeln(OutputLines.Text);
 
  // Clean up to avoid memory leaks:
  hProcess.Free;
  OutputLines.Free;
 
  //Below are some examples as you see we can pass illegal characters just as if done from terminal 
  //Even though you have read elsewhere that you can not I assure with this method you can :)
 
  //hprocess.Parameters.Add('ping -c 1 www.google.com');
  //hprocess.Parameters.Add('ifconfig wlan0 | grep ' +  QuotedStr('inet addr:') + ' | cut -d: -f2');
 
  //Using QuotedStr() is not a requirement though it makes for cleaner code;
  //you can use double quote and have the same effect.
 
  //hprocess.Parameters.Add('glxinfo | grep direct');   
 
  // This method can also be used for installing applications from your repository:
 
  //hprocess.Parameters.add('echo ' + sPass  + ' | sudo -S apt-get install -y pkg-name'); 
 
 end.
