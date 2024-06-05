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

#define IP   "127.0.0.1"
#define SIZE 100
#define QUEUE_LENGTH 1

int main (int argc, char *argv [])
{
    /* test arg number */
    if (argc != 3)
    {
        fprintf(stderr, "usage: %s ip_addr port_number\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    /* convert and check port number */
    int num_port = atoi(argv[2]);
    if (num_port < 10000 || num_port > 65000)
    {
        fprintf(stderr, "usage: %s Numero de port incorrect\n", argv[2]);
        exit(EXIT_FAILURE);
    }

    /* create socket */
    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    CHECK(sockfd);

    /* L'option SO_REUSEADDR permet de redémarrer le programme sans délai */
    /* L'option SO_REUSEADDR permet de réutiliser immédiatement une adresse locale sans attendre sa libération.*/
    int iSetOption = 1; // spécifie la valeur de l'option à définir pour le socket pour SO_REUSEADDR
    CHECK (setsockopt (sockfd, SOL_SOCKET, SO_REUSEADDR, &iSetOption, sizeof iSetOption));

    /* complete struct sockaddr */
    struct addrinfo hints = {0};
    hints.ai_family = AF_INET; // Famille IPv4
    hints.ai_socktype = SOCK_STREAM; // Type TCP
    hints.ai_flags = AI_NUMERICSERV | AI_NUMERICHOST;

    struct addrinfo *lst_addr;
    int fd_getaddrinfo = getaddrinfo(argv[1], argv[2], &hints, &lst_addr);
    if (fd_getaddrinfo != 0)
    {
        fprintf(stderr, "getaddrinfo usage: %s\n", gai_strerror(fd_getaddrinfo));
        exit(EXIT_FAILURE);
    }
    if (lst_addr == NULL)
    {
        fprintf(stderr, "lst_addr est vide\n");
        exit(EXIT_FAILURE);
    }

    /* link socket to local IP and PORT */
    CHECK(bind(sockfd, lst_addr->ai_addr, lst_addr->ai_addrlen));

    /* set queue limit for incoming connections (definir la limite de la file d'attente) */
    CHECK(listen(sockfd, QUEUE_LENGTH));

    /* wait for incoming TCP connection */
    struct sockaddr_storage sender_addr;
    socklen_t sender_addr_len = sizeof(sender_addr);
    int new_sockfd = accept(sockfd, (struct sockaddr *)&sender_addr, &sender_addr_len);
    CHECK(new_sockfd);

    /* print sender addr and port */
    char host[NI_MAXHOST];
    char service[NI_MAXSERV];
    int fd_getnameinfo = getnameinfo((struct sockaddr *)&sender_addr, sender_addr_len, host, NI_MAXHOST, service, NI_MAXSERV, NI_NUMERICHOST | NI_NUMERICSERV );
    if (fd_getnameinfo == 0)
        printf("%s %s\n", host, service);
    else
        fprintf(stderr, "getnameinfo error: %s\n", gai_strerror(fd_getnameinfo));

    /* wait for incoming message */
    char buffer[SIZE];
    ssize_t octets_recus = recv(new_sockfd, buffer, SIZE, 0);
    CHECK(octets_recus);
   
    /* close sockets */
    CHECK(close(new_sockfd));
    CHECK(close(sockfd));

    /* free memory */
    freeaddrinfo(lst_addr);

    /* print received message */
    buffer[octets_recus] = '\0';
    printf("%s", buffer);

    return 0;
}



