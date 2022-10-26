#include "postgres.h"
#include "fmgr.h"
#include "funcapi.h"
#include "utils/array.h"
#include "utils/lsyscache.h"
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

    // TODO: check when data and topics are null and decide what to do

    // get the args
    // abi
    char *abiArg;
    if (!PG_ARGISNULL(0)) {
      text *abi = PG_GETARG_TEXT_PP(0);
      int abiSize = VARSIZE_ANY_EXHDR(abi);
      abiArg = (char*) palloc((abiSize + 1) * sizeof(char));
      strcpy (abiArg, (char *)VARDATA_ANY(abi));
      abiArg[abiSize] = '\0';
      ereport(LOG, (errmsg("Abi is: %s, size is: %d", abiArg, abiSize)));
    }
    else {
      abiArg = (char*) palloc(sizeof(char));
      abiArg[0] = '\0';
      ereport(LOG, (errmsg("Error: abi is null")));
    }

    // data
    text *data = PG_GETARG_TEXT_PP(1);
    int dataSize = VARSIZE_ANY_EXHDR(data);
    char *dataArg = (char*) palloc((dataSize + 1) * sizeof(char));
    strcpy (dataArg, (char *)VARDATA_ANY(data));
    dataArg[dataSize] = '\0';
    ereport(LOG, (errmsg("Data is: %s, size is: %d", dataArg, dataSize)));

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
    ereport(LOG, (errmsg("Number of topics is: %d", nelems)));
    
    // maximum number of topics is 4
    char *topicsArg[MAX_NUM_TOPICS];

    // copy to array of strings to pass to go lib
    for (int i = 0; i < nelems; i++) {

      char *topic = (char *)VARDATA_ANY(DatumGetTextP(elems[i]));
      //TODO: check the length of topic, decide what to do if not 66

      topicsArg[i] = (char*)palloc((MAX_TOPIC_SIZE + 1) * sizeof(char));
      strcpy(topicsArg[i], topic);
      topicsArg[i][MAX_TOPIC_SIZE] = '\0';
      ereport(LOG, (errmsg("Topic[%d] is: %s, size is: %lu", i, topicsArg[i], strlen(topicsArg[i]))));
    }

    // memset the rest of the topics that are empty
    for (int i = nelems; i < MAX_NUM_TOPICS; i++) {
      topicsArg[i] = (char*) palloc((MAX_TOPIC_SIZE + 1) * sizeof(char));
      memset(topicsArg[i], '\0', MAX_TOPIC_SIZE + 1);
    }

    // for now passing all four topics separately
    int numParams;
    InputParam **params = ProcessLog(abiArg, dataArg, topicsArg[0], topicsArg[1], topicsArg[2], topicsArg[3], &numParams);
    
    for (int i = 0; i < numParams; i++) {
      InputParam *param = *(params + i);
      
      ereport(LOG, (errmsg("ProcessLog returned - Name: %s, Type: %s, Value: %s, index: %d", param->Name, param->Type, 
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


    // clean up
    pfree(abiArg);
    pfree(dataArg);
    pfree(topicsArg[0]);
    pfree(topicsArg[1]);
    pfree(topicsArg[2]);
    pfree(topicsArg[3]);

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

    ereport(LOG, (errmsg("IN LOOP 0, call_cntr: %d, max_call: %d, param name: %s, param size: %lu",
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

    ereport(LOG, (errmsg("IN LOOP 1, call_cntr: %d, max_call: %d",call_cntr,  max_calls)));

    SRF_RETURN_NEXT(funcctx, result);
  }
  else {
    ereport(LOG, (errmsg("Calling SRF_RETURN_DONE, call_cntr: %d, max_call: %d",call_cntr,  max_calls)));
    SRF_RETURN_DONE(funcctx);
  }
}