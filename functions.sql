-- library of functions to decode abi encoded data https://docs.soliditylang.org/en/develop/abi-spec.html

--drop function to_int64 (pos int, data text);

create or replace function to_int64 (pos int, data text) returns bigint immutable
as $$
select concat('x', substring(lpad($2, 64, '0'), $1+49, 16))::bit(64)::bigint
$$ language sql;

-- drop function to_uint64 (pos int, data text);

create or replace function to_uint64 (pos int, data text) returns dec immutable
as $$
select concat('x', substring(lpad($2, 64, '0'), $1+49, 8))::bit(32)::bigint::dec*4294967296 + concat('x', substring(lpad($2, 64, '0'), $1+57, 8))::bit(32)::bigint::dec
$$ language sql;

create or replace function to_uint32 (pos int, data text) returns bigint immutable
as $$
select concat('x', substring(lpad($2, 64, '0'), $1+57, 8))::bit(32)::bigint
$$ language sql;

--drop function to_int128 (pos int, data text)

create or replace function to_uint128 (pos int, data text) returns dec immutable
as $$
-- select strtol(substring($2, $1+33, 16), 16) * 18446744073709551616 + strtol(substring($2, $1+49, 16), 16)
-- select to_int64(0, substring($2, $1+33, 16)) * 18446744073709551616 + to_int64(0, substring($2, $1+49, 16))
-- select concat('x', lpad(substring($2, $1+33, 8), 8, '0')) --* 4294967296
--select concat('x', lpad(substring($2, $1+41, 8), 8, '0'))
--select concat('x', lpad(substring($2, $1+49, 8), 8, '0'))
-- select concat('x', lpad(substring($2, $1+57, 8), 8, '0'))::bit(32)::bigint::text
select concat('x', substring(lpad($2, 64, '0'), $1+33, 8))::bit(32)::bigint::dec*4294967296*4294967296*4294967296 + concat('x', substring(lpad($2, 64, '0'), $1+41, 8))::bit(32)::bigint::dec*4294967296*4294967296 + concat('x', substring(lpad($2, 64, '0'), $1+49, 8))::bit(32)::bigint::dec*4294967296 + concat('x', substring(lpad($2, 64, '0'), $1+57, 8))::bit(32)::bigint::dec
$$ language sql;

create or replace function can_convert_to_decimal (pos int, data text) returns bool immutable
as $$
--select to_int64(0, substring($2, $1+1, 32)) = 0
select length(ltrim(substring($2, $1+1, 32), '0')) = 0
$$ language sql;

-- create or replace function to_int256 (pos int, data text) returns decimal immutable
-- as $$
-- select strtol(substring($2, $1+1, 16), 16) * 18446744073709551616 + strtol(substring($2, $1+17, 16), 16) * 18446744073709551616 + strtol(substring($2, $1+33, 16), 16) * 18446744073709551616 + strtol(substring($2, $1+49, 16), 16)
-- $$ language sql;

create or replace function to_decimal (pos int, data text) returns decimal immutable
as $$
select case when can_convert_to_decimal($1, $2) then to_uint128($1, $2) else null end
$$ language sql;

--drop function to_int (pos int, data text)

create or replace function to_location (pos int, data text) returns int immutable
as $$
select to_uint32($1, $2)
$$ language sql;

create or replace function to_size (pos int, data text) returns int immutable
as $$
select to_uint32(to_location($1, $2)*2, $2)
$$ language sql;

create or replace function to_raw_bytes (pos int, data text)
  returns text
immutable
as $$
select substring($2, 1 + to_location($1, $2)*2 + 64, to_size($1, $2)*2)
$$ language sql;

create or replace function to_bytes (pos int, data text)
  returns text
immutable
as $$
select '0x' || to_raw_bytes($1, $2)
$$ language sql;

create or replace function to_fixed_bytes (pos int, data text, size int)
  returns text
immutable
as $$
select '0x' || rtrim(substring($2, $1+1, $3*2), '0')
$$ language sql;

create or replace function to_string (pos int, data text)
  returns text
immutable
as $$
select from_varbyte(from_hex(to_raw_bytes($1, $2)), 'utf8')
-- select convert_from(decode(to_raw_bytes($1, $2), 'hex'), 'utf8')
$$ language sql;

create or replace function to_address (pos int, data text)
  returns text
immutable
as $$
select '0x' || substring($2, $1+25, 40)
$$ language sql;

create or replace function to_bool (pos int, data text)
  returns bool
immutable
as $$
select to_uint32($1, $2)::int::bool
$$ language sql;

create or replace function to_element (pos int, data text, type text)
  returns text
immutable
as $$
select case
       when $3 = 'string' then quote_ident(to_string($1, $2))
       when $3 = 'bytes' then quote_ident(to_bytes($1, $2))
       when $3 = 'address' then quote_ident(to_address($1, $2))
       when $3 = 'int' then to_int64($1, $2)::text
       when $3 = 'bool' then case when to_bool($1, $2) then 'true' else 'false' end
       else substring($2, $1+1, 64)
       end
$$ language sql;

create or replace function to_array (pos int, data text, type text)
  returns text
immutable
as $$
select case
       when to_size($1, $2) = 0 then '[]'
       when to_size($1, $2) = 1 then '[' || to_element($1+128, $2, $3) || ']'
       when to_size($1, $2) = 2 then '[' || to_element($1+128, $2, $3) || ',' || to_element($1+192, $2, $3) || ']'
       else '[' || to_element($1+128, $2, $3) || ',' || to_element($1+192, $2, $3) || ',' || to_element($1+256, $2, $3) || ']'
       end
$$ language sql;

create or replace function to_fixed_array (pos int, data text, type text, size int)
  returns text
immutable
as $$
select case
       when $4 = 0 then '[]'
       when $4 = 1 then '[' || to_element($1, $2, $3) || ']'
       when $4 = 2 then '[' || to_element($1, $2, $3) || ',' || to_element($1+64, $2, $3) || ']'
       else '[' || to_element($1, $2, $3) || ',' || to_element($1+64, $2, $3) || ',' || to_element($1+128, $2, $3) || ']'
       end
$$ language sql;