FROM archlinux

RUN pacman -Syy
RUN pacman -S --noconfirm gcc make git mariadb mariadb-clients luarocks
RUN luarocks install luasql-mysql MYSQL_INCDIR=/usr/include/mysql

CMD cd "/toolbox" && make