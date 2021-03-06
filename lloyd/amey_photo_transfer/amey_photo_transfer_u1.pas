{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

the main form for amey_photo_transfer

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

unit amey_photo_transfer_u1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  EditBtn,FPReadJPEG, StdCtrls, FileCtrl, lazjpeg, ActnList;

type

  { TMainForm }

  TMainForm = class(TForm)
    CurrentPhoto: TImage;
    SourceDirectoryEdit: TDirectoryEdit;
    SourceFileListBox: TFileListBox;
    procedure FormCreate(Sender: TObject);
    procedure SourceDirectoryEditAcceptDirectory(Sender: TObject;
      var Value: String);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  MainForm: TMainForm;

implementation

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
var
   JPEG: TJPEGImage;
begin
  try
    //--------------------------------------------------------------------------
    // Create a TJPEGImage and load the file, then copy it to the TImage.
    // A TJPEGImage can only load jpeg images.
    JPEG:=TJPEGImage.Create;
    try
      JPEG.LoadFromFile('/home/lpark/pascal/lloyd/amey_photo_transfer/img_9025.jpg');
      // copy jpeg content to a TImage
      CurrentPhoto.Picture.Assign(JPEG);
    finally
      JPEG.Free;
    end;
    //--------------------------------------------------------------------------
  except
    on E: Exception do begin
      MessageDlg('Error','Error: '+E.Message,mtError,[mbOk],0);
    end;
  end;
end;

procedure TMainForm.SourceDirectoryEditAcceptDirectory(Sender: TObject;
  var Value: String);
begin

end;

initialization
  {$I amey_photo_transfer_u1.lrs}

end.

