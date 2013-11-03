#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>

#define MINIX_HEADER 32
#define GCC_HEADER 1024

void die(char *str)
{
    fprintf(stderr, "%s\n", str);
    exit(1);
}

void usage(void)
{
    die("Usage: build boot system [> image]");
}

int main(int argc, char **argv)
{
    int i, c, id;
    char buf[GCC_HEADER] = {0};

    if (argc != 3)
        usage();

    if ((id = open(argv[1], O_RDONLY)) < 0)
        die("Unable to open 'boot'");

    if (read(id, buf, MINIX_HEADER) != MINIX_HEADER)
        die("Unable to read header of 'boot'");

    if (((long *) buf)[0] != 0x04100301)
        die("Non-Minix header of 'boot'");

    if (((long *) buf)[1] != MINIX_HEADER)
        die("Non-Minix header of 'boot'");

    if (((long *) buf)[3] != 0)
        die("Illegal data segment in 'boot'");

    if (((long *) buf)[4] != 0)
        die("Illegal bss in 'boot'");

    if (((long *) buf)[5] != 0)
        die("Non-Minix header of 'boot'");

    if (((long *) buf)[7] != 0)
        die("Illegal symbol table in 'boot'");

    i = read(id, buf, sizeof(buf));

    if (i > 510)
        die("Boot block may not exceed 510 bytes");

    buf[510] = 0x55;
    buf[511] = 0xAA;
    i = write(1, buf, 512);

    if (i != 512)
        die("Write call failed");

    close(id);

    if ((id = open(argv[2], O_RDONLY)) < 0)
        die("Unable to open 'system'");

    if (read(id, buf, GCC_HEADER) != GCC_HEADER)
        die("Unable to read header of 'system'");

    while ((c = read(id, buf, sizeof(buf))) > 0)
        if (write(1, buf, c) != c)
            die("Write call failed");

    close(id);

    return(0);
}
