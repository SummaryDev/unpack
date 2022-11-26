/*
creates functions present on redshift https://docs.aws.amazon.com/redshift/latest/dg/r_STRTOL.html
but missing on the latest postgres https://www.postgresql.org/docs/current/functions-string.html
to keep functions.sql uniform across postgres and redshift
 */

create or replace function strtol (data text, bits int) returns bigint immutable
as $$
select concat('x', substr(lpad(data, 64, '0'), 49, 64))::bit(64)::bigint
$$ language sql;

-- select strtol('0000000000000000000000000000000000000000000000000000000000000020', 16);

-- select strtol('00000000000000000000000000000001', 16);

create or replace function from_hex (data text)
  returns bytea
immutable
as $$
select decode(data, 'hex')
$$ language sql;

create or replace function from_varbyte (data bytea, encoding text)
  returns text
immutable
as $$
select convert_from(data, encoding)
$$ language sql;

/*
useful for testing but not used in the library
https://stackoverflow.com/questions/33486595/postgresql-convert-hex-string-of-a-very-large-number-to-a-numeric/54130287#54130287
 */
create or replace function hex_to_numeric(str text)
returns numeric
language plpgsql immutable strict as $$
declare
    i int;
    n int = length(str)/ 8;
    res dec = 0;
    p text;
    d dec;
begin
    str := lpad($1, (n+ 1)* 8, '0');
    for i in 0..n loop
        res:= res * 4294967296; -- hex 100000000
        p:= concat('x', substr(str, i* 8+ 1, 8));
        d:= p::bit(32)::bigint::dec;
        res:= res + d;
        raise notice '% % %', p, d, res;
    end loop;
    return res;
end $$;
