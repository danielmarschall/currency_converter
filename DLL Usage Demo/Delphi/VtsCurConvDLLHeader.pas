unit VtsCurConvDLLHeader;

interface

uses
  Windows, Controls;

type
  TVtsCurConvFlags = type DWORD;

const
  CONVERT_DONT_SHOW_ERRORS             {:TVtsCurConvFlags} = 1;
  CONVERT_FALLBACK_TO_CACHE            {:TVtsCurConvFlags} = 2;
  CONVERT_USE_SSL                      {:TVtsCurConvFlags} = 4 deprecated 'Since all plans now support SSL, it is enabled by default.';
  CONVERT_CONFIRM_WEB_ACCESS           {:TVtsCurConvFlags} = 8;
  CONVERT_NO_INTERACTIVE_API_KEY_INPUT {:TVtsCurConvFlags} = 16;

type
  TVtsCurConvKeyStoreMode = type DWORD;

const
  CONVERT_KEYSTORE_REGISTRY_SYSTEM     {:TVtsCurConvKeyStoreMode} = 0;
  CONVERT_KEYSTORE_REGISTRY_USER       {:TVtsCurConvKeyStoreMode} = 1;
  CONVERT_KEYSTORE_MEMORY              {:TVtsCurConvKeyStoreMode} = 2;

const
  S_VTSCONV_OK:              HRESULT = HRESULT($20000000); // Success, Customer defined, Facility 0, Code 0
  S_VTSCONV_NOTHING:         HRESULT = HRESULT($20000001); // Success, Customer defined, Facility 0, Code 1
  E_VTSCONV_GENERIC_FAILURE: HRESULT = HRESULT($A0000000); // Failure, Customer defined, Facility 0, Code 0
  E_VTSCONV_BAD_ARGS:        HRESULT = HRESULT($A0000001); // Failure, Customer defined, Facility 0, Code 1

// Mode 0 = Write in Registry System Wide
// Mode 1 = Write in Registry User Local
// Mode 2 = Keep in DLL while it is loaded
function DeleteAPIKey(Mode: TVtsCurConvKeyStoreMode; DontShowErrors: BOOL): HRESULT; stdcall;

function WriteAPIKey(key: LPCTSTR; Mode: TVtsCurConvKeyStoreMode; DontShowErrors: BOOL): HRESULT; stdcall;
function WriteAPIKeyW(key: LPCWSTR; Mode: TVtsCurConvKeyStoreMode; DontShowErrors: BOOL): HRESULT; stdcall;
function WriteAPIKeyA(key: LPCSTR; Mode: TVtsCurConvKeyStoreMode; DontShowErrors: BOOL): HRESULT; stdcall;

function ReadAPIKey(key: LPTSTR; DontShowErrors: BOOL): HRESULT; stdcall;
function ReadAPIKeyW(key: LPWSTR; DontShowErrors: BOOL): HRESULT; stdcall;
function ReadAPIKeyA(key: LPSTR; DontShowErrors: BOOL): HRESULT; stdcall;

function Convert(Value: Double; CurFrom, CurTo: LPCTSTR; MaxAge: integer;
                 Flags: TVtsCurConvFlags; HistoricDate: TDate): Double; stdcall;
                 deprecated 'use ConvertEx';
function ConvertW(Value: Double; CurFrom, CurTo: LPCWSTR; MaxAge: integer;
                  Flags: TVtsCurConvFlags; HistoricDate: TDate): Double; stdcall;
                  deprecated 'use ConvertExW';
function ConvertA(Value: Double; CurFrom, CurTo: LPCSTR; MaxAge: integer;
                  Flags: TVtsCurConvFlags; HistoricDate: TDate): Double; stdcall;
                  deprecated 'use ConvertExA';

function ConvertEx(Value: Double; CurFrom, CurTo: LPCTSTR; MaxAge: integer;
                   Flags: TVtsCurConvFlags; HistoricDate: TDate;
                   OutValue: PDouble; OutTimestamp: PDateTime): HRESULT; stdcall;
function ConvertExW(Value: Double; CurFrom, CurTo: LPCWSTR; MaxAge: integer;
                    Flags: TVtsCurConvFlags; HistoricDate: TDate;
                    OutValue: PDouble; OutTimestamp: PDateTime): HRESULT; stdcall;
function ConvertExA(Value: Double; CurFrom, CurTo: LPCSTR; MaxAge: integer;
                    Flags: TVtsCurConvFlags; HistoricDate: TDate;
                    OutValue: PDouble; OutTimestamp: PDateTime): HRESULT; stdcall;

