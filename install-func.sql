drop function if exists unpack;

create or replace function unpack(text, text, text, text, text, text)
    returns text
    as :MOD,'unpack'
    LANGUAGE C IMMUTABLE;