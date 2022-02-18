#include "kernel/types.h"
#include "user/user.h"
#include "kernel/param.h"

#define MAX_LEN 512
#define stdin 0

int main(int argc, char* argv[]) {
    if(argc < 2) {
        fprintf(2, "xargs: usage xargs cmd param");
        exit(1);
    }

    char* param[MAXARG];
    
    for(int index = 1; index < argc; ++index) {
        param[index - 1] = argv[index];
    }

    char buf[MAX_LEN];
    char c;
    int status = 1;

    while(status) {
        int buf_end = 0;
        int param_begin = 0;
        int param_cnt = argc - 1;

        while(1) {
            status = read(stdin, &c, 1);
            if(status == 0) exit(0);

            if(c == ' ' || c == '\n') {
                buf[buf_end++] = 0;
                param[param_cnt++] = &buf[param_begin];
                param_begin = buf_end;
                if(c == '\n') break;
            } else {
                buf[buf_end++] = c;
            }
        }

        param[param_cnt] = 0;

        if(fork() == 0) {
            exec(param[0], param);
        }else {
            wait(0);
        }
    }

    exit(0);
}