#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"

void find(char* dir, char* dst) {
    char buf[512];
    char* p;
    int fd;
    struct dirent de;
    struct stat st;

    // open dir
    if((fd = open(dir, 0)) < 0) {
        fprintf(2, "find: %s cannot open\n", dir);
        return;
    }

    // fill st
    if(fstat(fd, &st) < 0){
        fprintf(2, "find: cannot stat %s\n", dir);
        close(fd);
        return;
    }

    // if st isn't dir, throw err
    if(st.type != T_DIR) {
        fprintf(2, "find: %s not directory\n", dir);
        return;
    }

    // path's len out of memory
    if(strlen(dir) + 1 + DIRSIZ + 1 > sizeof(buf)){
      printf("ls: path too long\n");
      return;
    }

    strcpy(buf, dir);
    p = buf+strlen(buf); // p to the buf's end
    *p++ = '/';

    // de: store name, buf: full path
    while(read(fd, &de, sizeof(de)) == sizeof(de)) {
        if(de.inum == 0) continue; // name's length
        if(!strcmp(de.name, ".") || !strcmp(de.name, "..")) continue; // don't match the rule

        memmove(p, de.name, strlen(de.name) + 1);
        p[strlen(de.name)] = 0;
        if (stat(buf, &st) < 0) { // 将buf指向的文件信息指向st
            fprintf(2, "find: cannot stat %s\n", buf);
            continue;
        }
        if (st.type == T_DIR) {
            find(buf, dst);
        } else if (st.type == T_FILE && !strcmp(de.name, dst)) {
            printf("%s\n", buf);
        }
    }

}

int main(int argc, char* argv[]) {
    if(argc != 3) {
        fprintf(2, "Usage: find dir filename\n");
        exit(1);
    }
    find(argv[1], argv[2]);
    exit(0);
}