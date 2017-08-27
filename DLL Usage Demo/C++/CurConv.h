#ifndef _CURCONV_API_H_
#define _CURCONV_API_H_

#include <windows.h>

typedef DWORD CURCONV_FLAGS;

const CURCONV_FLAGS CONVERT_DONT_SHOW_ERRORS             = 1;
const CURCONV_FLAGS CONVERT_FALLBACK_TO_CACHE            = 2;
const CURCONV_FLAGS CONVERT_USE_SSL                      = 4;
const CURCONV_FLAGS CONVERT_CONFIRM_WEB_ACCESS           = 8;
const CURCONV_FLAGS CONVERT_NO_INTERACTIVE_API_KEY_INPUT = 16;

const HRESULT S_VTSCONV_OK              = 0x20000000; // Success, Customer defined, Facility 0, Code 0
const HRESULT S_VTSCONV_NOTHING         = 0x20000001; // Success, Customer defined, Facility 0, Code 1
const HRESULT E_VTSCONV_GENERIC_FAILURE = 0xA0000000; // Failure, Customer defined, Facility 0, Code 0
const HRESULT E_VTSCONV_BAD_ARGS        = 0xA0000001; // Failure, Customer defined, Facility 0, Code 1

//#define CURCONV_API extern "C" __declspec(dllimport)
#define CURCONV_API extern "C" __stdcall

CURCONV_API HRESULT DeleteAPIKey(BOOL UserMode, BOOL DontShowErrors);

CURCONV_API HRESULT WriteAPIKeyW(LPCWSTR key, BOOL UserMode, BOOL DontShowErrors);
CURCONV_API HRESULT WriteAPIKeyA(LPCSTR key, BOOL UserMode, BOOL DontShowErrors);

CURCONV_API HRESULT ReadAPIKeyW(LPWSTR key, BOOL DontShowErrors);
CURCONV_API HRESULT ReadAPIKeyA(LPSTR key, BOOL DontShowErrors);

CURCONV_API double ConvertW(double Value, LPCWSTR CurFrom, LPCWSTR CurTo, int MaxAge, CURCONV_FLAGS Flags, DATE HistoricDate);
CURCONV_API double ConvertA(double Value, LPCSTR CurFrom, LPCSTR CurTo, int MaxAge, CURCONV_FLAGS Flags, DATE HistoricDate);

CURCONV_API int AcceptedCurrenciesW(LPWSTR WriteTo, int MaxAge, CURCONV_FLAGS Flags, DATE HistoricDate);
CURCONV_API int AcceptedCurrenciesA(LPSTR WriteTo, int MaxAge, CURCONV_FLAGS Flags, DATE HistoricDate);

CURCONV_API HRESULT DownloadNow(CURCONV_FLAGS Flags, DATE HistoricDate);

#endif
