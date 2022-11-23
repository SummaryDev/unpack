#include "postgres.h"
#include "fmgr.h"
#include "funcapi.h"
#include "utils/array.h"
#include "utils/lsyscache.h"
#include "utils/builtins.h"
#include "miscadmin.h"
#include "libunpack.h"
#include <stdio.h>
#include "utils/jsonb.h"

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(unpack);

Datum unpack(PG_FUNCTION_ARGS)
{
  const int MAX_TOPIC_SIZE = 66;
  const int MAX_NUM_TOPICS = 4;
  const int MAX_RESULT_SIZE = 65535;

  InputParam **params;

  // get the args
  // abi
  char *abiArg;
  if (!PG_ARGISNULL(0)) {
    abiArg = text_to_cstring(PG_GETARG_TEXT_PP(0));
    ereport(DEBUG1, (errmsg("Abi is: %s, size is: %lu", abiArg, strlen(abiArg))));
  }
  else {
    abiArg = "";
    ereport(LOG, (errmsg("Error: abi is null")));
  }

  // data
  char *dataArg;
  if (!PG_ARGISNULL(1)) {
    dataArg = text_to_cstring(PG_GETARG_TEXT_PP(1));
    ereport(DEBUG1, (errmsg("Data is: %s, size is: %lu", dataArg, strlen(dataArg))));
  }
  else {
    dataArg = "";
    ereport(LOG, (errmsg("Error: data is null")));
  }

  // topics
  // maximum number of topics is 4, size is 66
  char topicsArg[MAX_NUM_TOPICS][MAX_TOPIC_SIZE + 1];

  for (int i = 0; i < MAX_NUM_TOPICS; i++) {
    // memset the the topics to 0
    memset(topicsArg[i], '\0', MAX_TOPIC_SIZE + 1);

    // get each topic argument: 2, 3, 4, and 5, loop index+2
    if (!PG_ARGISNULL(i+2)) {
      strcpy (topicsArg[i], text_to_cstring(PG_GETARG_TEXT_PP(i+2)));
      ereport(DEBUG1, (errmsg("Topic[%d] is: %s, size is: %lu", i, topicsArg[i], strlen(topicsArg[i]))));
    }
  } 

  // call the go processing function
  int numParams;
  char *errMsg = "";
  params = ProcessLog(abiArg, dataArg, topicsArg[0], topicsArg[1], topicsArg[2], topicsArg[3], &numParams, &errMsg);

  // no result returned from ProcessLog - report it and continue
  if ((numParams == 0) || (!params)) {
    ereport(LOG, (errmsg("ProcessLog returned NO results, %s", errMsg)));
  }
  else {
    ereport(LOG, (errmsg("ProcessLog returned %d results", numParams))); 
  }

  char result[MAX_RESULT_SIZE] = "\0";

  for (int i = 0; i < numParams; i++) {

    InputParam *param = *(params + i);  

    if (i == 0) {
      strcat(result, "[");
    }

    ereport(LOG, (errmsg("ProcessLog returned - Event: %s, Name: %s, Type: %s, Value: %s", 
                  param->Event, param->Name, param->Type, param->Value)));

    sprintf(result, "%s{\"name\": \"%s\", \"type\": \"%s\", \"value\": \"%s\"}, ", result, param->Name, param->Type, param->Value);

    if (i == numParams-1) {
      result[strlen(result)-2] = ']';
      result[strlen(result)-1] = '\0';
    }
  }

  PG_RETURN_TEXT_P(cstring_to_text(result));
}
