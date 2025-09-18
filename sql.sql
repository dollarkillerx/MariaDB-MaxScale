-- 1. 监控用户 (MaxScale-Monitor 用)
CREATE USER IF NOT EXISTS 'maxscale_mon'@'%' IDENTIFIED BY 'cH4JtWmDX7P';
GRANT REPLICA MONITOR ON *.* TO 'maxscale_mon'@'%';
GRANT READ_ONLY ADMIN ON *.* TO 'maxscale_mon'@'%';
GRANT BINLOG ADMIN ON *.* TO 'maxscale_mon'@'%';
GRANT CONNECTION ADMIN ON *.* TO 'maxscale_mon'@'%';
GRANT RELOAD ON *.* TO 'maxscale_mon'@'%';
GRANT PROCESS ON *.* TO 'maxscale_mon'@'%';
GRANT SHOW DATABASES ON *.* TO 'maxscale_mon'@'%';
GRANT EVENT ON *.* TO 'maxscale_mon'@'%';
GRANT SELECT ON mysql.user TO 'maxscale_mon'@'%';
GRANT SELECT ON mysql.global_priv TO 'maxscale_mon'@'%';


-- 2. 代理服务用户 (MaxScale Proxy 用)
CREATE USER IF NOT EXISTS 'maxscale_user'@'%' IDENTIFIED BY 'cH4JtWmDX7P';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER
    ON *.* TO 'maxscale_user'@'%';


-- 3. 主从复制用户 (Replication 用)
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY 'cH4JtWmDX7P';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';

-- 刷新权限
FLUSH PRIVILEGES;

-- 上面所有节点都需要执行

-- 下面从裤执行

CHANGE MASTER TO
  MASTER_HOST='103.219.192.202', # 主库IP
  MASTER_PORT=5306, 
  MASTER_USER='repl',
  MASTER_PASSWORD='cH4JtWmDX7P',
  MASTER_USE_GTID=current_pos;
START SLAVE;
