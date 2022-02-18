#include "kernel/types.h"
#include "user/user.h"

#define READ 0
#define WRITE 1

int main(int argc, char* argv[]) {

    int n = 1;
    char c;

    int parent2child[2];
    int child2parent[2];
    int p2c = pipe(parent2child); // parent write, child read
    int c2p = pipe(child2parent); // parent read, child write

    if(p2c == -1 || c2p == -1) {
        fprintf(2, "pipe create failed\n");
        exit(1);
    }

    int pid = fork();
    if(pid == -1) { // fork failed
        fprintf(2, "fork failed\n");
        exit(1);
    }else if(pid == 0) { // child read, child write
        close(parent2child[WRITE]);
        close(child2parent[READ]);

        write(child2parent[WRITE], &c, n);

        int len = read(parent2child[READ], &c, 1);
        if (len != 1) {
            fprintf(2, "parent to child can't read\n");
            exit(1);
        }

        printf("%d: received ping\n", getpid());

        close(parent2child[READ]);
        close(child2parent[WRITE]);

        exit(0);
    }else { // parent write, parent read
        close(parent2child[READ]);
        close(child2parent[WRITE]);

        write(parent2child[WRITE], &c, n);

        int len = read(child2parent[READ], &c, 1);

        if(len != 1) {
            fprintf(2, "child to parent can't read\n");
            exit(1);
        }

        wait(0);
        printf("%d: received pong\n", getpid());

        close(parent2child[WRITE]);
        close(child2parent[READ]);

        exit(0);
    }

    exit(0);
}