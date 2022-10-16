create or replace function unpack(text)
    returns text as :MOD,'unpack'
    LANGUAGE C IMMUTABLE;