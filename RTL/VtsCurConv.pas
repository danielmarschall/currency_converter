unit VtsCurConv;

interface

uses
  SysUtils, Classes, Controls;

type
  EVtsCurConvException = class(Exception);

  TVtsCurApiKey = string;
  TVtsCur = string;
  TVtsRate = double;

  TVtsCurConv = class(TObject)
  private
    FSecure: boolean;
    FMaxAgeSeconds: integer;
    FConfirmWebAccess: boolean;
    FFallBackToCache: boolean;
    FInteractiveAPIKeyInput: boolean;
  protected
    function GetJsonRaw(HistoricDate: TDate=0): string;
    procedure QueryAPIKey(msg: string=''); virtual;
  public
    property Secure: boolean read FSecure write FSecure;
    property MaxAgeSeconds: integer read FMaxAgeSeconds write FMaxAgeSeconds;
    property ConfirmWebAccess: boolean read FConfirmWebAccess write FConfirmWebAccess;
    property FallBackToCache: boolean read FFallBackToCache write FFallBackToCache;
    property InteractiveAPIKeyInput: boolean read FInteractiveAPIKeyInput write FInteractiveAPIKeyInput;
    class procedure WriteAPIKey(key: TVtsCurApiKey; UserMode: boolean=true);
    class function ReadAPIKey: TVtsCurApiKey;
    class function DeleteAPIKey(UserMode: boolean=true): boolean;
    function Convert(value: Currency; fromCur, toCur: TVtsCur; HistoricDate: TDate=0): Currency;
    function GetAcceptedCurrencies(sl: TStringList=nil; HistoricDate: TDate=0): integer;
  end;

implementation

uses
  Windows, Registry, uLkJSON, Dialogs, IdHTTP, DateUtils;

function FileGetContents(filename: string): string;
var
  sl: TStringList;
begin
  sl := TStringList.Create;
  try
    sl.LoadFromFile(filename);
    result := sl.Text;
  finally
    sl.Free;
  end;
end;

procedure FilePutContents(filename, content: string);
var
  sl: TStringList;
begin
  sl := TStringList.Create;
  try
    sl.Text := content;
    sl.SaveToFile(filename);
  finally
    sl.Free;
  end;
end;

function GetPage(aURL: string): string;
var
  Response: TStringStream;
  HTTP: TIdHTTP;
const
  HTTP_RESPONSE_OK = 200;
begin
  // https://stackoverflow.com/questions/9239267/how-to-download-a-web-page-into-a-variable
  Result := '';
  Response := TStringStream.Create('');
  try
    HTTP := TIdHTTP.Create(nil);
    try
      HTTP.Get(aURL, Response);
      if HTTP.ResponseCode = HTTP_RESPONSE_OK then
        Result := Response.DataString
      else
        raise EVtsCurConvException.CreateFmt('Cannot download from %s', [aURL]);
    finally
      HTTP.Free;
    end;
  finally
    Response.Free;
  end;
end;

function GetTempDir: string;
var
  Dir: string;
  Len: DWord;
begin
  SetLength(Dir, MAX_PATH);
  Len := GetTempPath(MAX_PATH, PChar(Dir));
  if Len > 0 then
  begin
    SetLength(Dir, Len);
    Result := Dir;
  end
  else
    RaiseLastOSError;
end;

{ TVtsCurConv }

class procedure TVtsCurConv.WriteAPIKey(key: TVtsCurApiKey; UserMode: boolean=true);
  procedure _WriteAPIKey(root: HKEY);
  var
    reg: TRegistry;
  begin
    reg := TRegistry.Create;
    try
      reg.RootKey := root;
      if reg.OpenKey('Software\ViaThinkSoft\CurrencyConverter', true) then
      begin
        reg.WriteString('APIKey', key);
        reg.CloseKey;
      end
      else raise EVtsCurConvException.Create('Cannot open registry key');
    finally
      reg.Free;
    end;
  end;
