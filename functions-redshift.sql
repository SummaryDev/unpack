/*
creates functions based on redshift built it functions (and the lack of many of them)
 */

create or replace function to_uint32 (pos int, data text) returns bigint immutable
as $$
select strtol(substring(lpad($2, 64, '0'), $1+57, 8), 16)
$$ language sql;

create or replace function to_uint64 (pos int, data text) returns bigint immutable
as $$
select strtol(substring(lpad($2, 64, '0'), $1+49, 16), 16)
$$ language sql;

create or replace function to_int32 (pos int, data text) returns bigint immutable
as $$
select case when getbit(from_hex(substring(lpad($2, 64, '0'), $1+57, 8)), 31) = 0 then strtol(substring(lpad($2, 64, '0'), $1+57, 8), 16) else ~strtol(to_hex(~from_hex(substring(lpad($2, 64, '0'), $1+57, 8))), 16) end;
$$ language sql;

create or replace function to_int64 (pos int, data text) returns bigint immutable
as $$
select case when getbit(from_hex(substring(lpad($2, 64, '0'), $1+49, 16)), 63) = 0 then strtol(substring(lpad($2, 64, '0'), $1+49, 16), 16) else ~strtol(to_hex(~from_hex(substring(lpad($2, 64, '0'), $1+49, 16))), 16) end;
$$ language sql;

create or replace function to_uint128 (pos int, data text) returns dec immutable
as $$
select strtol(substring(lpad($2, 64, '0'), $1+33, 8), 16)::dec*4294967296*4294967296*4294967296 + strtol(substring(lpad($2, 64, '0'), $1+41, 8), 16)::dec*4294967296*4294967296 + strtol(substring(lpad($2, 64, '0'), $1+49, 8), 16)::dec*4294967296 + strtol(substring(lpad($2, 64, '0'), $1+57, 8), 16)::dec
$$ language sql;

