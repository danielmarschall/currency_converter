library CurConv;

uses
  SysUtils,
  Classes,
  Windows,
  Dialogs,
  System.UITypes,
  uLkJSON in '..\RTL\uLkJSON.pas',
  VtsCurConv in '..\RTL\VtsCurConv.pas';

{$R *.res}

type
  TVtsCurConvFlags = type DWORD;

const
  CONVERT_DONT_SHOW_ERRORS:             TVtsCurConvFlags = 1;
  CONVERT_FALLBACK_TO_CACHE:            TVtsCurConvFlags = 2;
  CONVERT_USE_SSL:                      TVtsCurConvFlags = 4 deprecated 'Since all plans now support SSL, it is enabled by default.';
  CONVERT_CONFIRM_WEB_ACCESS:           TVtsCurConvFlags = 8;
  CONVERT_NO_INTERACTIVE_API_KEY_INPUT: TVtsCurConvFlags = 16;

type
  TVtsCurConvKeyStoreMode = type DWORD;

const
  CONVERT_KEYSTORE_REGISTRY_SYSTEM     {:TVtsCurConvKeyStoreMode} = 0;
  CONVERT_KEYSTORE_REGISTRY_USER       {:TVtsCurConvKeyStoreMode} = 1;
  CONVERT_KEYSTORE_MEMORY              {:TVtsCurConvKeyStoreMode} = 2;

const
  S_VTSCONV_OK:                HRESULT = HRESULT($20000000); // Success, Customer defined, Facility 0, Code 0
  S_VTSCONV_NOTHING:           HRESULT = HRESULT($20000001); // Success, Customer defined, Facility 0, Code 1
  E_VTSCONV_GENERIC_FAILURE:   HRESULT = HRESULT($A0000000); // Failure, Customer defined, Facility 0, Code 0
  E_VTSCONV_BAD_ARGS:          HRESULT = HRESULT($A0000001); // Failure, Customer defined, Facility 0, Code 1
  E_VTSCONV_STOREDKEY_INVALID: HRESULT = HRESULT($A0000002); // Failure, Customer defined, Facility 0, Code 2
  E_VTSCONV_NO_STOREDKEY:      HRESULT = HRESULT($A0000003); // Failure, Customer defined, Facility 0, Code 3

resourcestring
  SBadArguments = 'Method called with bad arguments';
  SNoStoredKey = 'No stored API Key';
  SStoredKeyInvalid = 'Stored API Key is invalid';

var
  GTempApiKey: string;

procedure _WipeString(var S: string);
var
  P: PChar;
  Len: Integer;
begin
  Len := Length(S);
  if Len > 0 then
  begin
    // Direkten Zugriff auf die Zeichen im Speicher
    P := PChar(S);
    FillChar(P^, Len * SizeOf(Char), 0);  // Speicher mit Nullen füllen
  end;
  S := '';  // Den String leeren
end;

{$REGION 'DeleteAPIKey'}
function DeleteAPIKey(Mode: TVtsCurConvKeyStoreMode; DontShowErrors: BOOL): HRESULT; stdcall;
begin
  try
    case Mode of
      CONVERT_KEYSTORE_REGISTRY_SYSTEM:
      begin
        if TVtsCurConv.DeleteAPIKey({UserMode:}false) then
          result := S_VTSCONV_OK
        else
          result := S_VTSCONV_NOTHING;
      end;
      CONVERT_KEYSTORE_REGISTRY_USER:
      begin
        if TVtsCurConv.DeleteAPIKey({UserMode:}true) then
          result := S_VTSCONV_OK
        else
          result := S_VTSCONV_NOTHING;
      end;
      CONVERT_KEYSTORE_MEMORY:
      begin
        if GTempApiKey <> '' then
        begin
          _WipeString(GTempApiKey);
          result := S_VTSCONV_OK;
        end
        else
        begin
          result := S_VTSCONV_NOTHING;
        end;
      end
      else
      begin
        if DontShowErrors then MessageDlg(SBadArguments, mtError, [mbOk], 0);
        result := E_VTSCONV_BAD_ARGS;
        Exit;
      end;
    end;
  except
    on E: Exception do
    begin
      if DontShowErrors then MessageDlg(e.Message, mtError, [mbOk], 0);
      result := E_VTSCONV_GENERIC_FAILURE;
    end;
  end;
end;
{$ENDREGION}

