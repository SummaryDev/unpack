#include "postgres.h"
#include "fmgr.h"
#include "libunpack.h"
#include <stdio.h>

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(unpack);

Datum unpack(PG_FUNCTION_ARGS)
{
  text *string;

  // Get arguments.  If we declare our function as STRICT, then
  // this check is superfluous.
  if( PG_ARGISNULL(0) ) {
    PG_RETURN_NULL();
  }

  string = PG_GETARG_TEXT_P_COPY(0);

  int stringSize = VARSIZE_ANY_EXHDR(string);
  printf("Size is %d, string is: %s\n", stringSize, VARDATA(string));

  ProcessLog((char *)VARDATA(string));

  PG_RETURN_TEXT_P(string);
}