{
  Copyright (C) 2013 Tim Sinaeve tim.sinaeve@gmail.com

  This library is free software; you can redistribute it and/or modify it
  under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 3 of the License, or (at your
  option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
  for more details.

  You should have received a copy of the GNU Library General Public License
  along with this library; if not, write to the Free Software Foundation,
  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
}

unit DDuce.Demos.MainForm;

//*****************************************************************************

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, DBClient, Contnrs, StdCtrls, Buttons, ActnList, System.Actions,
  Vcl.ExtCtrls, Vcl.ComCtrls, System.UITypes,

  VirtualTrees,

  DDuce.Logger,

  DSharp.Windows.ColumnDefinitions, DSharp.Windows.TreeViewPresenter;

type
  TfrmMainMenu = class(TForm)
    aclMain        : TActionList;
    actClose       : TAction;
    actExecute     : TAction;
    actFocusFilter : TAction;
    btnExecute     : TBitBtn;
    edtFilter      : TEdit;
    pnlTop         : TPanel;
    pnlVST         : TPanel;
    sbrMain        : TStatusBar;
    vstConcepts    : TVirtualStringTree;

    procedure actExecuteExecute(Sender: TObject);
    procedure actFocusFilterExecute(Sender: TObject);

    procedure tvpConceptsDoubleClick(Sender: TObject);
    procedure vstConceptsPaintBackground(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; R: TRect; var Handled: Boolean);
    procedure edtFilterChange(Sender: TObject);
    procedure FTVPFilter(Item: TObject; var Accepted: Boolean);
    procedure FTVPDoubleClick(Sender: TObject);
    procedure edtFilterKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure edtFilterKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure vstConceptsKeyPress(Sender: TObject; var Key: Char);

    function CustomDrawColumn(
      Sender           : TObject;
      ColumnDefinition : TColumnDefinition;
      Item             : TObject;
      TargetCanvas     : TCanvas;
      CellRect         : TRect;
      ImageList        : TCustomImageList;
      DrawMode         : TDrawMode;
      Selected         : Boolean
    ): Boolean;

  private
    FVKPressed : Boolean;
    FVST       : TVirtualStringTree;
    FTVP       : TTreeViewPresenter;

  public
    procedure AfterConstruction; override;

    procedure ApplyFilter;
    procedure BeforeDestruction; override;

  end;

var
  frmMainMenu: TfrmMainMenu;

//*****************************************************************************

implementation

{$R *.dfm}

uses
  StrUtils,

  DDuce.Demos.Helpers, DDuce.Demos.DemoManager;

type
  TVKSet = set of Byte;

var
  VK_EDIT_KEYS : TVKSet = [
    VK_DELETE,
    VK_BACK,
    VK_LEFT,
    VK_RIGHT,
    VK_HOME,
    VK_END,
    VK_SHIFT,
    VK_CONTROL,
    VK_SPACE,
    Byte('0')..Byte('Z'),
    VK_OEM_1..VK_OEM_102,
    VK_MULTIPLY..VK_DIVIDE
  ];

  VK_CTRL_EDIT_KEYS : TVKSet = [
    VK_INSERT,
    VK_DELETE,
    VK_LEFT,
    VK_RIGHT,
    VK_HOME,
    VK_END,
    Byte('C'),
    Byte('X'),
    Byte('V'),
    Byte('Z')
  ];

  VK_SHIFT_EDIT_KEYS : TVKSet = [
    VK_INSERT,
    VK_DELETE,
    VK_LEFT,
    VK_RIGHT,
    VK_HOME,
    VK_END
  ];

resourcestring
  SConceptsLoaded = '%d demos loaded.';

{$REGION 'construction and destruction'}
//*****************************************************************************
// construction and destruction                                          BEGIN
//*****************************************************************************

procedure TfrmMainMenu.AfterConstruction;
begin
  inherited;
  Logger.Channels.Add(TIPCChannel.Create);
  FVST := vstConcepts;
  FTVP := CreateTVP(Self);
  with FTVP.ColumnDefinitions.Add('Name') do
  begin
    ValuePropertyName := 'Name';
    AutoSize          := True;
    Alignment         := taCenter;
    OnCustomDraw      := CustomDrawColumn;
  end;
  with FTVP.ColumnDefinitions.Add('UnitName') do
  begin
    ValuePropertyName := 'UnitName';
    AutoSize          := True;
  end;
//  with FTVP.ColumnDefinitions.Add('Category') do
//  begin
//    ValuePropertyName := 'Category';
//    AutoSize          := True;
//  end;
  FTVP.TreeView := FVST;
  FTVP.View.ItemsSource := DemoManager.ItemList;
  FTVP.View.Filter.Add(FTVPFilter);
  FTVP.OnDoubleClick := FTVPDoubleClick;
  FVST.Header.AutoFitColumns;
  sbrMain.SimpleText := Format(SConceptsLoaded, [DemoManager.ItemList.Count]);
end;

procedure TfrmMainMenu.BeforeDestruction;
begin
  FTVP.TreeView := nil; // bug in TVP?
  inherited;
end;

//*****************************************************************************
// construction and destruction                                            END
//*****************************************************************************
{$ENDREGION}

{$REGION 'action handlers'}
//*****************************************************************************
// action handlers                                                       BEGIN
//*****************************************************************************

procedure TfrmMainMenu.actExecuteExecute(Sender: TObject);
begin
  DemoManager.Execute(FTVP.SelectedItem);
end;

procedure TfrmMainMenu.actFocusFilterExecute(Sender: TObject);
begin
  edtFilter.SetFocus;
  edtFilter.SelectAll;
end;

//*****************************************************************************
// action handlers                                                         END
//*****************************************************************************
{$ENDREGION}

{$REGION 'event handlers'}
//*****************************************************************************
// event handlers                                                        BEGIN
//*****************************************************************************

procedure TfrmMainMenu.tvpConceptsDoubleClick(Sender: TObject);
begin
  DemoManager.Execute(FTVP.SelectedItem);
end;

procedure TfrmMainMenu.FTVPDoubleClick(Sender: TObject);
begin
  actExecute.Execute;
end;

procedure TfrmMainMenu.FTVPFilter(Item: TObject; var Accepted: Boolean);
var
  C: TDemo;
begin
  if edtFilter.Text <> '' then
  begin
    C := TDemo(Item);
    Accepted :=
      ContainsText(C.Name, edtFilter.Text)
      or ContainsText(C.UnitName, edtFilter.Text);
  end
  else
    Accepted := True;
end;

procedure TfrmMainMenu.vstConceptsKeyPress(Sender: TObject; var Key: Char);
begin
  if Ord(Key) = VK_RETURN then
  begin
    Close;
  end
  else if Ord(Key) = VK_ESCAPE then
  begin
    ModalResult := mrCancel;
    Close;
  end
  else if not edtFilter.Focused then
  begin
    edtFilter.SetFocus;
    PostMessage(edtFilter.Handle, WM_CHAR, Ord(Key), 0);
    edtFilter.SelStart := Length(edtFilter.Text);
    // required to prevent the invocation of accelerator keys!
    Key := #0;
  end;
end;

procedure TfrmMainMenu.vstConceptsPaintBackground(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; R: TRect; var Handled: Boolean);
begin
  vstConcepts.BackgroundOffsetX := vstConcepts.ClientWidth - 128;
  vstConcepts.BackgroundOffsetY := (vstConcepts.ClientHeight) - 128;
  Handled := False;
end;

procedure TfrmMainMenu.edtFilterChange(Sender: TObject);
begin
  ApplyFilter;
  FVST.FocusedNode := FVST.GetFirstVisible;
  FVST.Selected[FVST.FocusedNode] := True;
end;

procedure TfrmMainMenu.edtFilterKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  A : Boolean;
  B : Boolean;
  C : Boolean;
  D : Boolean;
begin
  A := (ssAlt in Shift) or (ssShift in Shift);
  B := (Key in VK_EDIT_KEYS) and (Shift = []);
  C := (Key in VK_CTRL_EDIT_KEYS) and (Shift = [ssCtrl]);
  D := (Key in VK_SHIFT_EDIT_KEYS) and (Shift = [ssShift]);
  if not (A or B or C or D) then
  begin
    FVKPressed := True;
    Key := 0;
  end;
end;

procedure TfrmMainMenu.edtFilterKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if FVKPressed and FVST.Enabled then
  begin
    PostMessage(FVST.Handle, WM_KEYDOWN, Key, 0);
    if Visible and FVST.CanFocus then
      FVST.SetFocus;
    end;
    FVKPressed := False;
end;

function TfrmMainMenu.CustomDrawColumn(Sender: TObject;
  ColumnDefinition: TColumnDefinition; Item: TObject; TargetCanvas: TCanvas;
  CellRect: TRect; ImageList: TCustomImageList; DrawMode: TDrawMode;
  Selected: Boolean): Boolean;
begin
  TargetCanvas.Font.Style := TargetCanvas.Font.Style + [fsBold];
  Result := True;
end;

//*****************************************************************************
// event handlers                                                          END
//*****************************************************************************
{$ENDREGION}

{$REGION 'protected methods'}
//*****************************************************************************
// protected methods                                                     BEGIN
//*****************************************************************************

procedure TfrmMainMenu.ApplyFilter;
begin
  FTVP.ApplyFilter;
end;

//*****************************************************************************
// protected methods                                                       END
//*****************************************************************************
{$ENDREGION}

end.
