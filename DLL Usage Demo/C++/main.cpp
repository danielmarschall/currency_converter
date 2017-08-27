#include <cstdlib>
#include <iostream>

#include "CurConv.h"

using namespace std;

int main(int argc, char *argv[])
{
    printf("10 USD = %f EUR\n", ConvertA(10, "USD", "EUR", 1*60*60, CONVERT_FALLBACK_TO_CACHE, 0));
    system("PAUSE");
    return EXIT_SUCCESS;
}
