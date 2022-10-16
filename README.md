# unpack
Utility to unpack call data by ABI

WARNING: no logic yet, just plumbing!!!

1) Setup environment variable:

    PG_DBNAME

2) To create test tables in Postgres and import test data:

    make install-db

3) To build go library, C shared object and link them:

    make

4) To install function unpack into Postgres:

    make install

5) To test function unpack:

    psql -d YOUR-DB-NAME -U postgres

    select unpack(address) from abi;

    (This will just output all addresses and write some debug into postgres log file, look for postgresql.log location and tail it)
