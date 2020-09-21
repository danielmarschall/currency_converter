unit VtsCurConvDLLHeader;

interface

uses
  Windows, Controls;

type
  TVtsCurConvFlags = type DWORD;

const
  CONVERT_DONT_SHOW_ERRORS             {:TVtsCurConvFlags} = 1;
  CONVERT_FALLBACK_TO_CACHE            {:TVtsCurConvFlags} = 2;
  CONVERT_USE_SSL                      {:TVtsCurConvFlags} = 4;
  CONVERT_CONFIRM_WEB_ACCESS           {:TVtsCurConvFlags} = 8;
  CONVERT_NO_INTERACTIVE_API_KEY_INPUT {:TVtsCurConvFlags} = 16;

const
  S_VTSCONV_OK:              HRESULT = $20000000; // Success, Customer defined, Facility 0, Code 0
  S_VTSCONV_NOTHING:         HRESULT = $20000001; // Success, Customer defined, Facility 0, Code 1
  E_VTSCONV_GENERIC_FAILURE: HRESULT = $A0000000; // Failure, Customer defined, Facility 0, Code 0
  E_VTSCONV_BAD_ARGS:        HRESULT = $A0000001; // Failure, Customer defined, Facility 0, Code 1

function DeleteAPIKey(UserMode: BOOL; DontShowErrors: BOOL): HRESULT; stdcall;

function WriteAPIKey(key: LPCTSTR; UserMode: BOOL; DontShowErrors: BOOL): HRESULT; stdcall;
function WriteAPIKeyW(key: LPCWSTR; UserMode: BOOL; DontShowErrors: BOOL): HRESULT; stdcall;
function WriteAPIKeyA(key: LPCSTR; UserMode: BOOL; DontShowErrors: BOOL): HRESULT; stdcall;

function ReadAPIKey(key: LPTSTR; DontShowErrors: BOOL): HRESULT; stdcall;
function ReadAPIKeyW(key: LPWSTR; DontShowErrors: BOOL): HRESULT; stdcall;
function ReadAPIKeyA(key: LPSTR; DontShowErrors: BOOL): HRESULT; stdcall;

function Convert(Value: Double; CurFrom, CurTo: LPCTSTR; MaxAge: integer;
                 Flags: TVtsCurConvFlags; HistoricDate: TDate): Double; stdcall;
function ConvertW(Value: Double; CurFrom, CurTo: LPCWSTR; MaxAge: integer;
                  Flags: TVtsCurConvFlags; HistoricDate: TDate): Double; stdcall;
function ConvertA(Value: Double; CurFrom, CurTo: LPCSTR; MaxAge: integer;
                  Flags: TVtsCurConvFlags; HistoricDate: TDate): Double; stdcall;

function AcceptedCurrencies(WriteTo: LPTSTR; MaxAge: integer; Flags: TVtsCurConvFlags;
                            HistoricDate: TDate): Integer; stdcall;
function AcceptedCurrenciesW(WriteTo: LPWSTR; MaxAge: integer; Flags: TVtsCurConvFlags;
                             HistoricDate: TDate): Integer; stdcall;
function AcceptedCurrenciesA(WriteTo: LPSTR; MaxAge: integer; Flags: TVtsCurConvFlags;
                             HistoricDate: TDate): Integer; stdcall;

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
function AcceptedCurrencies; external curConvDLL name 'AcceptedCurrenciesW';
{$ELSE}
function AcceptedCurrencies; external curConvDLL name 'AcceptedCurrenciesA';
{$ENDIF}
function AcceptedCurrenciesW; external curConvDLL name 'AcceptedCurrenciesW';
function AcceptedCurrenciesA; external curConvDLL name 'AcceptedCurrenciesA';

function DownloadNow; external curConvDLL name 'DownloadNow';

end.
