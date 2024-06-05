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

#define IP   "::1"
#define SIZE 100

int main (int argc, char *argv [])
{
    /* test arg number */
    if(argc != 3)
    {
        fprintf(stderr, "usage: %s ip_addr port_number\n", argv[0]);        
        exit(EXIT_FAILURE);
    }

    /* convert and check port number */
    int num_port = atoi(argv[2]);
    if(num_port < 10000 || num_port > 65000)
    {
        fprintf(stderr, "Numero de port incorrect\n");
        exit(EXIT_FAILURE);
    }

    /* create socket */
    int fd_socket = socket(AF_INET6, SOCK_DGRAM, 0);
    CHECK(fd_socket);

    /* complete struct sockaddr */
    struct addrinfo hints = {0};
    hints.ai_family = AF_INET6; // Famille IPV4
    hints.ai_socktype = SOCK_DGRAM; // Type UDP
    hints.ai_flags = AI_PASSIVE;

    struct addrinfo *lst_addr; // lst_addr stcke la liste de la structure addrinfo
    int fd_getaddrinfo = getaddrinfo(argv[1], argv[2], &hints , &lst_addr); // Fait la resolution (hints -- IP, port et met dans la liste lst_addr)
    if(fd_getaddrinfo != 0)
    {
        fprintf(stderr, "Name or service not known\n");        
        exit(EXIT_FAILURE);
    }
    if(lst_addr == NULL)
    {
        fprintf(stderr, "lst_addr est vide\n");
        exit(EXIT_FAILURE);
    }

    /* link socket to local IP and PORT */
    CHECK(bind(fd_socket, lst_addr -> ai_addr, lst_addr -> ai_addrlen));

    /* wait for incoming message */
    struct sockaddr_storage sender_addr;
    socklen_t sender_addr_len = sizeof(sender_addr);
    char buffer[SIZE];

    ssize_t octets_recus = recvfrom(fd_socket, buffer, SIZE - 1, 0, (struct sockaddr *)&sender_addr, &sender_addr_len);
    CHECK(octets_recus);

    buffer[octets_recus] = '\0'; // Ajouter le caractère nul à la fin du message reçu
    printf("%s", buffer); 
    
    /* print sender addr and port */
    char host[INET6_ADDRSTRLEN];
    char serv[NI_MAXSERV];
    int fd_getnameinfo = getnameinfo((struct sockaddr *)&sender_addr, sender_addr_len, host, INET6_ADDRSTRLEN, serv, NI_MAXSERV, NI_NUMERICHOST);
    if(fd_getnameinfo == 0)
        printf("%s %s\n", host, serv);
    else
        fprintf(stderr, "getnameinfo error: %s\n", gai_strerror(fd_getnameinfo));    

    /* close socket */
    CHECK(close(fd_socket));

    /* free memory */
    freeaddrinfo(lst_addr);

    return 0;
}
