#include "postgres.h"
#include "fmgr.h"
#include "libunpack.h"
#include <stdio.h>

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(unpack);

Datum unpack(PG_FUNCTION_ARGS)
{
  text *abi;

  // Get arguments.  If we declare our function as STRICT, then
  // this check is superfluous.
  if( PG_ARGISNULL(0) ) {
    PG_RETURN_NULL();
  }

  // must have all three arguments

  // abi
  abi = PG_GETARG_TEXT_P_COPY(0);
  int abiSize = VARSIZE_ANY_EXHDR(abi);
  printf("Size is %d, string is: %s\n", abiSize, VARDATA(abi));

  ProcessLog((char *)VARDATA(abi));

  PG_RETURN_TEXT_P(abi);
}