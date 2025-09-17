-- 监控用户
CREATE USER 'maxscale_mon'@'%' IDENTIFIED BY 'monitor_pass';
GRANT REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO 'maxscale_mon'@'%';

-- 代理服务用户
CREATE USER 'maxscale_user'@'%' IDENTIFIED BY 'service_pass';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON *.* TO 'maxscale_user'@'%';

-- 主从复制用户（手动建立主从）
CREATE USER 'repl'@'%' IDENTIFIED BY 'replpass';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';


-- 上面所有节点都需要执行

-- 下面从裤执行

CHANGE MASTER TO
  MASTER_HOST='192.168.0.101',
  MASTER_USER='repl',
  MASTER_PASSWORD='replpass',
  MASTER_USE_GTID=current_pos;
START SLAVE;