{$REGION 'WriteAPIKeyA, WriteAPIKeyW'}
function WriteAPIKeyW(key: LPCWSTR; Mode: TVtsCurConvKeyStoreMode; DontShowErrors: BOOL): HRESULT; stdcall;
begin
  try
    if Length(key) <> 32 then
    begin
      if DontShowErrors then MessageDlg(SBadArguments, mtError, [mbOk], 0);
      result := E_VTSCONV_BAD_ARGS;
      Exit;
    end;
    case Mode of
      CONVERT_KEYSTORE_REGISTRY_SYSTEM:
      begin
        TVtsCurConv.WriteAPIKey(TVtsCurApiKey(key), {UserMode:}false);
      end;
      CONVERT_KEYSTORE_REGISTRY_USER:
      begin
        TVtsCurConv.WriteAPIKey(TVtsCurApiKey(key), {UserMode:}true);
      end;
      CONVERT_KEYSTORE_MEMORY:
      begin
        _WipeString(GTempApiKey);
        GTempApiKey := Key;
      end
      else
      begin
        if DontShowErrors then MessageDlg(SBadArguments, mtError, [mbOk], 0);
        result := E_VTSCONV_BAD_ARGS;
        Exit;
      end;
    end;
    result := S_VTSCONV_OK;
  except
    on E: Exception do
    begin
      if DontShowErrors then MessageDlg(e.Message, mtError, [mbOk], 0);
      result := E_VTSCONV_GENERIC_FAILURE;
    end;
  end;
end;

function WriteAPIKeyA(key: LPCSTR; Mode: TVtsCurConvKeyStoreMode; DontShowErrors: BOOL): HRESULT; stdcall;
begin
  try
    if Length(key) <> 32 then
    begin
      if DontShowErrors then MessageDlg(SBadArguments, mtError, [mbOk], 0);
      result := E_VTSCONV_BAD_ARGS;
      Exit;
    end;
    case Mode of
      CONVERT_KEYSTORE_REGISTRY_SYSTEM:
      begin
        TVtsCurConv.WriteAPIKey(TVtsCurApiKey(key), {UserMode:}false);
      end;
      CONVERT_KEYSTORE_REGISTRY_USER:
      begin
        TVtsCurConv.WriteAPIKey(TVtsCurApiKey(key), {UserMode:}true);
      end;
      CONVERT_KEYSTORE_MEMORY:
      begin
        _WipeString(GTempApiKey);
        GTempApiKey := String(Key);
      end
      else
      begin
        if DontShowErrors then MessageDlg(SBadArguments, mtError, [mbOk], 0);
        result := E_VTSCONV_BAD_ARGS;
        Exit;
      end;
    end;
    result := S_VTSCONV_OK;
  except
    on E: Exception do
    begin
      if DontShowErrors then MessageDlg(e.Message, mtError, [mbOk], 0);
      result := E_VTSCONV_GENERIC_FAILURE;
    end;
  end;
end;
{$ENDREGION}

{$REGION 'ReadAPIKeyA, ReadAPIKeyW'}
// TODO: Why no "Mode" parameter?!
function ReadAPIKeyW(key: LPWSTR; DontShowErrors: BOOL): HRESULT; stdcall;
var
  s: WideString;
begin
  try
    if GTempApiKey <> '' then
      s := GTempApiKey
    else
      s := WideString(TVtsCurConv.ReadAPIKey);
    if s = '' then
    begin
      if DontShowErrors then MessageDlg(SNoStoredKey, mtError, [mbOk], 0);
      result := E_VTSCONV_NO_STOREDKEY;
      Exit;
    end;
    if Length(s) <> 32 then
    begin
      if DontShowErrors then MessageDlg(SStoredKeyInvalid, mtError, [mbOk], 0);
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

// TODO: Why no "Mode" parameter?!
function ReadAPIKeyA(key: LPSTR; DontShowErrors: BOOL): HRESULT; stdcall;
var
  s: AnsiString;
begin
  try
    if GTempApiKey <> '' then
      s := AnsiString(GTempApiKey)
    else
      s := AnsiString(TVtsCurConv.ReadAPIKey);
    if s = '' then
    begin
      if DontShowErrors then MessageDlg(SNoStoredKey, mtError, [mbOk], 0);
      result := E_VTSCONV_NO_STOREDKEY;
      Exit;
    end;
    if Length(s) <> 32 then
    begin
      if DontShowErrors then MessageDlg(SStoredKeyInvalid, mtError, [mbOk], 0);
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
{$ENDREGION}

{$REGION 'ConvertA, ConvertExA, ConvertW, ConvertExW'}

