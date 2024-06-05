#define _GNU_SOURCE
#include <sys/socket.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <fcntl.h>
#include <netdb.h>

#define CHECK(op) do { if ( (op) == -1) { perror (#op); exit (EXIT_FAILURE); } } while (0)

#define SIZE 100

void cpy (int src, int dst) 
{
    char buffer[SIZE];
    ssize_t bytes_read;
    while ((bytes_read = read(src, buffer, SIZE)) > 0) 
    {
        ssize_t bytes_written = write(dst, buffer, bytes_read);
        CHECK(bytes_written);
    }
    CHECK(bytes_read);
}

int main (int argc, char *argv []) {
    /* test arg number */
    if (argc != 4)
    {
        fprintf(stderr, "usage: %s ip_addr port_number filename\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    /* convert and check port number */
    int num_port = atoi(argv[2]);
    if (num_port < 10000 || num_port > 65000)
    {
        fprintf(stderr, "usage: %s Numero de port incorrect\n", argv[2]);
        exit(EXIT_FAILURE);
    }

    /* open file to send */
    int fd = open(argv[3], O_RDONLY);
    CHECK(fd);

    /* create socket */
    int sockfd = socket(AF_INET6, SOCK_STREAM, 0);
    CHECK(sockfd);

   /* complete struct sockaddr */
    struct addrinfo hints = {0}, *res;
    hints.ai_family = AF_INET6;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_NUMERICSERV | AI_NUMERICHOST;

    int status = getaddrinfo(argv[1], argv[2], &hints, &res);
    if (status != 0) {
        fprintf(stderr, "getaddrinfo error: %s\n", gai_strerror(status));
        exit(EXIT_FAILURE);
    }
    if(res == NULL)
    { 
        fprintf(stderr, "la liste res est vide\n");
        exit(EXIT_FAILURE);  
    }

    /* connect to the remote peer */
    if (connect(sockfd, res->ai_addr, res->ai_addrlen) == -1) {
        perror("Erreur de connection\n");
        exit(EXIT_FAILURE);
    }

    /* send the file content */
    cpy(fd, sockfd);

    /* close socket */
    close(sockfd);

    /* close file */
    close(fd);

    /* free memory */
    freeaddrinfo(res);

    return 0;
}
