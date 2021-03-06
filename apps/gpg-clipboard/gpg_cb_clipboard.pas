unit gpg_cb_clipboard;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, AsyncProcess;

type

  { TCryptEditForm }

  TCryptEditForm = class(TForm)
     GpgRunner: TAsyncProcess;
     ComboBox1: TComboBox;
     CryptBtn: TButton;
     EditBox: TMemo;
     MenuBtn: TSpeedButton;
     procedure CryptBtnClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  CryptEditForm: TCryptEditForm;

implementation

{$R *.lfm}

{ TCryptEditForm }



procedure TCryptEditForm.CryptBtnClick(Sender: TObject);
begin
   EditBox.Lines.SaveToStream();
end;

end.

