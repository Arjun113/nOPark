-- Table Definition ----------------------------------------------
CREATE TABLE rate_limits (
    ip_address VARCHAR(45) NOT NULL PRIMARY KEY,  
    tokens DECIMAL(10, 2) NOT NULL DEFAULT 10.0,
    last_request TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE ip_blacklist (
    ip_address VARCHAR(45) NOT NULL PRIMARY KEY,  
    reason VARCHAR(255),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_ip_blacklist_expires ON ip_blacklist (expires_at);
