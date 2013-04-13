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

unit DDuce.Demos.ListDataSet;

{ Demonstrates TListDataSet }

//*****************************************************************************

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, Grids, DBGrids, Contnrs, Vcl.ActnList,
  System.Actions, Vcl.ExtCtrls, Vcl.DBCtrls, Vcl.ComCtrls,

  VirtualTrees,

  DSharp.Collections, DSharp.Bindings, DSharp.Bindings.VCLControls,
  DSharp.Windows.TreeViewPresenter,

  DDuce.Components.ListDataSet, DDuce.Components.GridView,
  DDuce.Components.DBGridView,

  DDuce.Demos.Contact, Vcl.Mask, Vcl.StdCtrls;

//=============================================================================

type
  TfrmListDataSet = class(TForm)
    {$REGION 'designer controls'}
    aclMain                   : TActionList;
    actConnectDataSet         : TAction;
    actConnectPresenter       : TAction;
    actDisconnectDataSet      : TAction;
    actDisconnectPresenter    : TAction;
    actFillList               : TAction;
    actInspectComponents      : TAction;
    btnConnectPresenter       : TButton;
    btnDisconnectPresenter    : TButton;
    btnExecute                : TButton;
    btnExecute1               : TButton;
    btnExecute2               : TButton;
    dscMain                   : TDataSource;
    edtAddress                : TLabeledEdit;
    edtCompanyName            : TLabeledEdit;
    edtCountry                : TLabeledEdit;
    edtDBAddress              : TDBEdit;
    edtDBCompanyName          : TDBEdit;
    edtDBCountry              : TDBEdit;
    edtDBEmail                : TDBEdit;
    edtDBFirstname            : TDBEdit;
    edtDBLastname             : TDBEdit;
    edtDBNumber               : TDBEdit;
    edtEmail                  : TLabeledEdit;
    edtFirstname              : TLabeledEdit;
    edtLastname               : TLabeledEdit;
    edtNumber                 : TLabeledEdit;
    edtRecordCount            : TEdit;
    lblRecordCount            : TLabel;
    navDataSet                : TDBNavigator;
    pnlClient                 : TPanel;
    pnlDataAware              : TPanel;
    pnlLeft                   : TPanel;
    pnlLeftFooter             : TPanel;
    pnlLeftHeader             : TPanel;
    pnlPresenter              : TPanel;
    pnlRight                  : TPanel;
    pnlRightFooter            : TPanel;
    pnlRightHeader            : TPanel;
    pnlTop                    : TPanel;
    sbrMain                   : TStatusBar;
    splVertical               : TSplitter;
    pnlDataAwareControls      : TPanel;
    pnlVCLControls            : TPanel;
    lblFirstname              : TLabel;
    lblLastname               : TLabel;
    lblEmail                  : TLabel;
    lblCompanyName            : TLabel;
    lblAddress                : TLabel;
    lblCountry                : TLabel;
    lblNumber                 : TLabel;
    {$ENDREGION}

    procedure actFillListExecute(Sender: TObject);
    procedure actConnectDataSetExecute(Sender: TObject);
    procedure actDisconnectDataSetExecute(Sender: TObject);
    procedure actInspectComponentsExecute(Sender: TObject);
    procedure actDisconnectPresenterExecute(Sender: TObject);
    procedure actConnectPresenterExecute(Sender: TObject);

    procedure FormResize(Sender: TObject);
    procedure dscMainUpdateData(Sender: TObject);

  private
    FList        : IList<TContact>;
    FVST         : TVirtualStringTree;
    FDBGV        : TDBGridView;
    FTVP         : TTreeViewPresenter;
    FListDataSet : TListDataSet<TContact>;
    FBG          : TBindingGroup;

    function GetDataSet: TDataSet;
    function GetDataSetEnabled: Boolean;
    function GetPresenterEnabled: Boolean;
    procedure SetDataSetEnabled(const Value: Boolean);
    procedure SetPresenterEnabled(const Value: Boolean);

    procedure FillList;
    procedure DisconnectPresenter;
    procedure DisconnectDataSet;
    procedure ConnectPresenter;
    procedure ConnectDataSet;

  protected
    procedure FDBGVHeaderClick(Sender: TObject; Section: TGridHeaderSection);

    procedure UpdateActions; override;

  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    property DataSet: TDataSet
      read GetDataSet;

    property DataSetEnabled: Boolean
      read GetDataSetEnabled write SetDataSetEnabled;

    property PresenterEnabled: Boolean
      read GetPresenterEnabled write SetPresenterEnabled;

  end;

