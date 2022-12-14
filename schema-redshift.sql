--DROP TABLE IF EXISTS blocks;

CREATE TABLE blocks (
  timestamp         TIMESTAMP      NOT NULL,     -- The block time
  number            BIGINT         NOT NULL,     -- The block number
  hash              VARCHAR(66) NOT NULL,     -- Hash of the block
  parent_hash       VARCHAR(66) NOT NULL,     -- Hash of the parent block
  nonce             VARCHAR(42) NOT NULL,     -- Hash of the generated proof-of-work
  sha3_uncles       VARCHAR(66) NOT NULL,     -- SHA3 of the uncles data in the block
  logs_bloom        VARCHAR(65535) NOT NULL,     -- The bloom filter for the logs of the block
  transactions_root VARCHAR(66) NOT NULL,     -- The root of the transaction trie of the block
  state_root        VARCHAR(66) NOT NULL,     -- The root of the final state trie of the block
  receipts_root     VARCHAR(66) NOT NULL,     -- The root of the receipts trie of the block
  miner             VARCHAR(42) NOT NULL,     -- The address of the beneficiary to whom the mining rewards were given
  difficulty        NUMERIC(38, 0) NOT NULL,     -- Integer of the difficulty for this block
  total_difficulty  NUMERIC(38, 0) NOT NULL,     -- Integer of the total difficulty of the chain until this block
  size              BIGINT         NOT NULL,     -- The size of this block in bytes
  extra_data        VARCHAR(65535) DEFAULT NULL, -- The extra data field of this block
  gas_limit         BIGINT         DEFAULT NULL, -- The maximum gas allowed in this block
  gas_used          BIGINT         DEFAULT NULL, -- The total used gas by all transactions in this block
  transaction_count BIGINT         NOT NULL,     -- The number of transactions in the block
  base_fee_per_gas  BIGINT,         
  PRIMARY KEY (number)
)
DISTKEY (number)
SORTKEY AUTO;

select count(*) from blocks;

--DROP TABLE IF EXISTS transactions;

CREATE TABLE transactions (
  hash              VARCHAR(66) NOT NULL,     -- Hash of the transaction
  nonce             BIGINT         NOT NULL,     -- The number of transactions made by the sender prior to this one
  transaction_index BIGINT         NOT NULL,     -- Integer of the transactions index position in the block
  from_address      VARCHAR(42) NOT NULL,     -- Address of the sender
  to_address        VARCHAR(42) DEFAULT NULL, -- Address of the receiver. null when its a contract creation transaction
  value             NUMERIC(38, 0) NOT NULL,     -- Value transferred in Wei
  gas               BIGINT         NOT NULL,
  gas_price         BIGINT         NOT NULL,
  input             VARCHAR(65535) NOT NULL,     -- The data sent along with the transaction
  receipt_cumulative_gas_used   BIGINT         NOT NULL,
  receipt_gas_used              BIGINT         NOT NULL,
  receipt_contract_address      VARCHAR(42)         NOT NULL,
  receipt_root                  VARCHAR(66)         NOT NULL,
  receipt_status                BIGINT         NOT NULL,
  block_timestamp   TIMESTAMP       NOT NULL, -- The block time
  block_number      BIGINT         NOT NULL,     -- Block number where this transaction was in
  block_hash        VARCHAR(66) NOT NULL,     -- Hash of the block where this transaction was in
  max_fee_per_gas   BIGINT         DEFAULT NULL,
  max_priority_fee_per_gas   BIGINT         DEFAULT NULL,
  transaction_type         BIGINT         DEFAULT NULL,     
  receipt_effective_gas_price         BIGINT         NOT NULL,     
  PRIMARY KEY (hash)
)
DISTKEY (block_number)
SORTKEY AUTO;

--DROP TABLE IF EXISTS traces;

