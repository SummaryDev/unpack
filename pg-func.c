#include "postgres.h"
#include "fmgr.h"
#include "funcapi.h"
#include "utils/array.h"
#include "utils/lsyscache.h"
#include "utils/builtins.h"
#include "miscadmin.h"
#include "libunpack.h"
#include <stdio.h>

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(unpack);

Datum unpack(PG_FUNCTION_ARGS)
{
  const int MAX_TOPIC_SIZE = 66;
  const int MAX_NUM_TOPICS = 4;

  ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
  Tuplestorestate *tupstore;
  TupleDesc tupdesc;
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
  ArrayType *topics;
  Oid eltype;
  int16 elmlen;
  bool elmbyval;
  char elmalign;
  Datum *elems;
  bool *nulls;
  int nelems;

  topics = PG_GETARG_ARRAYTYPE_P(2);
  eltype = ARR_ELEMTYPE(topics);
  get_typlenbyvalalign(eltype, &elmlen, &elmbyval, &elmalign);
  deconstruct_array(topics, eltype, elmlen, elmbyval, elmalign, &elems, &nulls, &nelems);
  ereport(DEBUG1, (errmsg("Number of topics is: %d", nelems)));

  // maximum number of topics is 4, size is 66
  char topicsArg[MAX_NUM_TOPICS][MAX_TOPIC_SIZE + 1];

  // copy to array of strings to pass to go lib
  for (int i = 0; i < nelems; i++) {
    strncpy (topicsArg[i], text_to_cstring(DatumGetTextP(elems[i])), MAX_TOPIC_SIZE);
    topicsArg[i][MAX_TOPIC_SIZE] = '\0';
    ereport(DEBUG1, (errmsg("Topic[%d] is: %s, size is: %lu", i, topicsArg[i], strlen(topicsArg[i]))));
  }

  // memset the rest of the topics that are empty
  for (int i = nelems; i < MAX_NUM_TOPICS; i++) {
    memset(topicsArg[i], '\0', MAX_TOPIC_SIZE + 1);
  }

  /* check to see if caller supports us returning a tuplestore */
  if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
      ereport(ERROR,
              (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                errmsg("set-valued function called in context that cannot accept a set")));
                
  if (!(rsinfo->allowedModes & SFRM_Materialize) ||
          rsinfo->expectedDesc == NULL)
      ereport(ERROR,
              (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                errmsg("materialize mode required, but it is not allowed in this context")));

  if (get_call_result_type(fcinfo, NULL, &tupdesc) != TYPEFUNC_COMPOSITE)
        ereport(ERROR,
                (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                  errmsg("function returning record called in context "
                        "that cannot accept type record")));

  MemoryContext per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
  MemoryContext oldcontext = MemoryContextSwitchTo(per_query_ctx); 
  tupstore = tuplestore_begin_heap(false, false, work_mem);
  rsinfo->returnMode = SFRM_Materialize;
  rsinfo->setResult = tupstore;
  rsinfo->setDesc = tupdesc;
  MemoryContextSwitchTo(oldcontext);

  // for now passing all four topics separately
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

  for (int i = 0; i < numParams; i++) {
    Datum values[4];
    bool nulls[4];
    InputParam *param = *(params + i);  
       
    ereport(LOG, (errmsg("ProcessLog returned - Event: %s, Name: %s, Type: %s, Value: %s", 
                  param->Event, param->Name, param->Type, param->Value)));

    values[0] = CStringGetTextDatum(param->Event);
    values[1] = CStringGetTextDatum(param->Name);
    values[2] = CStringGetTextDatum(param->Type);
    values[3] = CStringGetTextDatum(param->Value);
    nulls[0] = false;
    nulls[1] = false;
    nulls[2] = false;
    nulls[3] = false;

    tuplestore_putvalues(tupstore, tupdesc, values, nulls);
  }

  return (Datum) 0;
}
