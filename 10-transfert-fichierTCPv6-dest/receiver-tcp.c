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

#define CHECK(op)   do { if ( (op) == -1) { perror (#op); exit (EXIT_FAILURE); } \
                    } while (0)

#define IP   "::1"
#define SIZE 100
#define QUEUE_LENGTH 1

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

int main (int argc, char *argv [])
{
    /* test arg number */
    if (argc != 3) {
        fprintf(stderr, "usage: %s ip_addr port_number\n", argv[0]);
        exit(EXIT_FAILURE);
    }
    /* convert and check port number */
    int port = atoi(argv[2]);
    if (port < 10000 || port > 65000) 
    {
        fprintf(stderr, "Numéro de port invalide\n");
        exit(EXIT_FAILURE);
    }
    /* create socket */
    int sockfd = socket(AF_INET6, SOCK_STREAM, 0);
    CHECK(sockfd);

    /* SO_REUSEADDR option allows re-starting the program without delay */
    int iSetOption = 1;
    CHECK (setsockopt (sockfd, SOL_SOCKET, SO_REUSEADDR, &iSetOption,
		       sizeof iSetOption));

    /* complete struct sockaddr */
    struct addrinfo *result;
    struct addrinfo hints = {0};

    hints.ai_family = AF_INET6;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_NUMERICSERV | AI_NUMERICHOST;

    int status = getaddrinfo(argv[1], argv[2], &hints, &result);
    if (status != 0)
    {
        fprintf(stderr, "getaddrinfo usage: %s\n", gai_strerror(status));
        exit(EXIT_FAILURE);
    }
    if (result == NULL)
    {
        fprintf(stderr, "result est vide\n");
        exit(EXIT_FAILURE);
    }


    /* link socket to local IP and PORT */
    CHECK(bind(sockfd, result->ai_addr, result->ai_addrlen));

    /* set queue limit for incoming connections */
    CHECK(listen(sockfd, QUEUE_LENGTH));

    /* wait for incoming TCP connection */
    struct sockaddr_storage clientAddr;
    socklen_t taille = sizeof(clientAddr);
    int new_sockfd = accept(sockfd, (struct sockaddr *)&clientAddr, &taille);
    CHECK(new_sockfd);

    /* open local file */
    int file = open("copy.tmp", O_WRONLY | O_CREAT | O_TRUNC, 0666);
    CHECK(file);

    /* get the transmitted file */
    cpy(new_sockfd, file);

    /* close sockets */
    close(new_sockfd);
    close(sockfd);

    /* close file */
    close(file);

    /* free memory */
    freeaddrinfo(result);
    
    return 0;
}
