# unpack

Utility to unpack call data with smart contract ABI.

WARNING: Inputs are written to log file for now. Make sure to run make install-db (fixed some .csv files)

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
select (x).* 
from (
select unpack(abi, data, topics) as x
	from abi INNER JOIN logs ON logs.address = abi.address 
	where abi.address = '0xa506758544a71943b5e8728d2df8ec9e72473a9a') sub;

select (x).* 
from (
select unpack(abi, data, topics) as x
	from abi INNER JOIN logs ON logs.address = abi.address 
	where abi.address = '0x2b591e99afe9f32eaa6214f7b7629768c40eeb39') sub;

select (x).* 
from (
select unpack(abi, data, topics) as x
	from abi INNER JOIN logs ON logs.address = abi.address 
	where abi.address = '0x8007aa43792a392b221dc091bdb2191e5ff626d1') sub;

select (x).* 
from (
select unpack(abi, data, topics) as x
	from abi INNER JOIN logs ON logs.address = abi.address) sub;

select log_index, (x).* 
from (
select *, unpack(abi, data, topics) as x
	from abi INNER JOIN logs ON logs.address = abi.address) sub;

select log_index, transaction_hash, (x).* 
from (
select *, unpack(abi, data, topics) as x
	from abi INNER JOIN logs ON logs.address = abi.address) sub;

SELECT x.* FROM abi JOIN  logs on logs.address = abi.address, unpack(abi, data, topics) x;

SELECT log_index, x.* FROM abi JOIN  logs on logs.address = abi.address, unpack(abi, data, topics) x;
```

This will just output all addresses and write some debug into postgres
log file, look for postgresql.log location and tail it:

For example:

```bash
tail -f /var/log/postgresql/postgresql-12-main.log
```

Observe debug output from our function:

```
2022/10/17 17:46:20 From go function: 0x8007aa43792a392b221dc091bdb2191e5ff626d1
2022/10/17 17:46:20 From go function: 0xb1690c08e213a35ed9bab7b318de14420fb57d8c
2022/10/17 17:46:20 From go function: 0x2b591e99afe9f32eaa6214f7b7629768c40eeb39
2022/10/17 17:46:20 From go function: 0xa506758544a71943b5e8728d2df8ec9e72473a9a
```