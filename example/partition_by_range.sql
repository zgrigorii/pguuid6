-- Create a simple table
create table task (
    id uuid primary key default uuid6(),
    name text not null
) partition by range(id);

-- Let's create a couple of partitions
create table task_20230820 partition of task
for values
from (uuid6_vmin('2023-08-20'::timestamptz))
to (uuid6_vmin('2023-08-21'::timestamptz));

create table task_20230821 partition of task
for values
from (uuid6_vmin('2023-08-21'::timestamptz))
to (uuid6_vmin('2023-08-22'::timestamptz));

-- and add a couple of records
insert into task(id, name) values(uuid6('2023-08-20 08:36:11'::timestamptz), 'task1');
insert into task(id, name) values(uuid6('2023-08-21 08:36:11'::timestamptz), 'task2');

-- So, check our partitions:
select tableoid::regclass as partition, t.*
from task as t;