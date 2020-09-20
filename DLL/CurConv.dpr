library CurConv;

uses
  SysUtils,
  Classes,
  Windows,
  Dialogs,
  uLkJSON in '..\RTL\uLkJSON.pas',
  VtsCurConv in '..\RTL\VtsCurConv.pas';

{$R *.res}

type
  TVtsCurConvFlags = type DWORD;

const
  CONVERT_DONT_SHOW_ERRORS:             TVtsCurConvFlags = 1;
  CONVERT_FALLBACK_TO_CACHE:            TVtsCurConvFlags = 2;
  CONVERT_USE_SSL:                      TVtsCurConvFlags = 4;
  CONVERT_CONFIRM_WEB_ACCESS:           TVtsCurConvFlags = 8;
  CONVERT_NO_INTERACTIVE_API_KEY_INPUT: TVtsCurConvFlags = 16;

const
  S_VTSCONV_OK:                HRESULT = $20000000; // Success, Customer defined, Facility 0, Code 0
  S_VTSCONV_NOTHING:           HRESULT = $20000001; // Success, Customer defined, Facility 0, Code 1
  E_VTSCONV_GENERIC_FAILURE:   HRESULT = $A0000000; // Failure, Customer defined, Facility 0, Code 0
  E_VTSCONV_BAD_ARGS:          HRESULT = $A0000001; // Failure, Customer defined, Facility 0, Code 1
  E_VTSCONV_STOREDKEY_INVALID: HRESULT = $A0000002; // Failure, Customer defined, Facility 0, Code 2
  E_VTSCONV_NO_STOREDKEY:      HRESULT = $A0000003; // Failure, Customer defined, Facility 0, Code 3

function DeleteAPIKey(UserMode: BOOL; DontShowErrors: BOOL): HRESULT; stdcall;
begin
  try
    if TVtsCurConv.DeleteAPIKey(UserMode) then
      result := S_VTSCONV_OK
    else
      result := S_VTSCONV_NOTHING;
  except
    on E: Exception do
    begin
      if DontShowErrors then MessageDlg(e.Message, mtError, [mbOk], 0);
      result := E_VTSCONV_GENERIC_FAILURE;
    end;
  end;
end;

function WriteAPIKeyW(key: LPCWSTR; UserMode: BOOL; DontShowErrors: BOOL): HRESULT; stdcall;
begin
  try
    if Length(key) <> 32 then
    begin
      result := E_VTSCONV_BAD_ARGS;
      Exit;
    end;
    TVtsCurConv.WriteAPIKey(TVtsCurApiKey(key), UserMode);
    result := S_VTSCONV_OK;
  except
    on E: Exception do
    begin
      if DontShowErrors then MessageDlg(e.Message, mtError, [mbOk], 0);
      result := E_VTSCONV_GENERIC_FAILURE;
    end;
  end;
end;

function WriteAPIKeyA(key: LPCSTR; UserMode: BOOL; DontShowErrors: BOOL): HRESULT; stdcall;
begin
  try
    if Length(key) <> 32 then
    begin
      result := E_VTSCONV_BAD_ARGS;
      Exit;
    end;
    TVtsCurConv.WriteAPIKey(TVtsCurApiKey(key), UserMode);
    result := S_VTSCONV_OK;
  except
    on E: Exception do
    begin
      if DontShowErrors then MessageDlg(e.Message, mtError, [mbOk], 0);
      result := E_VTSCONV_GENERIC_FAILURE;
    end;
  end;
end;

function ReadAPIKeyW(key: LPWSTR; DontShowErrors: BOOL): HRESULT; stdcall;
var
  s: WideString;
begin
  try
    s := WideString(TVtsCurConv.ReadAPIKey);
    if s = '' then
    begin
      result := E_VTSCONV_NO_STOREDKEY;
      Exit;
    end;
    if Length(s) <> 32 then
    begin
      result := E_VTSCONV_STOREDKEY_INVALID;
      Exit;
    end;
    ZeroMemory(key, 33*SizeOf(WideChar));
    CopyMemory(key, @s[1], 32*SizeOf(WideChar));
    Result := S_VTSCONV_OK;
  except
    on E: Exception do
    begin
      if DontShowErrors then MessageDlg(e.Message, mtError, [mbOk], 0);
      result := E_VTSCONV_GENERIC_FAILURE;
    end;
  end;
