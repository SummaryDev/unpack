#include "postgres.h"
#include "fmgr.h"
#include "funcapi.h"
#include "utils/array.h"
#include "utils/lsyscache.h"
#include "utils/builtins.h"
#include "libunpack.h"
#include <stdio.h>

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(unpack);

Datum unpack(PG_FUNCTION_ARGS)
{
  const int MAX_TOPIC_SIZE = 66;
  const int MAX_NUM_TOPICS = 4;


  FuncCallContext *funcctx;
  TupleDesc tupdesc;
  AttInMetadata *attinmeta;
  int call_cntr;
  int max_calls;
  InputParam **params;

  // stuff done only on the first call of the function
  if (SRF_IS_FIRSTCALL()) {

    MemoryContext oldcontext;
    funcctx = SRF_FIRSTCALL_INIT();
    oldcontext = MemoryContextSwitchTo(funcctx->multi_call_memory_ctx);

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

    // for now passing all four topics separately
    int numParams;
    char *errMsg = "";
    InputParam **params = ProcessLog(abiArg, dataArg, topicsArg[0], topicsArg[1], topicsArg[2], topicsArg[3], &numParams, &errMsg);

    // no result returned from ProcessLog - report it and continue
    if ((numParams == 0) || (!params)) {
      ereport(LOG, (errmsg("ProcessLog returned NO results, %s", errMsg)));
    }
    else {
      ereport(LOG, (errmsg("ProcessLog returned %d results", numParams))); 
    }

    for (int i = 0; i < numParams; i++) {
      InputParam *param = *(params + i);
      ereport(DEBUG1, (errmsg("ProcessLog returned - Name: %s, Type: %s, Value: %s, index: %d", param->Name, param->Type, 
          param->Value, i)));
    }
  
    funcctx->max_calls = numParams;
    funcctx->user_fctx = params;

    if (get_call_result_type(fcinfo, NULL, &tupdesc) != TYPEFUNC_COMPOSITE)
          ereport(ERROR,
                  (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                    errmsg("function returning record called in context "
                          "that cannot accept type record")));

    attinmeta = TupleDescGetAttInMetadata(tupdesc);
    funcctx->attinmeta = attinmeta;
    MemoryContextSwitchTo(oldcontext);
  }
    
  funcctx = SRF_PERCALL_SETUP();
  call_cntr = funcctx->call_cntr;
  max_calls = funcctx->max_calls;
  attinmeta = funcctx->attinmeta; 
  params = funcctx->user_fctx;

  if (call_cntr < max_calls) {
    char **values;
    HeapTuple tuple;
    Datum result;
    InputParam *param = *(params + call_cntr);

    ereport(DEBUG1, (errmsg("IN LOOP, call_cntr: %d, max_call: %d, param name: %s, param size: %lu",
        call_cntr,  max_calls, param->Name, strlen(param->Name))));
  
    values = (char **) palloc(4 * sizeof(char *));
    values[0] = (char *) palloc((strlen(param->Event)+1) * sizeof(char));
    values[1] = (char *) palloc((strlen(param->Name)+1) * sizeof(char));
    values[2] = (char *) palloc((strlen(param->Type)+1) * sizeof(char));
    values[3] = (char *) palloc((strlen(param->Value)+1) * sizeof(char));

    strcpy(values[0], param->Event);
    strcpy(values[1], param->Name);
    strcpy(values[2], param->Type);
    strcpy(values[3], param->Value);
  
    tuple = BuildTupleFromCStrings(attinmeta, values);
    result = HeapTupleGetDatum(tuple);
    ereport(DEBUG1, (errmsg("IN LOOP 1 call_cntr: %d, max_call: %d",call_cntr,  max_calls)));

    SRF_RETURN_NEXT(funcctx, result);
  }
  else {
    ereport(DEBUG1, (errmsg("Calling SRF_RETURN_DONE, call_cntr: %d, max_call: %d",call_cntr,  max_calls)));
    SRF_RETURN_DONE(funcctx);
  }
}