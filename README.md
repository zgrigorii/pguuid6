## PgUUID6

This is one of the postgresql  implementations of [uuid version 6](https://datatracker.ietf.org/doc/html/rfc4122) with functions to successfully use partitions by range.

### Functions

| structure                                     | description                                                         |
|-----------------------------------------------|---------------------------------------------------------------------|
| `uuid6_epoch(timestamp with time zone):text`  | generates timestamp with uuid version 6                             |
| `uuid6_concat(epoch text, variant text):uuid` | concatenates the left (epoch) and right (variant) parts into a uuid |
| `uuid6(timestamp with time zone):uuid`        | generates a new version 6 uuid                                      |
| `uuid6_vmin(timestamp with time zone):uuid`   | generates uuid with minimum variant                                 |
| `uuid6_vmax(timestamp with time zone):uuid`   | generates uuid with maximum variant                                 |

- #### uuid6_epoch
```postgresql
 select uuid6_epoch();
-- or
 select uuid6_epoch(clock_timestamp());
```

```
1ee3f77210d764e0
```

- #### uuid6_concat
```postgresql
select uuid6_concat('1ee3f7873e596ef0', 'b2c7f530d9f97777');
```
```
1ee3f787-3e59-6ef0-b2c7-f530d9f97777
```

- #### uuid6
```postgresql
select uuid6();
-- or
select uuid6(clock_timestamp());
```

```
1ee3f798-95a0-6950-8366-ba9f743d2bfd
```

- #### uuid6_vmin
```postgresql
select uuid6_vmin();
-- or
select uuid6_vmin(clock_timestamp());
```
```
1ee43f71-562c-6420-0000-000000000000
```
- #### uuid6_vmax
```postgresql
select uuid6_vmax();
-- or
select uuid6_vmax(clock_timestamp());
```
```
1ee43f7b-0787-68a0-ffff-ffffffffffff
```

### Examples

#### Partitions by range
Create a simple table:
```postgresql
create table task (
    id uuid primary key default uuid6(),
    name text not null
) partition by range(id);
```
Let's create a couple of partitions:
```postgresql
create table task_20230820 partition of task
for values
from (uuid6_vmin('2023-08-20'::timestamptz))
to (uuid6_vmin('2023-08-21'::timestamptz));

create table task_20230821 partition of task
for values
from (uuid6_vmin('2023-08-21'::timestamptz))
to (uuid6_vmin('2023-08-22'::timestamptz));
```
and add a couple of records:
```postgresql
insert into task(id, name) values(uuid6('2023-08-20 08:36:11'::timestamptz), 'task1');
insert into task(id, name) values(uuid6('2023-08-21 08:36:11'::timestamptz), 'task2');
```
So, check our partitions:
```postgresql
select tableoid::regclass as partition, t.*
from task as t;
```
```
+-------------+------------------------------------+-----+
|partition    |id                                  |name |
+-------------+------------------------------------+-----+
|task_20230820|1ee3f349-d998-6f80-8b3a-756f048f4ce0|task1|
|task_20230821|1ee3ffdc-8034-6f80-9a3b-22c3c7257c87|task2|
+-------------+------------------------------------+-----+
```