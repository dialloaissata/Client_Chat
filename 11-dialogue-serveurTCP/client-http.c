#define _GNU_SOURCE
#include <sys/socket.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <netdb.h>

#define CHECK(op)   do { if ( (op) == -1) { perror (#op); exit (EXIT_FAILURE); } \
                    } while (0)

#define SIZE 100

void cpy (int src, int dst)
{
    char buffer[SIZE];
    ssize_t octets_recus;
    while ((octets_recus = read(src, buffer, SIZE)) > 0)
    {
        CHECK(write(dst, buffer, octets_recus));  
    }
    CHECK(octets_recus);
    return;
}

int main (int argc, char * argv[])
{
    /* test arg number */
    if (argc != 2)
    {
        fprintf(stderr, "usage: %s server_name\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    /* get the list of struct addrinfo */
    
    struct addrinfo *lst;
    struct addrinfo hints = {0};

    hints.ai_family = AF_UNSPEC; // Le DNS qui precise 
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = 0 ;

    int status = getaddrinfo(argv[1], "http", &hints, &lst);
    if (status != 0)
    {
        fprintf(stderr, "getaddrinfo usage: %s\n", gai_strerror(status));
        exit(EXIT_FAILURE);
    }
    if (lst == NULL)
    {
        fprintf(stderr, "la liste contenant les flags est vide\n");
        exit(EXIT_FAILURE);
    }

    /* create socket */
    int sockfd = socket(lst->ai_family, lst->ai_socktype, lst->ai_protocol);
    CHECK(sockfd);

    /* connect to the server */
    int result = connect(sockfd, lst->ai_addr, lst->ai_addrlen);
    CHECK(result);
  
    /* prepare GET cmd */
    char *get_cmd = "GET / HTTP/1.1\r\nHost: %s\r\nConnection: close\r\n\r\n";
    char request[SIZE];
    snprintf(request, SIZE, get_cmd, argv[1]);

    /* send GET cmd and get the response */
    CHECK(send(sockfd, request, strlen(request), 0));
    cpy(sockfd, STDOUT_FILENO);

    /* close socket */
    close(sockfd);
    /* free struct addrinfo list */
    freeaddrinfo(lst);
    return 0;
}
