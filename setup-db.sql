CREATE TABLE IF NOT EXISTS abi (
	"address" TEXT PRIMARY KEY,
	abi TEXT
);

\set abipath `pwd`'/abis.csv'

COPY abi("address", abi)
FROM :'abipath'
DELIMITER ','
CSV HEADER;

CREATE TABLE IF NOT EXISTS logs (
	log_index INTEGER,
	transaction_hash TEXT,
	transaction_index INTEGER,
	"address" TEXT,
	"data" TEXT,
	topics TEXT[],
	block_timestamp TIMESTAMP with time zone,
	block_number INTEGER,
	block_hash TEXT,
	PRIMARY KEY(log_index, transaction_hash),
	CONSTRAINT fk_abi
		FOREIGN KEY (address)
			REFERENCES abi(address)
);

\set logspath `pwd`'/logs.csv'

COPY logs(log_index, transaction_hash, transaction_index, "address", "data", topics, block_timestamp, block_number, block_hash)
FROM :'logspath'
DELIMITER ','
CSV HEADER;