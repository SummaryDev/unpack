drop function if exists unpack;

create or replace function unpack(IN text, IN text, IN text, IN text, IN text, IN text,
    OUT event TEXT, OUT name TEXT, OUT type TEXT, OUT value TEXT)
    returns SETOF record 
    as :MOD,'unpack'
    LANGUAGE C IMMUTABLE;