function AcceptedCurrencies(WriteTo: LPTSTR; MaxAge: integer; Flags: TVtsCurConvFlags;
                            HistoricDate: TDate): Integer; stdcall;
                            deprecated 'use AcceptedCurrenciesEx';
function AcceptedCurrenciesW(WriteTo: LPWSTR; MaxAge: integer; Flags: TVtsCurConvFlags;
                             HistoricDate: TDate): Integer; stdcall;
                             deprecated 'use AcceptedCurrenciesExW';
function AcceptedCurrenciesA(WriteTo: LPSTR; MaxAge: integer; Flags: TVtsCurConvFlags;
                             HistoricDate: TDate): Integer; stdcall;
                             deprecated 'use AcceptedCurrenciesExA';

function AcceptedCurrenciesEx(WriteTo: LPTSTR; MaxAge: integer; Flags: TVtsCurConvFlags;
                              HistoricDate: TDate;
                              OutElements: PInteger): HRESULT; stdcall;
function AcceptedCurrenciesExW(WriteTo: LPWSTR; MaxAge: integer; Flags: TVtsCurConvFlags;
                               HistoricDate: TDate;
                               OutElements: PInteger): HRESULT; stdcall;
function AcceptedCurrenciesExA(WriteTo: LPSTR; MaxAge: integer; Flags: TVtsCurConvFlags;
                               HistoricDate: TDate;
                               OutElements: PInteger): HRESULT; stdcall;

function DownloadNow(Flags: TVtsCurConvFlags; HistoricDate: TDate): HRESULT; stdcall;
                             
implementation

const

  {$IFDEF WIN32}
  curConvDLL = 'CurConv.dll';
  {$ENDIF}

  {$IFDEF WIN64}
  curConvDLL = 'CurConv.64.dll';
  {$ENDIF}

function DeleteAPIKey; external curConvDLL name 'DeleteAPIKey';

{$IFDEF UNICODE}
function WriteAPIKey; external curConvDLL name 'WriteAPIKeyW';
{$ELSE}
function WriteAPIKey; external curConvDLL name 'WriteAPIKeyA';
{$ENDIF}
function WriteAPIKeyW; external curConvDLL name 'WriteAPIKeyW';
function WriteAPIKeyA; external curConvDLL name 'WriteAPIKeyA';

{$IFDEF UNICODE}
function ReadAPIKey; external curConvDLL name 'ReadAPIKeyW';
{$ELSE}
function ReadAPIKey; external curConvDLL name 'ReadAPIKeyA';
{$ENDIF}
function ReadAPIKeyW; external curConvDLL name 'ReadAPIKeyW';
function ReadAPIKeyA; external curConvDLL name 'ReadAPIKeyA';

{$IFDEF UNICODE}
function Convert; external curConvDLL name 'ConvertW';
{$ELSE}
function Convert; external curConvDLL name 'ConvertA';
{$ENDIF}
function ConvertW; external curConvDLL name 'ConvertW';
function ConvertA; external curConvDLL name 'ConvertA';

{$IFDEF UNICODE}
function ConvertEx; external curConvDLL name 'ConvertExW';
{$ELSE}
function ConvertEx; external curConvDLL name 'ConvertExA';
{$ENDIF}
function ConvertExW; external curConvDLL name 'ConvertExW';
function ConvertExA; external curConvDLL name 'ConvertExA';

{$IFDEF UNICODE}
function AcceptedCurrencies; external curConvDLL name 'AcceptedCurrenciesW';
{$ELSE}
function AcceptedCurrencies; external curConvDLL name 'AcceptedCurrenciesA';
{$ENDIF}
function AcceptedCurrenciesW; external curConvDLL name 'AcceptedCurrenciesW';
function AcceptedCurrenciesA; external curConvDLL name 'AcceptedCurrenciesA';

{$IFDEF UNICODE}
function AcceptedCurrenciesEx; external curConvDLL name 'AcceptedCurrenciesExW';
{$ELSE}
function AcceptedCurrenciesEx; external curConvDLL name 'AcceptedCurrenciesExA';
{$ENDIF}
function AcceptedCurrenciesExW; external curConvDLL name 'AcceptedCurrenciesExW';
function AcceptedCurrenciesExA; external curConvDLL name 'AcceptedCurrenciesExA';

function DownloadNow; external curConvDLL name 'DownloadNow';

end.
