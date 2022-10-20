# unpack
Utility to unpack call data by ABI

WARNING: Inputs are written to log file for now. Make sure to run make install-db (fixed some .csv files)

1. Setup environment variables to connect to your Postgres db with
   `psql`:

- PGDATABASE
- PGUSER
- PGPASSWORD

2. To create test tables in Postgres and import test data:

    make install-db

3. To build go library, C shared object and link them:

    make

4. To install function unpack into Postgres:

    make install

5. To test the new function `unpack` that was built and installed:

Open the interactive shell to Postgres:

```bash
psql
```

Execute SQL:

```sql
select unpack(abi, data, topics) from abi INNER JOIN logs ON logs.address = abi.address where abi.address = '0x2b591e99afe9f32eaa6214f7b7629768c40eeb39';

select unpack(abi, data, topics) from abi INNER JOIN logs ON logs.address = abi.address where abi.address = '0xa506758544a71943b5e8728d2df8ec9e72473a9a';

select unpack(abi, data, topics) from abi INNER JOIN logs ON logs.address = abi.address where abi.address = '0x8007aa43792a392b221dc091bdb2191e5ff626d1';
```

This will just output all addresses and write some debug into postgres
log file, look for postgresql.log location and tail it:

```bash
tail -f /var/log/postgresql/postgresql-12-main.log
```

To see debug output from our function:

```
2022/10/17 17:46:20 From go function: 0x8007aa43792a392b221dc091bdb2191e5ff626d1
2022/10/17 17:46:20 From go function: 0xb1690c08e213a35ed9bab7b318de14420fb57d8c
2022/10/17 17:46:20 From go function: 0x2b591e99afe9f32eaa6214f7b7629768c40eeb39
2022/10/17 17:46:20 From go function: 0xa506758544a71943b5e8728d2df8ec9e72473a9a
```