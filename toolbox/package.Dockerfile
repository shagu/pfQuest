FROM archlinux

RUN pacman -Syy
RUN pacman -S --noconfirm make zip

CMD cd "/src" && make clean full enUS