/*
    uuid6_epoch generates timestamp with uuid version 6

    EXAMPLE:
    select uuid6_epoch();

    OUTPUT:
    +----------------+
    |uuid6_epoch     |
    +----------------+
    |1ee3f77210d764e0|
    +----------------+
*/
create or replace function uuid6_epoch(
    v_time timestamp with time zone default clock_timestamp()
) returns text as
$$
declare
    v_secs          bigint  := null;
    v_usec          bigint  := null;
    v_timestamp     bigint  := null;
    v_timestamp_hex varchar := null;
    c_epoch         bigint  := -12219292800; -- RFC-4122 epoch: '1582-10-15 00:00:00'
begin
    -- get seconds and micros
    v_secs := EXTRACT(EPOCH FROM v_time);
    v_usec := mod(EXTRACT(MICROSECONDS FROM v_time)::numeric, 10 ^ 6::numeric);

    -- generate timestamp hexadecimal (and set version 6)
    v_timestamp := (((v_secs - c_epoch) * 10 ^ 6) + v_usec) * 10;
    v_timestamp_hex := lpad(to_hex(v_timestamp), 16, '0');
    v_timestamp_hex := substr(v_timestamp_hex, 2, 12) || '6' || substr(v_timestamp_hex, 14, 3);

    return v_timestamp_hex;

end
$$ language plpgsql;

/*
    uuid6_concat concatenates the left (epoch) and right (variant) parts into a uuid

    EXAMPLE:
    select uuid6_concat('1ee3f7873e596ef0', 'b2c7f530d9f97777');

    OUTPUT:
    +------------------------------------+
    |uuid6_concat                        |
    +------------------------------------+
    |1ee3f787-3e59-6ef0-b2c7-f530d9f97777|
    +------------------------------------+
*/
create or replace function uuid6_concat(epoch text, variant text) returns uuid as
$$
declare
    v_bytes bytea;
begin
    v_bytes := decode(epoch || variant, 'hex');

    return encode(v_bytes, 'hex')::uuid;

end
$$ language plpgsql;

/*
    uuid6 generates a new version 6 uuid

    EXAMPLE:
    select uuid6();

    OUTPUT:
    +------------------------------------+
    |uuid6                               |
    +------------------------------------+
    |1ee3f798-95a0-6950-8366-ba9f743d2bfd|
    +------------------------------------+
*/
create or replace function uuid6(
    v_timestamp timestamp with time zone default clock_timestamp()
) returns uuid as
$$
declare
    v_timestamp_hex         varchar := null;
    v_clkseq_and_nodeid     bigint  := null;
    v_clkseq_and_nodeid_hex varchar := null;
    c_variant               bit(64) := x'8000000000000000'; -- RFC-4122 variant: b'10xx...'
begin

    -- Generate timestamp hexadecimal (and set version 6)
    v_timestamp_hex := uuid6_epoch(v_timestamp);

    -- Generate clock sequence and node identifier hexadecimal (and set variant b'10xx')
    v_clkseq_and_nodeid := ((random()::numeric * 2 ^ 62::numeric)::bigint::bit(64) | c_variant)::bigint;
    v_clkseq_and_nodeid_hex := lpad(to_hex(v_clkseq_and_nodeid), 16, '0');

    return uuid6_concat(v_timestamp_hex, v_clkseq_and_nodeid_hex);

end
$$ language plpgsql;

/*
    uuid6_vmin generates uuid with minimum variant

    EXAMPLE:
    select uuid6_vmin();

    OUTPUT:
    +------------------------------------+
    |uuid6_vmin                          |
    +------------------------------------+
    |1ee43f71-562c-6420-0000-000000000000|
    +------------------------------------+
*/
create or replace function uuid6_vmin(
    v_time timestamp with time zone default clock_timestamp()
) returns uuid as
$$
declare
    v_variant varchar := '0000000000000000'; -- zero variant
    v_epoch   varchar := uuid6_epoch(v_time);
begin

    return uuid6_concat(v_epoch, v_variant);

end
$$ language plpgsql;

/*
    uuid6_vmin generates uuid with maximum variant

    EXAMPLE:
    select uuid6_vmax();

    OUTPUT:
    +------------------------------------+
    |uuid6_vmax                          |
    +------------------------------------+
    |1ee43f7b-0787-68a0-ffff-ffffffffffff|
    +------------------------------------+
*/
create or replace function uuid6_vmax(
    v_time timestamp with time zone default clock_timestamp()
) returns uuid as
$$
declare
    v_variant varchar := 'ffffffffffffffff';
    v_epoch   varchar := uuid6_epoch(v_time);
begin

    return uuid6_concat(v_epoch, v_variant);

end
$$ language plpgsql;