function ConvertExW(Value: Double; CurFrom, CurTo: LPCWSTR; MaxAge: integer;
                    Flags: TVtsCurConvFlags; HistoricDate: TDate;
                    OutValue: PDouble; OutTimeStamp: PDateTime): HRESULT; stdcall;
var
  x: TVtsCurConv;
  r: TVtsCurConvResult;
begin
  try
    x := TVtsCurConv.Create;
    try
      x.Secure                 := true; // Flags and CONVERT_USE_SSL <> 0;
      x.MaxAgeSeconds          := MaxAge;
      x.ConfirmWebAccess       := Flags and CONVERT_CONFIRM_WEB_ACCESS <> 0;
      x.FallBackToCache        := Flags and CONVERT_FALLBACK_TO_CACHE <> 0;
      x.InteractiveAPIKeyInput := Flags and CONVERT_NO_INTERACTIVE_API_KEY_INPUT = 0;
      if GTempApiKey <> '' then x.SetTempApiKey(GTempApiKey);
      r := x.Convert(value, TVtsCur(CurFrom), TVtsCur(CurTo), HistoricDate);
      OutValue^ := r.Value;
      OutTimeStamp^ := r.Timestamp;
      Result := S_VTSCONV_OK;
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

function ConvertW(Value: Double; CurFrom, CurTo: LPCWSTR; MaxAge: integer;
                  Flags: TVtsCurConvFlags; HistoricDate: TDate): Double; stdcall;
                  deprecated 'use ConvertExW';
var
  DummyTimestamp: TDateTime;
begin
  ConvertExW(Value, CurFrom, CurTo, MaxAge, Flags, HistoricDate, @Result, @DummyTimestamp);
end;

function ConvertExA(Value: Double; CurFrom, CurTo: LPCSTR; MaxAge: integer;
                    Flags: TVtsCurConvFlags; HistoricDate: TDate;
                    OutValue: PDouble; OutTimestamp: PDateTime): HRESULT; stdcall;
var
  x: TVtsCurConv;
  r: TVtsCurConvResult;
begin
  try
    x := TVtsCurConv.Create;
    try
      x.Secure                 := true; // Flags and CONVERT_USE_SSL <> 0;
      x.MaxAgeSeconds          := MaxAge;
      x.ConfirmWebAccess       := Flags and CONVERT_CONFIRM_WEB_ACCESS <> 0;
      x.FallBackToCache        := Flags and CONVERT_FALLBACK_TO_CACHE <> 0;
      x.InteractiveAPIKeyInput := Flags and CONVERT_NO_INTERACTIVE_API_KEY_INPUT = 0;
      if GTempApiKey <> '' then x.SetTempApiKey(GTempApiKey);
      r := x.Convert(value, TVtsCur(CurFrom), TVtsCur(CurTo), HistoricDate);
      OutValue^ := r.Value;
      OutTimeStamp^ := r.Timestamp;
      Result := S_VTSCONV_OK;
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

function ConvertA(Value: Double; CurFrom, CurTo: LPCSTR; MaxAge: integer;
                  Flags: TVtsCurConvFlags; HistoricDate: TDate): Double; stdcall;
                  deprecated 'use ConvertExA';
var
  DummyTimestamp: TDateTime;
begin
  ConvertExA(Value, CurFrom, CurTo, MaxAge, Flags, HistoricDate, @Result, @DummyTimestamp);
end;

{$ENDREGION}

{$REGION 'AcceptedCurrenciesA, AcceptedCurrenciesExA, AcceptedCurrenciesW, AcceptedCurrenciesExW'}

function AcceptedCurrenciesExW(WriteTo: LPWSTR; MaxAge: integer; Flags: TVtsCurConvFlags;
                               HistoricDate: TDate; OutElements: PInteger): HRESULT; stdcall;
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
      x.Secure                 := true; // Flags and CONVERT_USE_SSL <> 0;
      x.MaxAgeSeconds          := MaxAge;
      x.ConfirmWebAccess       := Flags and CONVERT_CONFIRM_WEB_ACCESS <> 0;
      x.FallBackToCache        := Flags and CONVERT_FALLBACK_TO_CACHE <> 0;
      x.InteractiveAPIKeyInput := Flags and CONVERT_NO_INTERACTIVE_API_KEY_INPUT = 0;
      if GTempApiKey <> '' then x.SetTempApiKey(GTempApiKey);
      OutElements^ := x.GetAcceptedCurrencies(sl, HistoricDate);
      if Assigned(WriteTo) then
      begin
        s := '';
        for i := 0 to sl.Count - 1 do s := s + WideString(Trim(sl.Strings[i]));
        ZeroMemory(WriteTo, (3*OutElements^+1)*SizeOf(WideChar));
        CopyMemory(WriteTo, @s[1], 3*OutElements^*SizeOf(WideChar));
      end;
      Result := S_VTSCONV_OK;
    finally
      x.Free;
      if Assigned(WriteTo) then sl.Free;
    end;
  except
    on E: Exception do
    begin
      if Flags and CONVERT_DONT_SHOW_ERRORS = 0 then MessageDlg(e.Message, mtError, [mbOk], 0);
      result := E_VTSCONV_GENERIC_FAILURE;
    end;
  end;