end;

function ReadAPIKeyA(key: LPSTR; DontShowErrors: BOOL): HRESULT; stdcall;
var
  s: AnsiString;
begin
  try
    s := AnsiString(TVtsCurConv.ReadAPIKey);
    if s = '' then
    begin
      result := E_VTSCONV_NO_STOREDKEY;
      Exit;
    end;
    if Length(s) <> 32 then
    begin
      result := E_VTSCONV_STOREDKEY_INVALID;
      Exit;
    end;
    ZeroMemory(key, 33*SizeOf(AnsiChar));
    CopyMemory(key, @s[1], 32*SizeOf(AnsiChar));
    result := S_VTSCONV_OK;
  except
    on E: Exception do
    begin
      if DontShowErrors then MessageDlg(e.Message, mtError, [mbOk], 0);
      result := E_VTSCONV_GENERIC_FAILURE;
    end;
  end;
end;

function ConvertW(Value: Double; CurFrom, CurTo: LPCWSTR; MaxAge: integer;
                  Flags: TVtsCurConvFlags; HistoricDate: TDate): Double; stdcall;
var
  x: TVtsCurConv;
begin
  try
    x := TVtsCurConv.Create;
    try
      x.Secure                 := Flags and CONVERT_USE_SSL <> 0;
      x.MaxAgeSeconds          := MaxAge;
      x.ConfirmWebAccess       := Flags and CONVERT_CONFIRM_WEB_ACCESS <> 0;
      x.FallBackToCache        := Flags and CONVERT_FALLBACK_TO_CACHE <> 0;
      x.InteractiveAPIKeyInput := Flags and CONVERT_NO_INTERACTIVE_API_KEY_INPUT = 0;
      result := x.Convert(value, TVtsCur(CurFrom), TVtsCur(CurTo), HistoricDate);
    finally
      x.Free;
    end;
  except
    on E: Exception do
    begin
      if Flags and CONVERT_DONT_SHOW_ERRORS = 0 then MessageDlg(e.Message, mtError, [mbOk], 0);
      result := -1;
    end;
  end;
end;

function ConvertA(Value: Double; CurFrom, CurTo: LPCSTR; MaxAge: integer;
                  Flags: TVtsCurConvFlags; HistoricDate: TDate): Double; stdcall;
var
  x: TVtsCurConv;
begin
  try
    x := TVtsCurConv.Create;
    try
      x.Secure                 := Flags and CONVERT_USE_SSL <> 0;
      x.MaxAgeSeconds          := MaxAge;
      x.ConfirmWebAccess       := Flags and CONVERT_CONFIRM_WEB_ACCESS <> 0;
      x.FallBackToCache        := Flags and CONVERT_FALLBACK_TO_CACHE <> 0;
      x.InteractiveAPIKeyInput := Flags and CONVERT_NO_INTERACTIVE_API_KEY_INPUT = 0;
      result := x.Convert(value, TVtsCur(CurFrom), TVtsCur(CurTo), HistoricDate);
    finally
      x.Free;
    end;
  except
    on E: Exception do
    begin
      if Flags and CONVERT_DONT_SHOW_ERRORS = 0 then MessageDlg(e.Message, mtError, [mbOk], 0);
      result := -1;
    end;
  end;
end;

function AcceptedCurrenciesW(WriteTo: LPWSTR; MaxAge: integer; Flags: TVtsCurConvFlags;
                             HistoricDate: TDate): Integer; stdcall;
var
  x: TVtsCurConv;
  sl: TStringList;
  s: WideString;
  i: integer;
