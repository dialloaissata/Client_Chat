#define _GNU_SOURCE
#include <sys/socket.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <netdb.h>

#define CHECK(op) do { if ((op) == -1) { perror(#op); exit(EXIT_FAILURE); } } while (0)

#define IP "127.0.0.1"
#define SIZE 100 // Taille max du message à envoyer

int main(int argc, char *argv[])
{
    /* test arg number */  

    if (argc != 2)
    {
        fprintf(stderr, "Usage: %s fournir le numéro de port en argument\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    /* convert and check port number */

    int num_port = atoi(argv[1]);
    if (num_port < 10000 || num_port > 65000)
    {
        fprintf(stderr, "Numéro de port incorrect\n");
        exit(EXIT_FAILURE);
    }

    /* create socket */
    int fd_socket = socket(AF_INET, SOCK_DGRAM, 0);
    CHECK(fd_socket);

    /* complete struct sockaddr */
    struct addrinfo hints;
    memset(&hints, 0, sizeof(hints)); // initialisation des valeurs de la structure à 0
    hints.ai_family = AF_INET;        // Famille IPv4
    hints.ai_socktype = SOCK_DGRAM;   // Type UDP

    struct addrinfo *lst_addr; // lst_addr stocke la liste de la structure addrinfo
    char port_str[10];
    snprintf(port_str, sizeof(port_str), "%d", num_port);

    int fd_getaddrinfo = getaddrinfo(IP, port_str, &hints, &lst_addr); // Fait la résolution (hints -- IP, Port et met dans lst)
    if (fd_getaddrinfo != 0)
    {
        fprintf(stderr, "Erreur au niveau de getaddrinfo : %s\n", gai_strerror(fd_getaddrinfo));
        exit(EXIT_FAILURE);
    }

    /* link socket to local IP and PORT */
    CHECK(bind(fd_socket, lst_addr->ai_addr, lst_addr->ai_addrlen));

    /* wait for incoming message */
    char buffer[SIZE];
    memset(buffer, 0, sizeof(buffer));
    ssize_t bits_recus = recvfrom(fd_socket, buffer, sizeof(buffer), 0, NULL, NULL);
    CHECK(bits_recus);

    /* close socket */
    CHECK(close(fd_socket));

    /* free memory */    
    freeaddrinfo(lst_addr);

    /* print received message */
    printf("%s\n", buffer);

    return 0;
}
