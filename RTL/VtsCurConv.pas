unit VtsCurConv;

interface

uses
  SysUtils, Classes;

type
  EVtsCurConvException = class(Exception);

  TVtsCurApiKey = string;
  TVtsCur = string;
  TVtsRate = double;
  TVtsCurConvResult = record
    Value: Currency;
    Timestamp: TDateTime;
  end;

  TVtsCurConv = class(TObject)
  private
    FSecure: boolean;
    FMaxAgeSeconds: integer;
    FConfirmWebAccess: boolean;
    FFallBackToCache: boolean;
    FInteractiveAPIKeyInput: boolean;
    FTempApiKey: string;
  protected
    function GetJsonRaw(HistoricDate: TDate=0): string;
    procedure QueryAPIKey(msg: string=''); virtual;
  public
    property Secure: boolean read FSecure write FSecure;
    property MaxAgeSeconds: integer read FMaxAgeSeconds write FMaxAgeSeconds;
    property ConfirmWebAccess: boolean read FConfirmWebAccess write FConfirmWebAccess;
    property FallBackToCache: boolean read FFallBackToCache write FFallBackToCache;
    property InteractiveAPIKeyInput: boolean read FInteractiveAPIKeyInput write FInteractiveAPIKeyInput;
    procedure SetTempApiKey(const ApiKey: String);
    procedure RemoveTempApiKey;
    class procedure WriteAPIKey(key: TVtsCurApiKey; UserMode: boolean=true);
    class function ReadAPIKey: TVtsCurApiKey;
    class function DeleteAPIKey(UserMode: boolean=true): boolean;
    function Convert(value: Currency; fromCur, toCur: TVtsCur; HistoricDate: TDate=0): TVtsCurConvResult;
    function GetAcceptedCurrencies(sl: TStringList=nil; HistoricDate: TDate=0): integer;
    destructor Destroy; override;
  end;

implementation

uses
  Windows, Registry, uLkJSON, wininet, Dialogs, DateUtils, Math, System.UITypes;

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

function WinInet_DoGet(const Url: string): string;

  const
    USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';
    MaxRedirects = 5;

  function GetRedirectLocation(hRequest: HINTERNET): string;
  var
    Buffer: array[0..1023] of Char;
    BufferLength, HeaderIndex: DWORD;
  begin
    Result := '';
    BufferLength := SizeOf(Buffer);
    HeaderIndex := 0;

    // Query the "Location" header to get the new URL for redirection
    if HttpQueryInfo(hRequest, HTTP_QUERY_LOCATION, @Buffer, BufferLength, HeaderIndex) then
      Result := string(Buffer);
  end;

  function GetStatusCode(hRequest: HINTERNET): DWORD;
  var
    StatusCode: DWORD;
    StatusCodeLen: DWORD;
    HeaderIndex: DWORD;
  begin
    StatusCode := 0;
    StatusCodeLen := SizeOf(StatusCode);
    HeaderIndex := 0;

    // Query the status code from the HTTP response
    if HttpQueryInfo(hRequest, HTTP_QUERY_STATUS_CODE or HTTP_QUERY_FLAG_NUMBER, @StatusCode, StatusCodeLen, HeaderIndex) then
      Result := StatusCode
    else
      Result := 0;
  end;

var
  AUrl: string;
  databuffer : array[0..4095] of ansichar; // SIC! ansichar!
  Response : ansistring; // SIC! ansistring
  hSession, hRequest: hInternet;
  dwread,dwNumber: cardinal;
  Str    : pansichar; // SIC! pansichar
  StatusCode: DWORD;
  RedirectCount: integer;
