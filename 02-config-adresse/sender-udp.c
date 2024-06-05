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

#define IP   "127.0.0.1"

int main (int argc, char *argv [])
{
    /* test arg number */

        if (argc != 2) {
        fprintf(stderr, "Usage: %s fournir le numero de port en argument\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    /* convert and check port number */

    const char *port = argv[1];
    // On va qu'a meme convertir le prt en entier pour pouvoir tester la plage contrainte
    int p = atoi(port);
    if (p < 10000 || p > 65000) {
        fprintf(stderr, "Port number must be in the range [10000; 65000]\n");
        exit(EXIT_FAILURE);
    }

    /* create socket */

    int fd_socket = socket(AF_INET, SOCK_DGRAM, 0);
    CHECK(fd_socket);

    /* complete sockaddr struct */

    struct addrinfo hints;
    memset(&hints, 0, sizeof(hints)); // initialisation des valeurs de la structure a 0
    hints.ai_family = AF_INET;     // Famille IPv4
    hints.ai_socktype = SOCK_DGRAM; //Type UDP

    struct addrinfo *lst_addr; // lst_addr stocke la liste de la structure addrinfo
    int fd_getaddrinfo = getaddrinfo(IP, port, &hints, &lst_addr); // Fait la resolution (hints -- IP, Port et met dans lst)
    if (fd_getaddrinfo != 0) {
        fprintf(stderr, "Erreur au niveau de getaddrinfo\n");
        exit(EXIT_FAILURE);
    }
    
    /* send msg to remote peer */

    const char *msg = "hello world";
    ssize_t envoi_msg = sendto(fd_socket, msg, strlen(msg), 0, lst_addr->ai_addr, lst_addr->ai_addrlen);
    CHECK(envoi_msg);

    printf("%s\n", msg);
    /* close socket */
        CHECK(close(fd_socket));

    /* free memory */
    
    freeaddrinfo(lst_addr);
    return 0;
}
