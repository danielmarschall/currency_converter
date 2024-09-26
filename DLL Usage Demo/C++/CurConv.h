#ifndef _CURCONV_API_H_
#define _CURCONV_API_H_

#include <windows.h>

typedef DWORD CURCONV_FLAGS;
const CURCONV_FLAGS CONVERT_DONT_SHOW_ERRORS             = (CURCONV_FLAGS)1;
const CURCONV_FLAGS CONVERT_FALLBACK_TO_CACHE            = (CURCONV_FLAGS)2;
const CURCONV_FLAGS CONVERT_USE_SSL                      = (CURCONV_FLAGS)4; // Depreacted. Since all plans now support SSL, it is enabled by default.
const CURCONV_FLAGS CONVERT_CONFIRM_WEB_ACCESS           = (CURCONV_FLAGS)8;
const CURCONV_FLAGS CONVERT_NO_INTERACTIVE_API_KEY_INPUT = (CURCONV_FLAGS)16;

typedef DWORD CURCONV_STORE_MODE;
const CONVERT_KEYSTORE_REGISTRY_SYSTEM  = (CURCONV_STORE_MODE)0;
const CONVERT_KEYSTORE_REGISTRY_USER    = (CURCONV_STORE_MODE)1;
const CONVERT_KEYSTORE_MEMORY           = (CURCONV_STORE_MODE)2;

const HRESULT S_VTSCONV_OK              = (HRESULT)0x20000000; // Success, Customer defined, Facility 0, Code 0
const HRESULT S_VTSCONV_NOTHING         = (HRESULT)0x20000001; // Success, Customer defined, Facility 0, Code 1
const HRESULT E_VTSCONV_GENERIC_FAILURE = (HRESULT)0xA0000000; // Failure, Customer defined, Facility 0, Code 0
const HRESULT E_VTSCONV_BAD_ARGS        = (HRESULT)0xA0000001; // Failure, Customer defined, Facility 0, Code 1

//#define CURCONV_API extern "C" __declspec(dllimport)
#define CURCONV_API extern "C" __stdcall

CURCONV_API HRESULT DeleteAPIKey(CURCONV_STORE_MODE Mode, BOOL DontShowErrors);

CURCONV_API HRESULT WriteAPIKeyW(LPCWSTR key, CURCONV_STORE_MODE Mode, BOOL DontShowErrors);
CURCONV_API HRESULT WriteAPIKeyA(LPCSTR key, CURCONV_STORE_MODE Mode, BOOL DontShowErrors);

CURCONV_API HRESULT ReadAPIKeyW(LPWSTR key, BOOL DontShowErrors);
CURCONV_API HRESULT ReadAPIKeyA(LPSTR key, BOOL DontShowErrors);

CURCONV_API double ConvertW(double Value, LPCWSTR CurFrom, LPCWSTR CurTo, int MaxAge, CURCONV_FLAGS Flags, DATE HistoricDate); // deprecated
CURCONV_API double ConvertA(double Value, LPCSTR CurFrom, LPCSTR CurTo, int MaxAge, CURCONV_FLAGS Flags, DATE HistoricDate); // deprecated
CURCONV_API HRESULT ConvertExW(double Value, LPCWSTR CurFrom, LPCWSTR CurTo, int MaxAge, CURCONV_FLAGS Flags, DATE HistoricDate, double* OutValue, DATE* OutTimestamp);
CURCONV_API HRESULT ConvertExA(double Value, LPCSTR CurFrom, LPCSTR CurTo, int MaxAge, CURCONV_FLAGS Flags, DATE HistoricDate, double* OutValue, DATE* OutTimestamp);

CURCONV_API int AcceptedCurrenciesW(LPWSTR WriteTo, int MaxAge, CURCONV_FLAGS Flags, DATE HistoricDate); // deprecated
CURCONV_API int AcceptedCurrenciesA(LPSTR WriteTo, int MaxAge, CURCONV_FLAGS Flags, DATE HistoricDate); // deprecated
CURCONV_API HRESULT AcceptedCurrenciesExW(LPWSTR WriteTo, int MaxAge, CURCONV_FLAGS Flags, DATE HistoricDate, int* OutElements);
CURCONV_API HRESULT AcceptedCurrenciesExA(LPSTR WriteTo, int MaxAge, CURCONV_FLAGS Flags, DATE HistoricDate, int* OutElements);

CURCONV_API HRESULT DownloadNow(CURCONV_FLAGS Flags, DATE HistoricDate);

#endif