begin
  Response:='';
  AUrl := Url;

  hSession:=InternetOpen(USER_AGENT, INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if not Assigned(hSession) then
    raise Exception.Create('Error initializing WinInet: ' + SysErrorMessage(GetLastError));
  try
    RedirectCount := 0;
    while true do
    begin
      hRequest:=InternetOpenUrl(hsession, pchar(AUrl), nil, 0, INTERNET_FLAG_RELOAD, 0);
      if not Assigned(hRequest) then
        raise Exception.Create('Error opening request: ' + SysErrorMessage(GetLastError));
      try
        StatusCode := GetStatusCode(hRequest);
        if (StatusCode >= 300) and (StatusCode < 400) then
        begin
          Inc(RedirectCount);

          // Stop following redirects if we exceed the maximum number of allowed redirects.
          if RedirectCount > MaxRedirects then
          begin
            raise Exception.Create('Error: Too many redirects');
          end;

          // Get the "Location" header for the new URL
          AURL := GetRedirectLocation(hRequest);
        end
        else if (StatusCode = 200) then // do not localize
        begin
          dwNumber := 1024;
          while (InternetReadfile(hRequest, @databuffer, dwNumber, DwRead)) do
          begin
            if dwRead =0 then
              break;
            databuffer[dwread]:=#0;
            Str := pansichar(@databuffer);
            Response := Response + Str;
          end;

          // Output the server response.
          Result := Response;

          break;
        end
        else
          raise Exception.CreateFmt('HTTP Error %d with GET request %s', [StatusCode, aurl]);
      finally
        InternetCloseHandle(hRequest);
      end;
    end;
  finally
    InternetCloseHandle(hsession);
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
  resourcestring
    S_CANNOT_OPEN_REGISTRY = 'Cannot open registry key';
  begin
    reg := TRegistry.Create;
    try
      reg.RootKey := root;
      if reg.OpenKey('Software\ViaThinkSoft\CurrencyConverter', true) then
      begin
        reg.WriteString('APIKey', key);
        reg.CloseKey;
      end
      else raise EVtsCurConvException.Create(S_CANNOT_OPEN_REGISTRY);
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

destructor TVtsCurConv.Destroy;
begin
  RemoveTempApiKey;
  inherited;
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

procedure TVtsCurConv.RemoveTempApiKey;

  procedure _WipeString(var S: string);
  var
    P: PChar;
    Len: Integer;
  begin
    UniqueString(S); // because other strings could share the memory of this string
    Len := Length(S);
    if Len > 0 then
    begin
      // Direkten Zugriff auf die Zeichen im Speicher
      P := PChar(S);
      FillChar(P^, Len * SizeOf(Char), 0);  // Speicher mit Nullen füllen
    end;
    S := '';  // Den String leeren
  end;

begin
  _WipeString(FTempApiKey);
end;

procedure TVtsCurConv.SetTempApiKey(const ApiKey: String);
begin
  RemoveTempApiKey;
  FTempApiKey := ApiKey;
end;

function TVtsCurConv.Convert(value: Currency; fromCur, toCur: TVtsCur; HistoricDate: TDate=0): TVtsCurConvResult;

  function UnixToDateTimeWithSystemTime(UnixTime: Int64): TDateTime;
  begin
    // Umwandlung von Unix-Zeit (Sekunden seit 1.1.1970 UTC) in TDateTime
    Result := UnixToDateTime(UnixTime);

    // Konvertierung von UTC nach lokaler Systemzeit
    Result := TTimeZone.Local.ToLocalTime(Result);
  end;

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
  xTimestamp: TlkJSONnumber;
resourcestring
  S_JSON_ENTRY_MISSING = 'JSON entry "%s" is missing!';
  S_WRONG_QUOTE_LEN = 'Length of quotes-entry is unexpected!';
  S_JSON_RATE_MISSING = 'JSON entry quotes->rate is missing!';
  S_CURRENCY_NOT_SUPPORTED = 'Currency "%s" not supported';
begin
  fromCur := Trim(UpperCase(fromCur));
  toCur := Trim(UpperCase(toCur));

  if fromCur = toCur then
  begin
    result.Value := value;
    result.Timestamp := Now;
    exit;
  end;

  sJSON := GetJsonRaw(HistoricDate);

  xRoot := TlkJSON.ParseText(sJSON) as TlkJSONobject;
  try
    xSource := xRoot.Field['source'] as TlkJSONstring;
    if not assigned(xSource) then raise EVtsCurConvException.CreateFmt(S_JSON_ENTRY_MISSING, ['source']);

    xQuotes := xRoot.Field['quotes'] as TlkJSONobject;
    if not assigned(xQuotes) then raise EVtsCurConvException.CreateFmt(S_JSON_ENTRY_MISSING, ['quotes']);

    xTimestamp := xRoot.Field['timestamp'] as TlkJSONNumber;
    if not assigned(xTimestamp) then raise EVtsCurConvException.CreateFmt(S_JSON_ENTRY_MISSING, ['timestamp']);

    rateToFound := false;
    rateFromFound := false;
    rateTo := 0.00; // to avoid that the compiler shows a warning
    rateFrom := 0.00; // to avoid that the compiler shows a warning

    for i := 0 to xQuotes.Count - 1 do
    begin
      if Length(xQuotes.NameOf[i]) <> 6 then raise EVtsCurConvException.Create(S_WRONG_QUOTE_LEN);

      xRate := xQuotes.Field[xQuotes.NameOf[i]] as TlkJSONnumber;
      if not Assigned(xRate) then raise EVtsCurConvException.Create(S_JSON_RATE_MISSING);

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

    if not rateToFound then raise EVtsCurConvException.CreateFmt(S_CURRENCY_NOT_SUPPORTED, [toCur]);
    if not rateFromFound then raise EVtsCurConvException.CreateFmt(S_CURRENCY_NOT_SUPPORTED, [fromCur]);

    result.Value := value * rateTo / rateFrom;
    result.Timestamp := UnixToDateTimeWithSystemTime(xTimeStamp.Value);
  finally
    xRoot.Free;
  end;
end;

procedure TVtsCurConv.QueryAPIKey(msg: string='');
var
  s: string;
resourcestring
  S_CURRENCYLAYER = 'currencylayer.com';
  S_ENTER_KEY = 'Please enter your API key:';
  S_NO_API_KEY = 'No API key provided.';
begin
  s := Trim(InputBox(S_CURRENCYLAYER, Trim(msg + ' ' + S_ENTER_KEY), ''));
  if s = '' then raise EVtsCurConvException.Create(S_NO_API_KEY);
  WriteAPIKey(s);
end;

function TVtsCurConv.GetAcceptedCurrencies(sl: TStringList=nil; HistoricDate: TDate=0): integer;
var
  i: Integer;
  sJSON: String;
  xSource: TlkJSONstring;
  xRoot: TlkJSONobject;
  xQuotes: TlkJSONobject;
resourcestring
  S_JSON_ENTRY_MISSING = 'JSON entry "%s" is missing!';
  S_WRONG_QUOTE_LEN = 'Length of quotes-entry is unexpected!';
begin
  result := 0;

  sJSON := GetJsonRaw(HistoricDate);

  xRoot := TlkJSON.ParseText(sJSON) as TlkJSONobject;
  try
    xSource := xRoot.Field['source'] as TlkJSONstring;
    if not assigned(xSource) then raise EVtsCurConvException.CreateFmt(S_JSON_ENTRY_MISSING, ['source']);

    xQuotes := xRoot.Field['quotes'] as TlkJSONobject;
    if not assigned(xQuotes) then raise EVtsCurConvException.CreateFmt(S_JSON_ENTRY_MISSING, ['quotes']);

    for i := 0 to xQuotes.Count - 1 do
    begin
      if Length(xQuotes.NameOf[i]) <> 6 then raise EVtsCurConvException.Create(S_WRONG_QUOTE_LEN);

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
  resourcestring
    S_ENTER_NEW_KEY = 'Do you want to enter a new one?';
    S_NO_CACHE_EXISTING = 'Cannot get the data online, and no cache exists. Please check your internet connection and API key.';
  begin
    if FallBackToCache then
    begin
      if not InteractiveAPIKeyInput then
      begin
        if not FileExists(cacheFileName) then
        begin
          raise Exception.Create(S_NO_CACHE_EXISTING);
        end;
        json := FileGetContents(cacheFileName);
        doRetry := false;
      end
      else
      begin
        if MessageDlg(Trim(msg + ' ' + S_ENTER_NEW_KEY), mtError, mbYesNoCancel, 0) = ID_YES then
        begin
          QueryAPIKey;
          doRetry := true;
        end
        else
        begin
          if not FileExists(cacheFileName) then
          begin
            raise Exception.Create(S_NO_CACHE_EXISTING);
          end;
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

  function protocol: string;
  begin
    if Secure then result := 'https' else result := 'http';
  end;

  function url: string;
  var
    sDate: string;
    ApiKey: string;
  begin
    if FTempApiKey <> '' then
      ApiKey := FTempApiKey
    else
      ApiKey := ReadAPIKey;
    if (CompareValue(HistoricDate,0) = 0) or
       (CompareValue(Trunc(HistoricDate),Trunc(Now)) >= 0) then
    begin
      sDate := '';
      result := protocol + '://www.apilayer.net/api/live?access_key=' + ApiKey;
    end
    else
    begin
      DateTimeToString(sDate, 'YYYY-MM-DD', HistoricDate);
      result := protocol + '://www.apilayer.net/api/historical?date=' + sDate + '&access_key=' + ApiKey;
    end;
  end;

  function cacheFileName: string;
  resourcestring
    S_CANNOT_CREATE_DIR = 'Cannot create directory %s';
  var
    sDate: string;
    cacheDirName: string;
  begin
    // cacheDirName := IncludeTrailingPathDelimiter(GetSpecialPath(CSIDL_PROGRAM_FILES_COMMON)) + 'ViaThinkSoft\CurrencyConverter\';
    cacheDirName := IncludeTrailingPathDelimiter(GetTempDir) + 'ViaThinkSoft\CurrencyConverter\';
    if not ForceDirectories(cacheDirName) then
    begin
      raise EVtsCurConvException.CreateFmt(S_CANNOT_CREATE_DIR, [cacheDirName]);
    end;

    if CompareValue(HistoricDate,0) = 0 then
    begin
      sDate := '';
      result := IncludeTrailingPathDelimiter(cacheDirName) + 'live.json';
    end
    else
    begin
      DateTimeToString(sDate, 'YYYY-MM-DD', HistoricDate);
      result := IncludeTrailingPathDelimiter(cacheDirName) + 'historical-' + sDate + '.json';
    end;
  end;

var
  sJSON, msg: string;
  xRoot: TlkJSONobject;
  xSuccess: TlkJSONboolean;
  keyInvalid, doRetry: boolean;
  needDownload: boolean;
  mTime: TDateTime;
resourcestring
  S_INVALID_MAXAGE = 'Invalid maxage';
  S_NO_API_KEY_PROVIDED = 'No API key provided.';
  S_DOWNLOAD_QUERY = 'Download %s to %s ?';
  S_JSON_FILE_INVALID = 'JSON file invalid';
  S_UNKNOWN_SUCCESS = 'Cannot determinate status of the query.';
  S_JSON_UNKNOWN_ERROR = 'Unknown error while loading JSON.';
  S_API_KEY_INVALID = 'API key invalid.';
begin
  {$REGION 'Determinate if we need to download or not'}
  if CompareValue(HistoricDate,0) = 0 then
  begin
    needDownload := true;
    if MaxAgeSeconds < -1 then
    begin
      raise EVtsCurConvException.Create(S_INVALID_MAXAGE);
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

  if not needDownload and FileExists(cacheFileName) then
  begin
    sJSON := FileGetContents(cacheFileName);
  end
  else
  begin
    doRetry := false;

    {$REGION 'Is an API key available?'}
    if (FTempApiKey = '') and (ReadAPIKey = '') then
    begin
      _HandleKeyInvalidOrMissing(cacheFileName, S_NO_API_KEY_PROVIDED, doRetry, sJSON);
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
      if ConfirmWebAccess and (MessageDlg(Format(S_DOWNLOAD_QUERY, [url, cacheFileName]), mtConfirmation, mbYesNoCancel, 0) <> ID_YES) then
      begin
        if FallBackToCache and FileExists(cacheFileName) then
        begin
          result := FileGetContents(cacheFileName);
          Exit;
        end
        else Abort;
      end;
      {$ENDREGION}

      doRetry := false;

      sJSON := WinInet_DoGet(url);

      xRoot := TlkJSON.ParseText(sJSON) as TlkJSONobject;
      if not assigned(xRoot) then raise EVtsCurConvException.Create(S_JSON_FILE_INVALID);
      try
        xSuccess := xRoot.Field['success'] as TlkJSONboolean;
        if not assigned(xSuccess) then raise EVtsCurConvException.Create(S_UNKNOWN_SUCCESS);

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
            msg := Format('%s (%s)', [
              xRoot.Field['error'].Field['info'].Value,
              xRoot.Field['error'].Field['code'].Value(*,
              xRoot.Field['error'].Field['type'].Value*)]);
          except
            keyInvalid := false;
            msg := S_JSON_UNKNOWN_ERROR;
          end;
          {$ENDREGION}

          if keyInvalid then
          begin
            _HandleKeyInvalidOrMissing(cacheFileName, S_API_KEY_INVALID, doRetry, sJSON);
          end
          else // if not keyInvalid then
          begin
            if FallBackToCache and FileExists(cacheFileName) then
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
      finally
        FreeAndNil(xRoot);
      end;
    until not doRetry;
    {$ENDREGION}
  end;

  result := sJSON;

  // "USDUSD" missing 06 Aug 2022. A bug?? Reported https://github.com/apilayer/currencylayer-API/issues/16
  if Pos('"USDUSD"', result) = 0 then
    result := StringReplace(result, '"quotes":{', '"quotes":{"USDUSD":1,', []);
end;

end.
