#include "postgres.h"
#include "fmgr.h"
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
  
  // check if we have abi
  if( PG_ARGISNULL(0) ) {
    ereport(ERROR, (errmsg("Error: abi is null, exiting")));
    PG_RETURN_NULL();
  }

  // TODO: check when data and topics are null and decide what to do

  // abi
  text *abi = PG_GETARG_TEXT_P_COPY(0);
  int abiSize = VARSIZE_ANY_EXHDR(abi);
  char *abiArg = (char*) palloc((abiSize + 1) * sizeof(char));
  strcpy (abiArg, (char *)VARDATA_ANY(abi));
  abiArg[abiSize] = '\0';
  ereport(LOG, (errmsg("Abi is: %s, size is: %d", abiArg, abiSize)));

  // data
  text *data = PG_GETARG_TEXT_P_COPY(1);
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

  topics = PG_GETARG_ARRAYTYPE_P_COPY(2);
  eltype = ARR_ELEMTYPE(topics);
  get_typlenbyvalalign(eltype, &elmlen, &elmbyval, &elmalign);
  deconstruct_array(topics, eltype, elmlen, elmbyval, elmalign, &elems, &nulls, &nelems);
  ereport(LOG, (errmsg("Number of topics is: %d", nelems)));
  
  // maximum number of topics is 4
  char *topicsArg[MAX_NUM_TOPICS];

  // copy to array of strings to pass to go lib
  for (int i = 0; i < nelems; i++) {

    char *topic = (char *)VARDATA_ANY(DatumGetTextPCopy(elems[i]));
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

  // Go doesn't accept arrays - for now passing all four topics separately
  ProcessLog(abiArg, dataArg, topicsArg[0], topicsArg[1], topicsArg[2], topicsArg[3]);

  // temp return data
  PG_RETURN_TEXT_P(data);
}