CREATE TABLE traces (
  transaction_hash  VARCHAR(66) NOT NULL, -- Transaction hash where this trace was in
  transaction_index BIGINT         DEFAULT NULL, -- Integer of the transactions index position in the block
  from_address      VARCHAR(42) NOT NULL,     -- Address of the sender
  to_address        VARCHAR(42) DEFAULT NULL, -- Address of the receiver. null when its a contract creation transaction
  value             NUMERIC(38, 0) NOT NULL,     -- Value transferred in Wei
  input             VARCHAR(65535) NOT NULL,     -- The data sent along with the transactionl
  output            VARCHAR(65535) NOT NULL, -- The output of the message call, bytecode of contract when trace_type is create
  trace_type        VARCHAR(16) NOT NULL, -- One of call, create, suicide, reward, genesis, daofork
  call_type         VARCHAR(16) NOT NULL, -- One of call, callcode, delegatecall, staticcall
  reward_type       VARCHAR(16) NOT NULL, -- One of block, uncle
  gas               BIGINT         DEFAULT NULL, -- Gas provided with the message call
  gas_used          BIGINT         DEFAULT NULL, -- Gas used by the message call
  subtraces         BIGINT         NOT NULL, -- Number of subtraces
  trace_address     VARCHAR(8192) NOT NULL, -- Comma separated list of trace address in call tree
  error             VARCHAR(1024) NOT NULL,  -- Error if message call failed
  status            INT         NOT NULL,
  block_timestamp   TIMESTAMP       NOT NULL, -- The block time
  block_number      BIGINT         NOT NULL,     -- Block number where this transaction was in
  block_hash        VARCHAR(66) NOT NULL,     -- Hash of the block where this transaction was in
  trace_id          VARCHAR(128) NOT NULL,
  PRIMARY KEY (trace_id)
)
DISTKEY (block_number)
SORTKEY AUTO;

--drop table if exists logs;

