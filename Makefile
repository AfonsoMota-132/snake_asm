# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: afogonca <afogonca@student.42porto.com>    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/07/26 12:00:00 by afogonca          #+#    #+#              #
#    Updated: 2025/07/26 12:07:10 by afogonca         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

CFLAGS = -Wall -Wextra -Werror
CC = cc

NAME = snake
CSRCS = ft_readline.c
COBJS = $(CSRCS:.c=.o)

SSRCS = snake.asm
SOBJS = $(SSRCS:.asm=.o)


all: $(COBJS) $(SOBJS) $(NAME)

$(NAME): $(COBJS) $(SOBJS)
	ld $(SOBJS) $(COBJS) -o $(NAME) -dynamic-linker /lib64/ld-linux-x86-64.so.2 -lc

%.o : %.asm
	nasm -f elf64 $< -o $@

clean:
	rm -fr $(SOBJS)
	rm -fr $(COBJS)

fclean: clean
	rm -fr $(NAME)

re: fclean all

.PHONY = all clean fclean re 
	




