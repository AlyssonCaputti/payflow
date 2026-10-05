

CREATE TABLE accounts(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    owner TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN('ACTIVE', 'BLOCKED')),
    balance_cents BIGINT NOT NULL DEFAULT 0 
    CHECK(balance_cents >= 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);


CREATE TABLE transfers(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    idempotency_key TEXT UNIQUE NOT NULL,
    from_acc BIGINT NOT NULL REFERENCES accounts(id),
    to_acc BIGINT NOT NULL REFERENCES accounts(id),
    amount_cents BIGINT NOT NULL
    CHECK(amount_cents > 0),
    status TEXT NOT NULL DEFAULT 'PENDING' 
    CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (from_acc <> to_acc)
);

CREATE TABLE ledger_entries(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transfer_id BIGINT NOT NULL REFERENCES transfers(id),
    account_id BIGINT NOT NULL REFERENCES accounts(id),
    amount_cents BIGINT NOT NULL
);

CREATE TABLE outbox(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id UUID NOT NULL UNIQUE,
    aggregate_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    payload  JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    published_at TIMESTAMPTZ
);