CREATE TABLE logs (
  log_index         BIGINT          NOT NULL, -- Integer of the log index position in the block
  transaction_hash  VARCHAR(66)     NOT NULL, -- Hash of the transactions this log was created from 
  transaction_index BIGINT          NOT NULL, -- Integer of the transactions index position log was created from
  address           VARCHAR(42)     NOT NULL, -- Address from which this log originated
  data              VARCHAR(65535)  NOT NULL, -- Contains one or more 32 Bytes non-indexed arguments of the log
  topic0            VARCHAR(66)     NOT NULL, -- Indexed log arguments (0 to 4 32-byte hex strings). (In solidity: The first topic is the hash of the 
  topic1            VARCHAR(66)     NOT NULL, -- Indexed log arguments (0 to 4 32-byte hex strings). (In solidity: The first topic is the hash of the 
  topic2            VARCHAR(66)     NOT NULL, -- Indexed log arguments (0 to 4 32-byte hex strings). (In solidity: The first topic is the hash of the 
  topic3            VARCHAR(66)     NOT NULL, -- Indexed log arguments (0 to 4 32-byte hex strings). (In solidity: The first topic is the hash of the
  block_timestamp   TIMESTAMP       NOT NULL, -- The block time
  block_number      BIGINT          NOT NULL, -- The block number where this log was insignature of the event (e.g. Deposit(address,bytes32,uint256)),
  block_hash        VARCHAR(66)     NOT NULL, -- Hash of the block where this log was in except you declared the event with the anonymous specifier
  PRIMARY KEY (transaction_hash, log_index)
)
DISTKEY (block_number)
SORTKEY AUTO;

--DROP TABLE IF EXISTS token_transfers;

CREATE TABLE token_transfers (
  token_address    VARCHAR(42) NOT NULL, -- ERC20 token address
  from_address     VARCHAR(42) NOT NULL, -- Address of the sender
  to_address       VARCHAR(42) NOT NULL, -- Address of the receiver
  --value            NUMERIC(38, 0) NOT NULL, -- Amount of tokens transferred
  value            VARCHAR(256) NOT NULL, -- Amount of tokens transferred
  transaction_hash VARCHAR(66) NOT NULL, -- Transaction hash
  log_index        BIGINT         NOT NULL, -- Log index in the transaction receipt
  block_timestamp   TIMESTAMP       NOT NULL, -- The block time
  block_number      BIGINT          NOT NULL, -- The block number where this log was insignature of the event (e.g. Deposit(address,bytes32,uint256)),
  block_hash        VARCHAR(66)     NOT NULL, -- Hash of the block where this log was in except you declared the event with the anonymous specifier
  PRIMARY KEY (transaction_hash, log_index)
)
DISTKEY (block_number)
SORTKEY AUTO;

--DROP TABLE IF EXISTS tokens;

CREATE TABLE tokens (
  address      VARCHAR(42) NOT NULL,     -- The address of the ERC20 token
  symbol       VARCHAR(32) DEFAULT NULL, -- The symbol of the ERC20 token
  name         VARCHAR(128) DEFAULT NULL, -- The name of the ERC20 token
  decimals     INT DEFAULT NULL, -- The number of decimals the token uses.  Cast to NUMERIC or FLOAT8
  total_supply VARCHAR(256) NOT NULL,     -- The total token supply. Cast to NUMERIC or FLOAT8
  block_timestamp   TIMESTAMP       NOT NULL, -- The block time
  block_number      BIGINT          NOT NULL, -- The block number where this log was insignature of the event (e.g. Deposit(address,bytes32,uint256)),
  block_hash        VARCHAR(66)     NOT NULL, -- Hash of the block where this log was in except you declared the event with the anonymous specifier
  PRIMARY KEY (address)
)
DISTSTYLE ALL
SORTKEY AUTO;

DROP TABLE IF EXISTS contracts;

CREATE TABLE contracts (
  address            VARCHAR(42) NOT NULL, -- Address of the contract
  bytecode           VARCHAR(65535) NOT NULL, -- Bytecode of the contract
  function_sighashes VARCHAR(1024) NOT NULL, -- 4-byte function signature hashes
  is_erc20           BOOLEAN        NOT NULL, -- Whether this contract is an ERC20 contract
  is_erc721          BOOLEAN        NOT NULL, -- Whether this contract is an ERC721 contract
  block_number      BIGINT          NOT NULL, -- The block number where this log was insignature of the event (e.g. Deposit(address,bytes32,uint256)),
  block_timestamp   TIMESTAMP       NOT NULL -- The block time
)
DISTSTYLE ALL
SORTKEY AUTO;


-- select data from logs
--   inner join abi on abi.address = logs.address
-- where logs.address = '0xc12d1c73ee7dc3615ba4e37e4abfdbddfa38907e'
--       and topic0 = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'
--       and block_timestamp < '2020-01-01 12:00:00';
--
-- select topic0, data from logs where logs.address = '0xc12d1c73ee7dc3615ba4e37e4abfdbddfa38907e' and block_timestamp < '2020-12-01 01:00:00' limit 100;

create schema eth;

set search_path to eth;

drop table if exists logs;

CREATE TABLE logs (
  address           VARCHAR(42)     NOT NULL, -- Address from which this log originated
  topics            super, -- Indexed log arguments (0 to 4 32-byte hex strings). (In solidity: The first topic is the hash of the
  data              varbinary(512000)  NOT NULL, -- Contains one or more 32 Bytes non-indexed arguments of the log
  transaction_index BIGINT          NOT NULL, -- Integer of the transactions index position log was created from
  log_index         BIGINT          NOT NULL, -- Integer of the log index position in the block
  transaction_hash  VARCHAR(66)     NOT NULL, -- Hash of the transactions this log was created from
  block_number      BIGINT          NOT NULL, -- The block number where this log was insignature of the event (e.g. Deposit(address,bytes32,uint256)),
  block_hash        VARCHAR(66)     NOT NULL, -- Hash of the block where this log was in except you declared the event with the anonymous specifier,
  block_timestamp   timestamp          NOT NULL,
  date              varchar(10)     NOT NULL,
  last_modified     timestamp          NOT NULL,
  PRIMARY KEY (transaction_hash, log_index)
)
  DISTKEY (block_number)
  SORTKEY AUTO;

COPY dev.public.logs_a FROM 's3://aws-public-blockchain-copy' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;

COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-01/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-02/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-03/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;

COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-04/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-05/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-06/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-07/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-08/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-09/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-10/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-11/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-12/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-13/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-14/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-15/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-16/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-17/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-18/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-19/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-20/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-21/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-22/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-23/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-24/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-25/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-26/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-27/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-28/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-29/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-30/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;
COPY dev.public.logs FROM 's3://aws-public-blockchain-copy/logs/date=2020-01-31/' IAM_ROLE 'arn:aws:iam::729713441316:role/service-role/AmazonRedshift-CommandsAccessRole-20221031T131305' FORMAT AS PARQUET SERIALIZETOJSON;

select topics[1]::text from logs_a where address = '0xdac17f958d2ee523a2206206994597c13d831ec7' limit 1;

select topics[1]::text from logs where address = '0xdac17f958d2ee523a2206206994597c13d831ec7' limit 1;

select * from logs_a where address = '0xdac17f958d2ee523a2206206994597c13d831ec7' limit 1;

select to_address(topics[1]::text) from logs where address = '0xdac17f958d2ee523a2206206994597c13d831ec7' limit 1;