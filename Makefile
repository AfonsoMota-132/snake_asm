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

NAME = snake

SRCS = snake.asm
OBJS = $(SRCS:.asm=.o)


all: $(OBJS) $(NAME)

$(NAME): $(OBJS)
	ld $(OBJS) -o $(NAME)

%.o : %.asm
	nasm -f elf64 $< -o $@

clean:
	rm -fr $(OBJS)

fclean: clean
	rm -fr $(NAME)

re: fclean all

.PHONY = all clean fclean re 
	




