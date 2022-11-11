DROP TABLE logs;
DROP TABLE abi;

CREATE TABLE IF NOT EXISTS abi (
	"address" VARCHAR(42) PRIMARY KEY,
	abi TEXT
);

\COPY abi("address", abi) FROM 'abis.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE IF NOT EXISTS logs (
	log_index BIGINT,
	transaction_hash VARCHAR(66),
	transaction_index BIGINT,
	"address" VARCHAR(42),
	"data" TEXT,
	topic0 VARCHAR(66),
	topic1 VARCHAR(66),
	topic2 VARCHAR(66),
	topic3 VARCHAR(66),
	block_timestamp TIMESTAMP without time zone,
	block_number BIGINT,
	block_hash VARCHAR(66),
	PRIMARY KEY(log_index, transaction_hash),
	CONSTRAINT fk_abi
		FOREIGN KEY (address)
			REFERENCES abi(address)
);

\COPY logs(log_index, transaction_hash, transaction_index, "address", "data", topic0, topic1, topic2, topic3, block_timestamp, block_number, block_hash) FROM 'logs.csv' DELIMITER ',' CSV HEADER;
