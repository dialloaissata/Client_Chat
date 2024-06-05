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

#define IP "127.0.0.1"

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
    int fd_socket = socket(AF_INET, SOCK_STREAM, 0);
    CHECK(fd_socket);

    /* complete struct sockaddr */
    struct addrinfo hints = {0};
    hints.ai_family = AF_INET; // Famille IPv4
    hints.ai_socktype = SOCK_STREAM; // Type TCP
    hints.ai_flags = AI_NUMERICSERV | AI_NUMERICHOST;

    struct addrinfo *lst_addr; // lst_addr stocke la liste de la structure addrinfo
    int fd_getaddrinfo = getaddrinfo(argv[1], argv[2], &hints, &lst_addr); // Fait la resolution (hints -- IP, port et met dans la liste lst_addr)
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

    /* connect to the remote peer  (se connecter à l'homologue distant )*/
    CHECK(connect(fd_socket, lst_addr->ai_addr, lst_addr->ai_addrlen));
   

    /* send the message */
    char *msg = "hello world";
    CHECK(send(fd_socket, msg, strlen(msg), 0));

    /* close socket */
    CHECK(close(fd_socket));

    /* free memory */
    freeaddrinfo(lst_addr);

    return 0;
}


