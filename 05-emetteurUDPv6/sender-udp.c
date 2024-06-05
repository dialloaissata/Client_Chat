#define _GNU_SOURCE
#include <sys/socket.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <netinet/in.h>
#include <unistd.h>
#include <netdb.h>

#define CHECK(op)   do { if ( (op) == -1) { perror (#op); exit (EXIT_FAILURE); } \
                    } while (0)

#define IP "::1"

int main (int argc, char *argv [])
{
    /* test arg number */
    if (argc != 3) {
        fprintf(stderr, "usage: ./sender-udp ip_addr port_number\n");
        exit(EXIT_FAILURE);
    }

    /* convert and check port number */
    const char *port = argv[2];
    // On va qu'a meme convertir le prt en entier pour pouvoir tester la plage contrainte
    int p = atoi(port);
    if (p < 10000 || p > 65000) {
        fprintf(stderr, "usage: %s port_number\n", argv[2]);        
        exit(EXIT_FAILURE);
    }


    /* create socket */
    int socketIPV6 = socket(AF_INET6, SOCK_DGRAM, 0); // socketIPV6 est un descripteur de fichier
    CHECK(socketIPV6);


    /* fill in dest IP and PORT */
    struct addrinfo hints = {0};
    hints.ai_family = AF_INET6;     // Famille IPv6
    hints.ai_socktype = SOCK_DGRAM; //Type UDP
    hints.ai_flags = AI_PASSIVE;

    struct addrinfo *lst_addr; // lst_addr stocke la liste de la structure addrinfo
    int fd_getaddrinfo = getaddrinfo(argv[1], argv[2], &hints, &lst_addr); // Fait la resolution (hints -- IP, Port et met dans lst)
    if (fd_getaddrinfo != 0) {
       // fprintf(stderr, "Name or service not known %s\n", gai_strerror(fd_getaddrinfo));
        fprintf(stderr, "Name or service not known\n");
        exit(EXIT_FAILURE);
    }
    if(lst_addr == NULL)
    {
        fprintf(stderr, "lst_addr est vide\n");
        exit(EXIT_FAILURE);
    }

    /* send message to remote peer */
    const char *msg = "hello world\0";
    ssize_t envoi_msg = sendto(socketIPV6, msg, strlen(msg), 0, lst_addr->ai_addr, lst_addr->ai_addrlen);
    CHECK(envoi_msg);
    
    printf("%s\n", msg);

    /* close socket */
    CHECK(close(socketIPV6));

    /* free memory */
    freeaddrinfo(lst_addr);

    return 0;
}
