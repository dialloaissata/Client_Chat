#include <sys/socket.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <netinet/in.h>
#include <unistd.h>

#define CHECK(op)   do { if ( (op) == -1) { perror (#op); exit (EXIT_FAILURE); } \
                    } while (0)

#define IP      0x100007f /* 127.0.0.1 */
#define PORT(p) htons(p)

int main (int argc, char *argv [])
{
    /* test arg number */

      if (argc != 2) {
        fprintf(stderr, "Usage: %s fournir le numero de port en argument\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    /* convert and check port number */

    int num_port = atoi(argv[1]);
    if (num_port < 10000 || num_port > 65000)
    {
        fprintf(stderr, "Numero de port incorect\n");
        exit(EXIT_FAILURE);
    }

    /* create socket */

    int socketIPV4 = socket(AF_INET, SOCK_DGRAM, 0); // socketIPV4 est un descripteur de fichier
    CHECK(socketIPV4);

    /* complete sockaddr struct */

    struct sockaddr_storage ss;
    struct sockaddr_in *dest_addr = (struct sockaddr_in *)&ss;

    dest_addr -> sin_family = AF_INET;
    dest_addr -> sin_port = PORT(num_port);
    dest_addr -> sin_addr.s_addr = IP; // Adresse IP du destinataire (127.0.0.1)

    /* send message to remote peer */

    char *msg = "hello world";
    ssize_t envoi_msg  = sendto(socketIPV4, msg, strlen(msg), 0, (struct sockaddr *)dest_addr, sizeof(*dest_addr));
    CHECK(envoi_msg);

    /* close socket */

    CHECK(close(socketIPV4));

    return 0;
}