end;

function AcceptedCurrenciesW(WriteTo: LPWSTR; MaxAge: integer; Flags: TVtsCurConvFlags;
                             HistoricDate: TDate): Integer; stdcall;
                             deprecated 'use AcceptedCurrenciesExW';
begin
  AcceptedCurrenciesExW(WriteTo, MaxAge, Flags, HistoricDate, @Result);
end;

function AcceptedCurrenciesExA(WriteTo: LPSTR; MaxAge: integer; Flags: TVtsCurConvFlags;
                               HistoricDate: TDate; OutElements: PInteger): HRESULT; stdcall;
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
      x.Secure                 := true; // Flags and CONVERT_USE_SSL <> 0;
      x.MaxAgeSeconds          := MaxAge;
      x.ConfirmWebAccess       := Flags and CONVERT_CONFIRM_WEB_ACCESS <> 0;
      x.FallBackToCache        := Flags and CONVERT_FALLBACK_TO_CACHE <> 0;
      x.InteractiveAPIKeyInput := Flags and CONVERT_NO_INTERACTIVE_API_KEY_INPUT = 0;
      if GTempApiKey <> '' then x.SetTempApiKey(GTempApiKey);
      OutElements^ := x.GetAcceptedCurrencies(sl, HistoricDate);
      if Assigned(WriteTo) then
      begin
        s := '';
        for i := 0 to sl.Count - 1 do s := s + AnsiString(Trim(sl.Strings[i]));
        ZeroMemory(WriteTo, (3*OutElements^+1)*SizeOf(AnsiChar));
        CopyMemory(WriteTo, @s[1], 3*OutElements^*SizeOf(AnsiChar));
      end;
      result := S_VTSCONV_OK;
    finally
      x.Free;
      if Assigned(WriteTo) then sl.Free;
    end;
  except
    on E: Exception do
    begin
      if Flags and CONVERT_DONT_SHOW_ERRORS = 0 then MessageDlg(e.Message, mtError, [mbOk], 0);
      result := E_VTSCONV_GENERIC_FAILURE;
    end;
  end;
end;

function AcceptedCurrenciesA(WriteTo: LPSTR; MaxAge: integer; Flags: TVtsCurConvFlags;
                             HistoricDate: TDate): Integer; stdcall;
                             deprecated 'use AcceptedCurrenciesExA';
begin
  AcceptedCurrenciesExA(WriteTo, MaxAge, Flags, HistoricDate, @Result);
end;

{$ENDREGION}

{$REGION 'DownloadNow'}
function DownloadNow(Flags: TVtsCurConvFlags; HistoricDate: TDate): HRESULT; stdcall;
var
  x: TVtsCurConv;
begin
  try
    x := TVtsCurConv.Create;
    try
      x.Secure                 := true; // Flags and CONVERT_USE_SSL <> 0;
      x.MaxAgeSeconds          := 0; // Always Download
      x.ConfirmWebAccess       := Flags and CONVERT_CONFIRM_WEB_ACCESS <> 0;
      x.FallBackToCache        := Flags and CONVERT_FALLBACK_TO_CACHE <> 0;
      x.InteractiveAPIKeyInput := Flags and CONVERT_NO_INTERACTIVE_API_KEY_INPUT = 0;
      if GTempApiKey <> '' then x.SetTempApiKey(GTempApiKey);
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
{$ENDREGION}

exports
  DeleteAPIKey,
  WriteAPIKeyW,
  WriteAPIKeyA,
  ReadAPIKeyW,
  ReadAPIKeyA,
  ConvertW,
  ConvertExW,
  ConvertA,
  ConvertExA,
  AcceptedCurrenciesW,
  AcceptedCurrenciesA,
  AcceptedCurrenciesExW,
  AcceptedCurrenciesExA,
  DownloadNow;

begin
end.
