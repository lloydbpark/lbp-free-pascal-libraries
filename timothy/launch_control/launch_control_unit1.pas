{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

A simple project for my son's experiments with rocketry

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

unit launch_control_unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, ExtCtrls, EditBtn;

type

  { TLaunchControlForm }

  TLaunchControlForm = class(TForm)
    ArmedCheckBox: TCheckBox;
    AbortCountdownButton: TButton;
    CountdownEdit: TEdit;
    StartCountdownButton: TButton;
    CountdownTimer: TTimer;
    procedure AbortCountdownButtonClick(Sender: TObject);
    procedure ArmedCheckBoxChange(Sender: TObject);
    procedure CountdownTimerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure StartCountdownButtonClick(Sender: TObject);
  private
    { private declarations }
    Seconds:   longint;
    Direction: longint;
  public
    { public declarations }
  end; 

var
  LaunchControlForm: TLaunchControlForm;

implementation

{ TLaunchControlForm }

procedure TLaunchControlForm.FormCreate(Sender: TObject);
begin
   CountdownEdit.Text:='';
end;

procedure TLaunchControlForm.StartCountdownButtonClick(Sender: TObject);
begin
   AbortCountdownButton.Enabled:= true;
   StartCountdownButton.Enabled:= false;
   ArmedCheckBox.Enabled:= false;
   CountdownTimer.Enabled:= true;
   CountdownEdit.Text:='10';
   Seconds:= 10;
   Direction:= -1;
end;


procedure TLaunchControlForm.ArmedCheckBoxChange(Sender: TObject);
begin
  if( ArmedCheckBox.Checked) then begin
     AbortCountdownButton.Enabled:= false;
     StartCountdownButton.Enabled:= true;
     CountdownEdit.Font.Color:= clGreen;
     CountdownTimer.Enabled:= false;
     CountdownEdit.Text:='';
  end else begin
     AbortCountdownButton.Enabled:= false;
     StartCountdownButton.Enabled:= false;
  end;
end;

procedure TLaunchControlForm.CountdownTimerTimer(Sender: TObject);
var
   temp: string;
begin
   Seconds:= Seconds + Direction;
   if( Seconds = 0 ) then begin
      CountdownEdit.Font.Color:= clMaroon;
      countdownEdit.Text:= 'Launched!';
      Direction:= 1;
   end else begin
      str( Seconds, Temp);
      if( Direction = -1) then begin
         CountdownEdit.Font.Color:= clGreen;
      end else begin
         CountdownEdit.Font.Color:= clBlue;
      end;
      CountdownEdit.Text:= Temp;
   end;
end;

procedure TLaunchControlForm.AbortCountdownButtonClick(Sender: TObject);
begin
   CountdownTimer.Enabled:= false;

   AbortCountdownButton.Enabled:= false;
   StartCountdownButton.Enabled:= false;
   ArmedCheckBox.Checked:= false;
   ArmedCheckBox.Enabled:= true;
end;

initialization
  {$I launch_control_unit1.lrs}

end.