//*****************************************************************************

implementation

{$R *.dfm}

uses
  Rtti, Math,

  DSharp.Core.Reflection,

  DDuce.Demos.Helpers;

{$REGION 'construction and destruction'}
//*****************************************************************************
// construction and destruction                                          BEGIN
//****************************************************************************

procedure TfrmListDataSet.AfterConstruction;
begin
  inherited AfterConstruction;
  FList        := CreateContactList;
  FVST         := CreateVST(Self, pnlRight);
  FDBGV        := CreateDBGridView(Self, pnlLeft, dscMain);
  FListDataSet := TListDataset<TContact>.Create(Self, FList);
  FBG          := TBindingGroup.Create(Self);
  FDBGV.OnHeaderClick := FDBGVHeaderClick;
  //FDBGV.OnGetSortDirection := FDBGVGe
end;

procedure TfrmListDataSet.BeforeDestruction;
begin
  DisconnectPresenter;
  FList := nil;
  inherited BeforeDestruction;
end;

//*****************************************************************************
// construction and destruction                                            END
//*****************************************************************************
{$ENDREGION}

{$REGION 'action handlers'}
//*****************************************************************************
// action handlers                                                       BEGIN
//*****************************************************************************

procedure TfrmListDataSet.actConnectDataSetExecute(Sender: TObject);
begin
  ConnectDataSet;
end;

procedure TfrmListDataSet.actConnectPresenterExecute(Sender: TObject);
begin
  ConnectPresenter;
end;

procedure TfrmListDataSet.actDisconnectDataSetExecute(Sender: TObject);
begin
  DisconnectDataSet;
end;

procedure TfrmListDataSet.actDisconnectPresenterExecute(Sender: TObject);
begin
  DisconnectPresenter;
end;

procedure TfrmListDataSet.actFillListExecute(Sender: TObject);
begin
  DisconnectPresenter;
  DisconnectDataSet;
  FillList;
end;

procedure TfrmListDataSet.actInspectComponentsExecute(Sender: TObject);
begin
  //InspectComponents([DataSet, FVST, FDBGV, FTVP]);
end;

//*****************************************************************************
// action handlers                                                         END
//*****************************************************************************
{$ENDREGION}

{$REGION 'event handlers'}
//*****************************************************************************
// event handlers                                                        BEGIN
//*****************************************************************************

procedure TfrmListDataSet.FormResize(Sender: TObject);
begin
  pnlLeft.Width := ClientWidth div 2;
end;

procedure TfrmListDataSet.dscMainUpdateData(Sender: TObject);
begin
  FVST.Invalidate;
end;

//*****************************************************************************
// event handlers                                                          END
//*****************************************************************************
{$ENDREGION}

{$REGION 'property access methods'}
//*****************************************************************************
// property access methods                                               BEGIN
//*****************************************************************************

function TfrmListDataSet.GetDataSet: TDataSet;
begin
  Result := FListDataSet;
end;

function TfrmListDataSet.GetDataSetEnabled: Boolean;
begin
  Result := DataSet.Active;
end;

procedure TfrmListDataSet.SetDataSetEnabled(const Value: Boolean);
begin
  if Value <> DataSetEnabled then
  begin
    DataSet.Active := Value;
  end;
end;

function TfrmListDataSet.GetPresenterEnabled: Boolean;
begin
  Result := Assigned(FTVP);
end;

procedure TfrmListDataSet.SetPresenterEnabled(const Value: Boolean);
begin
  if Value <> PresenterEnabled then
  begin
    if Value then
      ConnectPresenter
    else
      DisconnectPresenter;
  end;
end;

//*****************************************************************************
// property access methods                                                 END
//*****************************************************************************
{$ENDREGION}

{$REGION 'private methods'}
//*****************************************************************************
// private methods                                                       BEGIN
//*****************************************************************************

