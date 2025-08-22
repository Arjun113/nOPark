-- Table Definition ----------------------------------------------
create table rate_limits (
   ip_address   varchar(45) not null primary key,
   tokens       decimal(10,2) not null default 10.0,
   last_request timestamp with time zone default current_timestamp not null
);

create table ip_blacklist (
   ip_address varchar(45) not null primary key,
   reason     varchar(255),
   expires_at timestamp with time zone not null
);

-- Indexes -------------------------------------------------------
create index idx_ip_blacklist_expires on
   ip_blacklist (
      expires_at
   );