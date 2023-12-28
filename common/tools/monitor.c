
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <termios.h>
#include <signal.h>
#include <stdlib.h>
#include <sys/select.h>
#include <sys/ioctl.h>

struct termios orig_termios;
struct sigaction old_action;


void reset()
{
	 tcsetattr(0, TCSANOW, &orig_termios);
}

void sigint_handler(int sig_no)
{
	reset();
    	sigaction(SIGINT, &old_action, NULL);
    	kill(0, SIGINT);
}

int ready(int fd)
{
	struct timeval tv = { 0L, 0L };
    	fd_set fds;
    	FD_ZERO(&fds);
    	FD_SET(fd, &fds);
    	return select(1, &fds, NULL, NULL, &tv) > 0;
}

int main(int argc, char *argv[])
{
	char buffer[4097];
	int n;
  	struct termios tty, new_termios;
	struct sigaction action;

	memset(&action, 0, sizeof(action));
	action.sa_handler = &sigint_handler;
    	sigaction(SIGINT, &action, &old_action);

	int fd = open(argv[1], O_RDWR); // | O_NOCTTY | O_NDELAY);
  	if (fd < 0) {
    		perror("Cannot open serial port");
    		return -1;
  	}
  	fcntl(fd, F_SETFL, 0);

	if (tcgetattr(fd, &tty) != 0) {
    		perror("tcgetattr");
    		return -1;
  	}
	 printf("\n%x %x %x\n\n", tty.c_iflag, tty.c_oflag, tty.c_lflag); 
	 
	 tty.c_iflag = 0;
	 tty.c_oflag = 4;
	 tty.c_lflag = 0; 
	
	cfsetospeed(&tty, B115200);
  	cfsetispeed(&tty, B115200);
	tty.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP
                           | INLCR | IGNCR | ICRNL | IXON 
			   | INPCK);
	tty.c_iflag |= BRKINT;
  	tty.c_cflag &= ~PARENB;
  	tty.c_cflag &= ~CSTOPB;
  	tty.c_cflag &= ~CSIZE;
  	tty.c_cflag |= CS8;

	if (tcsetattr(fd, TCSANOW, &tty) != 0) {
    		perror("tcsetattr");
    		return -1;
  	}


	/* terminal */
    	tcgetattr(0, &orig_termios);
    	memcpy(&new_termios, &orig_termios, sizeof(new_termios));
    	atexit(reset);
	new_termios.c_lflag &= ~ICANON;
    	tcsetattr(0, TCSANOW, &new_termios);
	
	printf("press <CTRL-C> to exit\n");
	fflush(stdout);
	while (1) {
		n = 0;
		ioctl(fd, FIONREAD, &n);
		if (n > 0) {
			n = read(fd, buffer, sizeof(buffer)-1);
		}
		if (n > 0) {
			write(1, buffer, n);
		}
		if (ready(0)) {
			read(0, buffer, 1);
			write(fd, buffer, 1);
		} else if (n <= 0) {
			usleep(10000);
		}
	}
  	close(fd);
  	return 0;
}

