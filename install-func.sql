create or replace function unpack(text, text, text)
    returns text as :MOD,'unpack'
    LANGUAGE C IMMUTABLE;