begin
  try
    x := TVtsCurConv.Create;
    if Assigned(WriteTo) then sl := TStringList.Create else sl := nil;
    try
      x.Secure                 := Flags and CONVERT_USE_SSL <> 0;
      x.MaxAgeSeconds          := MaxAge;
      x.ConfirmWebAccess       := Flags and CONVERT_CONFIRM_WEB_ACCESS <> 0;
      x.FallBackToCache        := Flags and CONVERT_FALLBACK_TO_CACHE <> 0;
      x.InteractiveAPIKeyInput := Flags and CONVERT_NO_INTERACTIVE_API_KEY_INPUT = 0;
      result := x.GetAcceptedCurrencies(sl, HistoricDate);
      if Assigned(WriteTo) then
      begin
        s := '';
        for i := 0 to sl.Count - 1 do s := s + WideString(Trim(sl.Strings[i]));
        ZeroMemory(WriteTo, (3*result+1)*SizeOf(WideChar));
        CopyMemory(WriteTo, @s[1], 3*result*SizeOf(WideChar));
      end;
    finally
      x.Free;
      if Assigned(WriteTo) then sl.Free;
    end;
  except
    on E: Exception do
    begin
      if Flags and CONVERT_DONT_SHOW_ERRORS = 0 then MessageDlg(e.Message, mtError, [mbOk], 0);
      result := -1;
    end;
  end;
end;

function AcceptedCurrenciesA(WriteTo: LPSTR; MaxAge: integer; Flags: TVtsCurConvFlags;
                             HistoricDate: TDate): Integer; stdcall;
var
  x: TVtsCurConv;
  sl: TStringList;
  s: AnsiString;
  i: integer;
begin
  try
    x := TVtsCurConv.Create;
    if Assigned(WriteTo) then sl := TStringList.Create else sl := nil;
    try
      x.Secure                 := Flags and CONVERT_USE_SSL <> 0;
      x.MaxAgeSeconds          := MaxAge;
      x.ConfirmWebAccess       := Flags and CONVERT_CONFIRM_WEB_ACCESS <> 0;
      x.FallBackToCache        := Flags and CONVERT_FALLBACK_TO_CACHE <> 0;
      x.InteractiveAPIKeyInput := Flags and CONVERT_NO_INTERACTIVE_API_KEY_INPUT = 0;
      result := x.GetAcceptedCurrencies(sl, HistoricDate);
      if Assigned(WriteTo) then
      begin
        s := '';
        for i := 0 to sl.Count - 1 do s := s + AnsiString(Trim(sl.Strings[i]));
        ZeroMemory(WriteTo, (3*result+1)*SizeOf(AnsiChar));
        CopyMemory(WriteTo, @s[1], 3*result*SizeOf(AnsiChar));
      end;
    finally
      x.Free;
      if Assigned(WriteTo) then sl.Free;
    end;
  except
    on E: Exception do
    begin
      if Flags and CONVERT_DONT_SHOW_ERRORS = 0 then MessageDlg(e.Message, mtError, [mbOk], 0);
      result := -1;
    end;
  end;
end;

function DownloadNow(Flags: TVtsCurConvFlags; HistoricDate: TDate): HRESULT; stdcall;
var
  x: TVtsCurConv;
begin
  try
    x := TVtsCurConv.Create;
    try
      x.Secure                 := Flags and CONVERT_USE_SSL <> 0;
      x.MaxAgeSeconds          := 0; // Always Download
      x.ConfirmWebAccess       := Flags and CONVERT_CONFIRM_WEB_ACCESS <> 0;
      x.FallBackToCache        := Flags and CONVERT_FALLBACK_TO_CACHE <> 0;
      x.InteractiveAPIKeyInput := Flags and CONVERT_NO_INTERACTIVE_API_KEY_INPUT = 0;
      x.Convert(1, 'USD', 'USD', HistoricDate);
      result := S_VTSCONV_OK
    finally
      x.Free;
    end;
  except
    on E: Exception do
    begin
      if Flags and CONVERT_DONT_SHOW_ERRORS = 0 then MessageDlg(e.Message, mtError, [mbOk], 0);
      result := E_VTSCONV_GENERIC_FAILURE;
    end;
  end;
end;

exports
  DeleteAPIKey,
  WriteAPIKeyW,
  WriteAPIKeyA,
  ReadAPIKeyW,
  ReadAPIKeyA,
  ConvertW,
  ConvertA,
  AcceptedCurrenciesW,
  AcceptedCurrenciesA,
  DownloadNow;

begin
end.