begin
  if UserMode then
    _WriteAPIKey(HKEY_CURRENT_USER)
  else
    _WriteAPIKey(HKEY_LOCAL_MACHINE);
end;

class function TVtsCurConv.DeleteAPIKey(UserMode: boolean=true): boolean;
  procedure _DeleteAPIKey(root: HKEY);
  var
    reg: TRegistry;
  begin
    reg := TRegistry.Create;
    try
      reg.RootKey := root;
      if reg.OpenKey('Software\ViaThinkSoft\CurrencyConverter', true) then
      begin
        result := reg.DeleteValue('APIKey');
        reg.CloseKey;
      end;
    finally
      reg.Free;
    end;
  end;
begin
  result := false;
  if UserMode then
    _DeleteAPIKey(HKEY_CURRENT_USER)
  else
    _DeleteAPIKey(HKEY_LOCAL_MACHINE);
end;

class function TVtsCurConv.ReadAPIKey: TVtsCurApiKey;
  function _ReadAPIKey(root: HKEY): string;
  var
    reg: TRegistry;
  begin
    result := '';
    reg := TRegistry.Create;
    try
      reg.RootKey := root;
      if reg.OpenKeyReadOnly('Software\ViaThinkSoft\CurrencyConverter') then
      begin
        if reg.ValueExists('APIKey') then result := reg.ReadString('APIKey');
        reg.CloseKey;
      end;
    finally
      reg.Free;
    end;
  end;
begin
  result := _ReadAPIKey(HKEY_CURRENT_USER);
  if result = '' then result := _ReadAPIKey(HKEY_LOCAL_MACHINE);
end;

function TVtsCurConv.Convert(value: Currency; fromCur, toCur: TVtsCur; HistoricDate: TDate=0): Currency;
var
  rateTo, rateFrom: TVtsRate;
  i: Integer;
  rateToFound: Boolean;
  rateFromFound: Boolean;
  sJSON: String;
  xSource: TlkJSONstring;
  xRoot: TlkJSONobject;
  xQuotes: TlkJSONobject;
  xRate: TlkJSONnumber;
begin
  result := 0; // to avoid that the compiler shows a warning

  fromCur := Trim(UpperCase(fromCur));
  toCur := Trim(UpperCase(toCur));

  sJSON := GetJsonRaw(HistoricDate);

  xRoot := TlkJSON.ParseText(sJSON) as TlkJSONobject;
  try
    xSource := xRoot.Field['source'] as TlkJSONstring;
    if not assigned(xSource) then raise EVtsCurConvException.Create('JSON entry "source" is missing!');

    xQuotes := xRoot.Field['quotes'] as TlkJSONobject;
    if not assigned(xQuotes) then raise EVtsCurConvException.Create('JSON entry "quotes" is missing!');

    rateToFound := false;
    rateFromFound := false;
    rateTo := 0.00; // to avoid that the compiler shows a warning
    rateFrom := 0.00; // to avoid that the compiler shows a warning

    for i := 0 to xQuotes.Count - 1 do
    begin
      if Length(xQuotes.NameOf[i]) <> 6 then raise EVtsCurConvException.Create('Length of quotes-entry is unexpected!');

      xRate := xQuotes.Field[xQuotes.NameOf[i]] as TlkJSONnumber;
      if not Assigned(xRate) then raise EVtsCurConvException.Create('JSON entry quotes->rate is missing!');

      if Copy(xQuotes.NameOf[i], 1, 3) = xSource.Value then
      begin
        if Copy(xQuotes.NameOf[i], 4, 3) = toCur then
        begin
          rateTo := xRate.Value;
          rateToFound := true;
        end;
        if Copy(xQuotes.NameOf[i], 4, 3) = fromCur then
        begin
          rateFrom := xRate.Value;
          rateFromFound := true;
        end;
      end;
    end;

    if not rateToFound then raise EVtsCurConvException.CreateFmt('Currency "%s" not supported', [toCur]);
    if not rateFromFound then raise EVtsCurConvException.CreateFmt('Currency "%s" not supported', [fromCur]);

    result := value * rateTo / rateFrom;
  finally
    xRoot.Free;
  end;
