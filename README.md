* **ServerA**：运行 MariaDB（主）
* **ServerB**：运行 MariaDB（从）
* **ServerC**：运行 MaxScale

三台服务器跑一个简单的主从集群，并通过 MaxScale 管理，开启 `auto_failover` 和 `auto_rejoin`。

---

## 一、MariaDB 主从（ServerA、ServerB）

在 **两台数据库服务器**上都写一个 `docker-compose.yml`，区别只是 `server_id`。

### ServerA（主库）

```yaml
services:
  mariadb:
    image: mariadb:12.0.2-noble
    container_name: mariadb-master
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: zkim2bPKQW5
      MYSQL_DATABASE: testdb
      MYSQL_USER: pacman
      MYSQL_PASSWORD: zkim2bPKQW5
    ports:
      - "5306:3306"
    volumes:
      - ./master_data:/var/lib/mysql
      - ./master.cnf:/etc/mysql/conf.d/master.cnf
```

`master.cnf` 内容：

```ini
[mysqld]
server_id=1
log_bin=/var/lib/mysql/mysql-bin
binlog_format=ROW

# GTID
gtid_domain_id=1
gtid_strict_mode=ON
log_slave_updates=ON

slave-skip-errors=1396 # 跳过 同名用户错误
```

---

### ServerB（从库）

```yaml
services:
  mariadb:
    image: mariadb:12.0.2-noble
    container_name: mariadb-slave
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: zkim2bPKQW5
      MYSQL_DATABASE: testdb
      MYSQL_USER: pacman
      MYSQL_PASSWORD: zkim2bPKQW5
    ports:
      - "5306:3306"
    volumes:
      - ./slave_data:/var/lib/mysql
      - ./slave.cnf:/etc/mysql/conf.d/slave.cnf
```

`slave.cnf` 内容：

```ini
[mysqld]
server_id=2
relay_log=/var/lib/mysql/relay-bin
log_bin=/var/lib/mysql/mysql-bin
binlog_format=ROW

# GTID
gtid_domain_id=2
gtid_strict_mode=ON
log_slave_updates=ON
slave-skip-errors=1396 # 跳过 同名用户错误
```

---

## 二、MaxScale（ServerC）

`docker-compose.yml`：

```yaml
services:
  maxscale:
    image: mariadb/maxscale:24.02.7-ubi
    container_name: maxscale
    restart: always
    ports:
      - "4006:4006"
      - "8989:8989"   # web管理端口
    volumes:
      - ./maxscale.cnf:/etc/maxscale.cnf
```

---

## 三、MaxScale 配置

maxscale_mon

maxscale_user

修改为root 最快

`maxscale.cnf`：

```ini
[maxscale]
threads=auto
# 测试环境可以
admin_secure_gui=false
# ----------------------
# 后端数据库节点
# ----------------------
[server1]
type=server
address=103.219.192.202   
port=5306
protocol=MariaDBBackend

[server2]
type=server
address=103.219.195.40   
port=5306
protocol=MariaDBBackend

# ----------------------
# 监控模块
# ----------------------
[MariaDB-Monitor]
type=monitor
module=mariadbmon
servers=server1,server2
user=maxscale_mon
password=cH4JtWmDX7P
monitor_interval=2000ms
auto_failover=true
auto_rejoin=true
enforce_read_only_slaves=true

# ----------------------
# 服务和路由
# ----------------------
[Read-Write-Service]
type=service
router=readwritesplit
servers=server1,server2
user=maxscale_user
password=cH4JtWmDX7P

[Read-Write-Listener]
type=listener
service=Read-Write-Service
protocol=MariaDBClient
port=4006
```

---

## 四、准备数据库用户（在任意 MariaDB 节点执行）

```sql

GRANT REPLICATION SLAVE, REPLICATION CLIENT, REPLICATION SLAVE ADMIN, SUPER, RELOAD 
ON *.* TO 'maxscale_user'@'%' IDENTIFIED BY 'cH4JtWmDX7P';


GRANT REPLICATION SLAVE, REPLICATION CLIENT, REPLICATION SLAVE ADMIN, SUPER, RELOAD 
ON *.* TO 'repl'@'%' IDENTIFIED BY 'cH4JtWmDX7P';


GRANT REPLICATION SLAVE, REPLICATION CLIENT, REPLICATION SLAVE ADMIN, SUPER, RELOAD
ON *.* TO 'maxscale_mon'@'%' IDENTIFIED BY 'cH4JtWmDX7P';

-- 刷新权限
FLUSH PRIVILEGES;

-- 上面所有节点都需要执行
```

在从库执行：

```sql

CHANGE MASTER TO
  MASTER_HOST='103.219.192.202', # 主库IP
  MASTER_USER='repl',
  MASTER_PASSWORD='cH4JtWmDX7P',
  MASTER_USE_GTID=current_pos;
START SLAVE;
```

---

## 五、验证

1. 连接 MaxScale：

```bash
mysql -h 192.168.0.103 -P4006 -u maxscale_user -p
```

2. 主库挂掉后，从库会被提升为主。
3. 原主恢复后，因 `auto_rejoin=true` 会自动回到复制集。
