#include "kernel/types.h"
#include "user/user.h"

#define READ 0
#define WRITE 1

void computePrime(int pd[]) {
    int fd[2];
    int prime;
    int len;

    close(pd[WRITE]);
    if((len = read(pd[READ], &prime, sizeof(int))) <= 0) {
        exit(1);
    }
    printf("prime %d\n", prime);

    int p = pipe(fd);
    if(p == -1) {
        fprintf(2, "pipe create failed\n");
        exit(1);
    }

    int n;
    if(fork() == 0) { // child
        close(fd[WRITE]);
        computePrime(fd);
    }else { // parent
        close(fd[READ]);
        while((len = read(pd[READ], &n, sizeof(int))) > 0) {
            if(n % prime != 0) {
                write(fd[WRITE], &n, sizeof(int));
            }
        }
        close(pd[READ]);
        close(fd[WRITE]);
        wait(0);
    }
    exit(0);
}

int main(int argc, char* argv[]) {
    int pd[2];

    int p = pipe(pd);
    if(p == -1) {
        fprintf(2, "pipe create failed\n");
        exit(1);
    }

    if(fork() == 0) { // child
        close(pd[WRITE]);
        computePrime(pd);
    }else { // parent
        close(pd[READ]);
        for(int i = 2; i <= 35; ++i) {
            write(pd[WRITE], &i, sizeof(int));
        }
        close(pd[WRITE]);
        wait(0);
    }
    exit(0);
}