end;

procedure TVtsCurConv.QueryAPIKey(msg: string='');
var
  s: string;
begin
  s := Trim(InputBox('currencylayer.com', Trim(msg + ' Please enter your API key:'), ''));
  if s = '' then raise EVtsCurConvException.Create('No API key provided.');
  WriteAPIKey(s);
end;

function TVtsCurConv.GetAcceptedCurrencies(sl: TStringList=nil; HistoricDate: TDate=0): integer;
var
  i: Integer;
  sJSON: String;
  xSource: TlkJSONstring;
  xRoot: TlkJSONobject;
  xQuotes: TlkJSONobject;
begin
  result := 0;

  sJSON := GetJsonRaw(HistoricDate);

  xRoot := TlkJSON.ParseText(sJSON) as TlkJSONobject;
  try
    xSource := xRoot.Field['source'] as TlkJSONstring;
    if not assigned(xSource) then raise EVtsCurConvException.Create('JSON entry "source" is missing!');

    xQuotes := xRoot.Field['quotes'] as TlkJSONobject;
    if not assigned(xQuotes) then raise EVtsCurConvException.Create('JSON entry "quotes" is missing!');

    for i := 0 to xQuotes.Count - 1 do
    begin
      if Length(xQuotes.NameOf[i]) <> 6 then raise EVtsCurConvException.Create('Length of quotes-entry is unexpected!');

      if Copy(xQuotes.NameOf[i], 1, 3) = xSource.Value then
      begin
        Inc(result);
        if Assigned(sl) then sl.Add(Copy(xQuotes.NameOf[i], 4, 3));
      end;
    end;
  finally
    xRoot.Free;
  end;
end;

function TVtsCurConv.GetJsonRaw(HistoricDate: TDate=0): string;

  procedure _HandleKeyInvalidOrMissing(cacheFileName: string; msg: string; out doRetry: boolean; out json: string);
  begin
    if FallBackToCache then
    begin
      if not InteractiveAPIKeyInput then
      begin
        json := FileGetContents(cacheFileName);
        doRetry := false;
      end
      else
      begin
        if MessageDlg(Trim(msg + ' Do you want to enter a new one?'), mtError, mbYesNoCancel, 0) = ID_YES then
        begin
          QueryAPIKey;
          doRetry := true;
        end
        else
        begin
          json := FileGetContents(cacheFileName);
          doRetry := false;
        end;
      end;
    end
    else // if not FallBackToCache then
    begin
      if not InteractiveAPIKeyInput then
      begin
        raise EVtsCurConvException.Create(msg);
      end
      else
      begin
        QueryAPIKey(msg);
        doRetry := true;
      end;
    end;
  end;

var
  sJSON, msg, protocol: string;
  xRoot: TlkJSONobject;
  xSuccess: TlkJSONboolean;
  keyInvalid, doRetry: boolean;
  sDate: string;
  url: string;
  cacheDirName, cacheFileName: string;
  needDownload: boolean;
  mTime: TDateTime;
