# Какво е Chitanka Docker Compose?

`Chitanka Docker Compose` е създаден благодарение на [Моята Библиотека](https://https://github.com/chitanka) и [Chitanka Docker](https://github.com/basekat/chitanka-docker).
Използват се само стандартни докер контейнери.

# Как да използваме?

```console
$ git clone https://github.com/Cremator/chitanka-docker-compose.git
$ cd chitanka-docker-compose
... прегледайте docker-compose.yml
```
!!! ВАЖНО !!! Volume content съдържа архив от (~21GB) с всички книги, корици и т.н. Намира се в /var/lib/docker/volumes/chitanka_content
```
 volumes:
  mysql_db_init:
  mysql:
  git:
  content:  !!! ВАЖНО !!!
```
Стартирате
```
docker compose up -d
```

Уверете се, че всички контейнери са стартирани:
```
# docker ps -a
CONTAINER ID   IMAGE                        COMMAND                  CREATED       STATUS                 PORTS                               NAMES
fd695ea5524e   nginx                        "/docker-entrypoint.…"   6 hours ago   Up 6 hours             0.0.0.0:80->80/tcp, :::80->80/tcp   nginx
8d7438b9317f   php:7-fpm                    "docker-php-entrypoi…"   6 hours ago   Up 6 hours             9000/tcp                            php-fpm
1e94d9c4bdae   willfarrell/crontab:latest   "/sbin/tini -- /dock…"   6 hours ago   Up 6 hours (healthy)                                       cron
cc586e790a81   mariadb                      "docker-entrypoint.s…"   6 hours ago   Up 6 hours             3306/tcp                            mariadb
```

При първоначалното стартиране на `chitanka`, ще бъде изтеглена актуалната версия на базата от данни на [Моята Библиотека](https://github.com/chitanka)
Съдържанието (архива) на [Моята Библиотека](https://github.com/chitanka) ще бъде обновено като стартирате или рестартирате cron контейнера и на всеки 12 часа.

- `Windows` - Добавете към C:\Windows\System32\drivers\etc\hosts `127.0.0.1 chitanka.local`
- `Linux` - `echo "127.0.0.1 chitanka.local" >> /etc/hosts`
Отворете [Вашата Библиотека](http://chitanka.local)

# Информация за отделните услуги

## `mariadb`

`mariadb` контейнерът използва стандартен MariaDB docker image - текущата версия. Настройте `MYSQL_` параметрите или използвайте тези по подразбиране.
```
  mariadb:
    image: mariadb
    ...
    environment: 
      ...
      MYSQL_ALLOW_EMPTY_PASSWORD: yes
      MYSQL_DATABASE: chitanka
    volumes:
      - mysqldb_init:/docker-entrypoint-initdb.d
    ...
```

## `php-fpm`

`php-fpm` контейнерът използва стандартен php-fpm docker image - 7-ма версия. Добавени са следните PHP добавки `mysqli|pdo_mysql|gd|intl|curl|mbstring|xsl|zip`.

```
  php-fpm:
    image: php:7-fpm
    ...
    volumes:
      - content:/var/www
    ...
```

## `nginx`

`nginx` контейнерът използва стандартен nginx docker image - текущата версия. 
```
  nginx:
    image: nginx
    ...
    environment: 
      ...
      NGINX_SERVER_NAME: chitanka.local
      NGINX_FASTCGI_PASS: php-fpm:9000
    depends_on:
      - php-fpm
    volumes:
      - ./default.conf.template:/etc/nginx/templates/default.conf.template
      - content:/var/www
    ports:
      - 80:80
```

- `NGINX_SERVER_NAME` - В случай, че имате свой домейн, можете да го конфигурирате в този параметър.
- `NGINX_FASTCGI_PASS` - В случай, че искате да ползвате различен PHP-FPM upstream, можете да го конфигурирате в този параметър.

Ако искате уеб сървъра да слуша на друг порт (например 8080), можете да го смените в секцията `ports`:
```
ports:
  - 8080:80
```

- `default.conf.template`  е шаблон, който бива използван за динамично генериране на конфигурацията за виртуалния хост. Използван е [ngix.conf](https://github.com/chitanka/chitanka-installer/blob/master/nginx-vhost.conf) от [Автоматичния инсталатор](https://github.com/chitanka/chitanka-installer)
```
      - ./default.conf.template:/etc/nginx/templates/default.conf.template
```

## `cron`

`cron` контейнерът използва стандартен crontab docker image - текущата версия. Kонтейнерът се използва за автоматичното обновяване на съдържанието.

```
cron:
    container_name: cron
    image: willfarrell/crontab:latest
    restart: unless-stopped
    logging: *default-logging
    environment: 
      <<: *default-env
      CRON_CHITANKA_GIT: https://github.com/chitanka/chitanka-production.git
      CRON_CHITANKA_CONTENT: rsync.chitanka.info::content/
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./docker-compose.yml:/opt/crontab/docker-compose.yml:ro
      - ./parameters.yml:/opt/crontab/parameters.yml:ro
      - ./chitanka.cron.sh:/opt/crontab/chitanka.cron.sh:ro
      - ./config.json:/opt/crontab/config.json:rw"
      - mysqldb_init:/opt/crontab/mysqldb_init
      - git:/opt/crontab/chitanka_git
      - content:/opt/crontab/chitanka_content
```

- `CRON_CHITANKA_GIT` - В случай, че искате да използвате различен код, можете да го конфигурирате в този параметър.
- `CRON_CHITANKA_CONTENT` - В случай, че искате да ползвате различен rsync сорс за съдържание, можете да го конфигурирате в този параметър.

# Обновяване

За да извършите обновяване на версията на всички docker image-и:
```console
docker-compose down
docker-compose pull
docker-compose up -d
```

# Изтриване на всичко

Ако искате да започнете наново и да изтриете всички volumes (без content), можете да използвате следната команда:
```console
docker compose down
docker volume rm chitanka_git chitanka_mysql_db_init chitanka_mysql
```

# Докладване на проблеми

Ако искате да докладвате проблем или имате идея - [Issues](https://github.com/Cremator/chitanka-docker-compose/issues)