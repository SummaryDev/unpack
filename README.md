# unpack

Utility to unpack call data with smart contract ABI.

1. Setup environment variables to connect to your Postgres db with
   `psql`:

- PGUSER
- PGPASSWORD
- PGDATABASE if not using the default

For example:

```bash
export PGUSER=postgres && export PGPASSWORD=postgres
```

2. To create test tables in Postgres and import test data:

    make install-db

3. To build go library, C shared object and link them:

    make

4. To install function unpack into Postgres:

    make install

5. To test Postgres function `unpack` that we just built and installed:

Start the interactive shell `psql`.

Execute SQL:

```sql

select unpack(abi, data, topic0, topic1, topic2, topic3) from abi INNER JOIN logs ON logs.address = abi.address where abi.address = '0xa506758544a71943b5e8728d2df8ec9e72473a9a';

select unpack(abi, data, topic0, topic1, topic2, topic3) from abi INNER JOIN logs ON logs.address = abi.address;

SELECT log_index, unpack(abi, data, topic0, topic1, topic2, topic3) from abi INNER JOIN logs ON logs.address = abi.address;
```

The module will log into postgres log file. Tail it to see the activity.

```bash
tail -f /var/log/postgresql/postgresql-12-main.log
```

Logging level is controlled by the following variable in postgresql.conf file:

````
log_min_messages		warning  			#is the default
````

with levels: debug5, debug4, debug3, debug2, debug1, info, notice, warning, error, log, fatal, panic

Observe log output from our function:

```
2022-10-28 15:53:54.747 AST [93085] LOG:  ProcessLog returned 2 results
2022-10-28 15:53:54.747 AST [93085] STATEMENT:  SELECT log_index, x.* FROM abi JOIN  logs on logs.address = abi.address, unpack(abi, data, topic0, topic1, topic2, topic3) x;
```

To see more verbose logging for our function set log_min_messages to debug1.