begin
  try
    {$REGION 'Determinate file location and URL'}
    // cacheDirName := IncludeTrailingPathDelimiter(GetSpecialPath(CSIDL_PROGRAM_FILES_COMMON)) + 'ViaThinkSoft\CurrencyConverter\';
    cacheDirName := IncludeTrailingPathDelimiter(GetTempDir) + 'ViaThinkSoft\CurrencyConverter\';
    if not ForceDirectories(cacheDirName) then
    begin
      raise EVtsCurConvException.CreateFmt('Cannot create directory %s', [cacheDirName]);
    end;

    if Secure then protocol := 'https' else protocol := 'http';
    if HistoricDate = 0 then
    begin
      sDate := '';
      url := protocol + '://www.apilayer.net/api/live?access_key=' + ReadAPIKey;
      cacheFileName := IncludeTrailingPathDelimiter(cacheDirName) + 'live.json';
    end
    else
    begin
      DateTimeToString(sDate, 'YYYY-MM-DD', HistoricDate);
      url := protocol + '://www.apilayer.net/api/historical?date=' + sDate + '&access_key=' + ReadAPIKey;
      cacheFileName := IncludeTrailingPathDelimiter(cacheDirName) + 'historical-' + sDate + '.json';
    end;
    {$ENDREGION}

    {$REGION 'Determinate if we need to download or not'}
    if HistoricDate = 0 then
    begin
      needDownload := true;
      if MaxAgeSeconds < -1 then
      begin
        raise EVtsCurConvException.Create('Invalid maxage');
      end
      else if MaxAgeSeconds = -1 then
      begin
        // Only download once
        needDownload := not FileExists(cacheFileName);
      end
      else if MaxAgeSeconds = 0 then
      begin
        // Always download
        needDownload := true;
      end
      else if MaxAgeSeconds > 0 then
      begin
        // Download if older than <MaxAge> seconds
        FileAge(cacheFileName, mTime);
        needDownload := not FileExists(cacheFileName) or (SecondsBetween(Now, mTime) > MaxAgeSeconds);
      end;
    end
    else
    begin
      needDownload := not FileExists(cacheFileName)
    end;
    {$ENDREGION}

    if not needDownload then
    begin
      sJSON := FileGetContents(cacheFileName);
    end
    else
    begin
      doRetry := false;

      {$REGION 'Is an API key available?'}
      if ReadAPIKey = '' then
      begin
        _HandleKeyInvalidOrMissing(cacheFileName, 'No API key provided.', doRetry, sJSON);
        if not doRetry then
        begin
          result := sJSON;
          Exit;
        end;
      end;
      {$ENDREGION}

      {$REGION 'Download and check if everything is OK'}
      repeat
        {$REGION 'Confirm web access?'}
        if ConfirmWebAccess and (MessageDlg('Download ' + url + ' to ' + cacheFileName + ' ?', mtConfirmation, mbYesNoCancel, 0) <> ID_YES) then
        begin
          if FallBackToCache then
          begin
            result := FileGetContents(cacheFileName);
            Exit;
          end
          else Abort;
        end;
        {$ENDREGION}

        doRetry := false;

        sJSON := GetPage(url);

        xRoot := TlkJSON.ParseText(sJSON) as TlkJSONobject;
        if not assigned(xRoot) then raise EVtsCurConvException.Create('JSON file invalid');

        xSuccess := xRoot.Field['success'] as TlkJSONboolean;
        if not assigned(xSuccess) then raise EVtsCurConvException.Create('Cannot determinate status of the query.');

        if xSuccess.Value then
        begin
          try
            FilePutContents(cacheFileName, sJSON);
          except
            // Since this is only a cache, we should not break the whole process if only the saving fails
          end;
        end
        else
        begin
          {$REGION 'Get information of the error'}
          try
            keyInvalid := xRoot.Field['error'].Field['code'].Value = 101;
            msg := Format('%s (%s, %s)', [
              xRoot.Field['error'].Field['info'].Value,
              xRoot.Field['error'].Field['code'].Value,
              xRoot.Field['error'].Field['type'].Value]);
          except
            keyInvalid := false;
            msg := 'Unknown error while loading JSON.';
          end;
          {$ENDREGION}

          if keyInvalid then
          begin
            _HandleKeyInvalidOrMissing(cacheFileName, 'API key invalid.', doRetry, sJSON);
          end
          else // if not keyInvalid then
          begin
            if FallBackToCache then
            begin
              result := FileGetContents(cacheFileName);
              Exit;
            end
            else
            begin
              raise EVtsCurConvException.Create(msg);
            end;
          end;
        end;
      until not doRetry;
      {$ENDREGION}
    end;

    result := sJSON;
  finally
    FreeAndNil(xRoot);
  end;
end;

end.
