CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE notifications (
id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
user_id    UUID         NOT NULL,
type       VARCHAR(50)  NOT NULL
    CHECK (type IN ('new_deal', 'deal_status_changed',
    'new_message', 'review_received', 'payment_status')),
title      VARCHAR(255) NOT NULL,
body       TEXT         NOT NULL,
data       JSONB,
read_at    TIMESTAMPTZ,
created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX notifications_user_id_idx
    ON notifications(user_id);

CREATE INDEX notifications_type_idx
    ON notifications(type);

CREATE INDEX notifications_created_at_idx
    ON notifications(created_at);

CREATE INDEX notifications_unread_idx
    ON notifications(user_id) WHERE
        read_at IS NULL;

CREATE INDEX notifications_read_at_idx
    ON notifications(read_at);

CREATE TABLE push_tokens (
id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
user_id     UUID          NOT NULL,
token       TEXT          NOT NULL UNIQUE,
device_id   VARCHAR(100),
device_name VARCHAR(100),
platform    VARCHAR(20)   NOT NULL
    CHECK (platform IN ('ios', 'android', 'web')),
is_active   BOOLEAN       NOT NULL DEFAULT TRUE,
created_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
updated_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX push_tokens_user_id_idx
    ON push_tokens(user_id);

CREATE INDEX push_tokens_device_id_idx
    ON push_tokens(device_id);

CREATE INDEX push_tokens_platform_idx
    ON push_tokens(platform);

CREATE TABLE notification_settings (
user_id             UUID        PRIMARY KEY,
new_deal            BOOLEAN     NOT NULL DEFAULT TRUE,
deal_status_changed BOOLEAN     NOT NULL DEFAULT TRUE,
new_message         BOOLEAN     NOT NULL DEFAULT TRUE,
review_received     BOOLEAN     NOT NULL DEFAULT TRUE,
payment_status      BOOLEAN     NOT NULL DEFAULT TRUE,
updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_push_tokens_updated_at
BEFORE UPDATE ON push_tokens
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_notification_settings_updated_at
BEFORE UPDATE ON notification_settings
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();