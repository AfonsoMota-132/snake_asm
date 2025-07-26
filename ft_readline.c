/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_readline.c                                      :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: afogonca <afogonca@student.42porto.com>    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2024/12/17 19:55:02 by afogonca          #+#    #+#             */
/*   Updated: 2025/07/26 12:07:23 by afogonca         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include <fcntl.h>
#include <readline/history.h>
#include <readline/readline.h>
#include <termios.h>
#include <unistd.h>

char ft_get_keypress() {
  struct termios oldt, newt;
  char ch;

  tcgetattr(STDIN_FILENO, &oldt);
  newt = oldt;
  newt.c_lflag &= ~(ICANON | ECHO);
  newt.c_cc[VMIN] = 0;
  newt.c_cc[VTIME] = 1;
  tcsetattr(STDIN_FILENO, TCSANOW, &newt);
  read(STDIN_FILENO, &ch, 1);
  tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
  return (ch);
}