procedure TfrmListDataSet.FDBGVHeaderClick(Sender: TObject;
  Section: TGridHeaderSection);
var
  bDesc : Boolean;
  Field : TField;
begin
  Screen.Cursor := crSQLWait;
  try
    Field := FDBGV.Columns[Section.ColumnIndex].Field;
    if Assigned(Field) and (Field.FieldKind = fkData) then
    begin
      FList.Sort(
        function(const Left, Right: TContact): Integer
        var
          V1 : TValue;
          V2 : TValue;
        begin
          V1 := Left.GetProperty(Field.FieldName).GetValue(Left);
          V2 := Right.GetProperty(Field.FieldName).GetValue(Right);
          if V1.IsOrdinal and V2.IsOrdinal then
          begin
            Result := Math.CompareValue(V1.AsOrdinal, V2.AsOrdinal);
          end else
          if V1.IsFloat and V2.IsFloat then
          begin
            Result := Math.CompareValue(V1.AsFloat, V2.AsFloat);
          end else
          if V1.IsString and V2.IsString then
          begin
            Result := SysUtils.CompareStr(V1.AsString, V2.AsString);
          end else
          begin
            Result := 0;
          end;
        end);
    DataSet.Refresh;
//      FSortedFieldName := Field.FieldName;
//      if SortDataSet(FSortedFieldName, bDesc) then
//        if bDesc then
//          FSortDirection := gsDescending
//        else
//          FSortDirection := gsAscending
//      else
//      begin
//        FSortDirection   := gsNone;
//        FSortedFieldName := '';
//      end;
//      if GotoFirstAfterSort then
//        DataSet.First;
//    end
//    else
//    begin
//      FSortDirection   := gsNone;
//      FSortedFieldName := '';
//    end;
//    // TODO: should maybe only be triggered after a successful sort operation.
   end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmListDataSet.FillList;
begin
  FillListWithContacts(FList.AsList, StrToInt(edtRecordCount.Text));
end;

procedure TfrmListDataSet.ConnectDataSet;
begin
  DataSet.Active := True;
  dscMain.DataSet := DataSet;
  FDBGV.AutoSizeCols;
end;

procedure TfrmListDataSet.ConnectPresenter;
begin
  if not Assigned(FTVP) then
  begin
    FTVP := CreateTVP(Self, FVST, FList.AsList);
    FVST.Header.AutoFitColumns;
    AddControlBinding(FBG, FTVP, 'View.CurrentItem.Firstname', edtFirstname);
    AddControlBinding(FBG, FTVP, 'View.CurrentItem.Lastname', edtLastname);
    AddControlBinding(FBG, FTVP, 'View.CurrentItem.Address', edtAddress);
    AddControlBinding(FBG, FTVP, 'View.CurrentItem.CompanyName', edtCompanyName);
    AddControlBinding(FBG, FTVP, 'View.CurrentItem.Email', edtEmail);
    AddControlBinding(FBG, FTVP, 'View.CurrentItem.Country', edtCountry);
    AddControlBinding(FBG, FTVP, 'View.CurrentItem.Number', edtNumber);
  end;
end;

procedure TfrmListDataSet.DisconnectDataSet;
begin
  DataSet.Active := False;
  dscMain.DataSet := nil;
end;

procedure TfrmListDataSet.DisconnectPresenter;
begin
  FVST.Clear;
  FBG.Bindings.Clear;
  FreeAndNil(FTVP);
end;

//*****************************************************************************
// private methods                                                         END
//*****************************************************************************
{$ENDREGION}

{$REGION 'protected methods'}
//*****************************************************************************
// protected methods                                                     BEGIN
//*****************************************************************************

procedure TfrmListDataSet.UpdateActions;
begin
  inherited;
  actConnectDataSet.Enabled         := not DataSetEnabled;
  actDisconnectDataSet.Enabled      := DataSetEnabled;
  actConnectPresenter.Enabled       := not PresenterEnabled;
  actDisconnectPresenter.Enabled    := PresenterEnabled;
end;

//*****************************************************************************
// protected methods                                                       END
//*****************************************************************************
{$ENDREGION}

end.