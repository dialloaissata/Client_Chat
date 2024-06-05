#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <poll.h>
#include <netdb.h>
#include <sys/types.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <arpa/inet.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <netinet/in.h>

#define CHECK(op)               \
    do                          \
    {                           \
        if ((op) == -1)         \
        {                       \
            perror(#op);        \
            exit(EXIT_FAILURE); \
        }                       \
    } while (0)

#define PORT(p) htons(p)
#define MAX_MESSAGE_SIZE 1024

// Constante HELO et QUIT de taille = 1 octet
#ifdef BIN
#define HELO (uint8_t)0x1
#define QUIT (uint8_t)0x0
#endif

// Nombre d'utilisateurs pouvant se connecter
#ifdef USR
#define MAX_USERS 3
#endif

int main(int argc, char *argv[])
{
#ifdef BIN
    // Initialisation des tableaux
    uint8_t bufBin_Helo[1] = {HELO};
    uint8_t bufBin_Quit[1] = {QUIT};
#endif
#ifdef USR
    int numUsers = 0;
    struct sockaddr_in6 userAddresses[MAX_USERS]; // Tableau pour stocker les adresses IP
#endif
    /* test arg number */
    if (argc != 2)
    {
        fprintf(stderr, "usage: %s port_number\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    /* convert and check port number */
    int port = atoi(argv[1]);
    if (port < 10000 || port > 65000)
    {
        fprintf(stderr, "Numero de port invalide. choisir entre [10000, 65000].\n");
        exit(EXIT_FAILURE);
    }

    /* create socket */
    int sockfd = socket(AF_INET6, SOCK_DGRAM, 0);
    CHECK(sockfd);

    /* set dual stack socket */
    // Desactiver l'option IPV6_V6ONLY pour que ca prenne du IPV4 aussi
    int value = 0;
    CHECK(setsockopt(sockfd, IPPROTO_IPV6, IPV6_V6ONLY, &value, sizeof value));

    /* set local addr */
    struct sockaddr_in6 ss = {0};
    struct sockaddr_in6 *in6 = (struct sockaddr_in6 *)&ss;
    in6->sin6_family = AF_INET6;
    in6->sin6_port = PORT(port);
    in6->sin6_addr = in6addr_any; // Utiliser toutes les @ disponibles

    /* bind socket */
    // Lie le socket à une adresse et un port local
    int bindfd = bind(sockfd, (struct sockaddr *)in6, sizeof(*in6));

    /* check if a client is already present */
    socklen_t addr_len = sizeof(ss);
    char buffer[MAX_MESSAGE_SIZE];
    memset(buffer, 0, MAX_MESSAGE_SIZE); // Initialisation du buffer

    if (bindfd == -1)
    {
        // Si l'erreur est du au fait que l'adresse soit utilisé
        //  Action : Send /HELO.
        if (errno == EADDRINUSE)
        {
#ifdef BIN
            CHECK(sendto(sockfd, bufBin_Helo, 1, 0, (struct sockaddr *)in6, addr_len));
#else
            CHECK(sendto(sockfd, "/HELO", 5, 0, (struct sockaddr *)in6, addr_len));
#endif
        }
    }
    else
    {
#ifdef USR
        while (numUsers < MAX_USERS)
        {
            memset(buffer, 0, MAX_MESSAGE_SIZE);
            // Attente d'un message d'un utilisateur
            ssize_t bytesRecv = recvfrom(sockfd, buffer, MAX_MESSAGE_SIZE - 1, 0, (struct sockaddr *)in6, &addr_len);
            CHECK(bytesRecv);

            // Vérification du message reçu
            if (strncmp(buffer, "/HELO", 5) == 0)
            {
                // Si le message est /HELO, afficher les informations sur l'utilisateur
                char host[NI_MAXHOST];
                char server[NI_MAXSERV];
                int result = getnameinfo((struct sockaddr *)in6, addr_len, host, NI_MAXHOST, server, NI_MAXSERV, NI_NUMERICHOST | NI_NUMERICSERV);
                if (result != 0)
                {
                    fprintf(stderr, "getnameinfo: %s\n", gai_strerror(result));
                }
                printf("User %d: %s %s\n", numUsers, host, server);

                // Recupere les adresses des utilisateurs connectés
                memcpy(&userAddresses[numUsers], &in6->sin6_addr, sizeof(struct in6_addr));
                numUsers++;
            }
        }
        printf("Server is full.\n");
#else

        // S'il a réeussi a lier l'adresse et le port, ce qu'il n'y a personne qui l'utilise
        /*
        Attendre que quelqu'un se connecte et l'envoie /HELO
        Event: recv / HELO
        Action : print remote addr and port
        */
#ifdef BIN
        uint8_t buffer_bin[1];
        while ((memcmp(buffer_bin, bufBin_Helo, 1) != 0))
        {
            ssize_t bytesRecv = recvfrom(sockfd, buffer_bin, 1, 0, (struct sockaddr *)in6, &addr_len);
            CHECK(bytesRecv);
        }
#else
        while ((strncmp(buffer, "/HELO", 5) != 0))
        {
            ssize_t bytesRecv = recvfrom(sockfd, buffer, MAX_MESSAGE_SIZE - 1, 0, (struct sockaddr *)in6, &addr_len);
            CHECK(bytesRecv);
        }
#endif
        char host[NI_MAXHOST];
        char server[NI_MAXSERV];
        int result = getnameinfo((struct sockaddr *)in6, addr_len, host, NI_MAXHOST, server, NI_MAXSERV, NI_NUMERICHOST | NI_NUMERICSERV);
        if (result != 0)
        {
            fprintf(stderr, "getnameinfo: %s\n", gai_strerror(result));
        }
        printf("%s %s\n", host, server); // Affiche l'adresse et le port
#endif
    }

    /* prepare struct pollfd with stdin and socket for incoming data */
    struct pollfd poll_fds[2];
    poll_fds[0].fd = STDIN_FILENO;
    poll_fds[0].events = POLLIN;
    poll_fds[1].fd = sockfd;
    poll_fds[1].events = POLLIN;

    /* main loop */
    int run = 1;
    char msg[MAX_MESSAGE_SIZE];

    while (run)
    {
        CHECK(poll(poll_fds, 2, -1));
        // Surveiller les evenements de la rentrée standart
        if (poll_fds[0].revents & POLLIN)
        {
            memset(msg, 0, MAX_MESSAGE_SIZE);
            ssize_t donnees_lues = read(STDIN_FILENO, msg, MAX_MESSAGE_SIZE);
            // Si aucune donnée n'est lu, cela signifie que l'utilisateur a fermé l'entree standart
            // exemple: Ctrl+D, donc il faut sortir de la boucle et prevenir l'autre
            if (donnees_lues == 0)
            {
#ifdef BIN
                CHECK(sendto(sockfd, bufBin_Quit, 1, 0, (struct sockaddr *)in6, addr_len));
#else
                CHECK(sendto(sockfd, "/QUIT", 5, 0, (struct sockaddr *)in6, addr_len));
#endif
                run = 0;
            }
            // Si le message entrée est QUIT, envoyer à l'autre utilisateur le message QUIT
            if (strncmp(msg, "/QUIT", 5) == 0)
            {
#ifdef BIN
                msg[0] = QUIT;
                msg[1] = '\0';
                CHECK(sendto(sockfd, msg, strlen(msg), 0, (struct sockaddr *)in6, addr_len));
                run = 0;
#else
                CHECK(sendto(sockfd, msg, strlen(msg), 0, (struct sockaddr *)in6, addr_len));
                run = 0;

#endif
            }
            // Si le message entrée n'est pas /QUIT, envoyer à l'autre utilisateur le message ecrit
            else
            {
#ifdef FILEIO
                // Si le message lu au clavier commence par /FILE, on est dans le cas du transfert de fichier
                if (strncmp(msg, "/FILE", 5) == 0)
                {
                    /*Si les 5 premiers caracteres sont identique a /FILE on envoie à l'autre utilisateur
                      pour le prevenir qu'il s'agit d'un transfert de fichier*/
                    CHECK(sendto(sockfd, msg, strlen(msg), 0, (struct sockaddr *)in6, addr_len));
                    //  Extraire le nom du fichier de la commande , puisque /FILE est suivit du nom du fichier à envoyer
                    char filename[MAX_MESSAGE_SIZE];
                    if (sscanf(msg, "/FILE %s", filename) != 1)
                    {
                        fprintf(stderr, "Format de commande invalide, saisir le nom du fichier après\n");
                        exit(EXIT_FAILURE);
                    }
                    int file = open(filename, O_RDONLY);
                    CHECK(file);

                    int sequence_number = 0;
                    while (1)
                    {
                        ssize_t bytesRead = read(file, msg, sizeof(msg));
                        if (bytesRead > 0)
                        {
                            // Envoyer le paquet avec le numéro de séquence
                            CHECK(sendto(sockfd, &sequence_number, sizeof(sequence_number), 0, (struct sockaddr *)in6, addr_len));
                            CHECK(sendto(sockfd, msg, bytesRead, 0, (struct sockaddr *)in6, addr_len));
                            // Attendre l'ACK correspondant
                            int ack_number;
                            ssize_t ack_len = recvfrom(sockfd, &ack_number, sizeof(ack_number), 0, (struct sockaddr *)in6, &addr_len);
                            // Si l'ACK est correct, incrémenter le numéro de séquence
                            if (ack_len == sizeof(ack_number) && ack_number == sequence_number)
                            {
                                sequence_number++;
                            }
                            else
                            {
                                // L'ACK n'est pas correct, revenir sur le paquet perdu et le retransmettre
                                off_t offset = -bytesRead;
                                CHECK(lseek(file, offset, SEEK_CUR));
                            }
                        }
                        else
                        {
                            // S'il n'y a plus rien a lire, sortir de la boucle car fin du fichier
                            printf("Fin de transmission\n");
                            break;
                        }
                    }
                    CHECK(close(file));
                }
                // S'il ne s'agit pas de transfert de fichier, envoyer simplement le message lu au clavier
                else
                {
                    CHECK(sendto(sockfd, msg, strlen(msg), 0, (struct sockaddr *)in6, addr_len));
                }
#else
                // S'il n'y a pas de message QUIT, ils continuent à s'envoyer des messages
                /* Event: type DATA
                Action: send DATA */
                CHECK(sendto(sockfd, msg, strlen(msg), 0, (struct sockaddr *)in6, addr_len));

#endif
            }
        }

        // Surveiller les evenements d'entrees du socket
        if (poll_fds[1].revents & POLLIN)
        {
            memset(msg, 0, MAX_MESSAGE_SIZE);
            ssize_t recv_len = recvfrom(sockfd, msg, MAX_MESSAGE_SIZE, 0, (struct sockaddr *)in6, &addr_len);
            CHECK(recv_len);
            // Si message recu est QUIT, fermer la conversation en sortant de la boucle
            //  Event: rcv /QUIT

#ifdef BIN
            if (msg[0] == QUIT)
            {
                run = 0;
            }
            else
            {
                /* Event: recv DATA
                Action: print DATA */
                printf("%s", msg);
            }
#else
            if (strncmp(msg, "/QUIT", 5) == 0)
            {
                run = 0;
            }
            else
            {
#ifdef FILEIO
                // Si message recu commence par le mot /FILE, il s'agit du transfert de fichier
                if (strncmp(msg, "/FILE", 5) == 0)
                {
                    char filename[MAX_MESSAGE_SIZE];
                    char new_filename[MAX_MESSAGE_SIZE + 5]; // Ajout de 5 pour "_recu" et le caractère nul '\0'
                    if (sscanf(msg, "/FILE %s", filename) != 1)
                    {
                        fprintf(stderr, "Format de commande invalide, saisir le nom du fichier après\n");
                        exit(EXIT_FAILURE);
                    }
                    // Ajouter la chaîne de caractères "_recu" au nom du fichier, pour eviter la ressemblance entre les 2 noms de fichiers
                    snprintf(new_filename, sizeof(new_filename), "%s_recu", filename);
                    int file_out = open(new_filename, O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
                    CHECK(file_out);
                    int expected_sequence_number = 0;
                    ssize_t totalReceivedSize = 0; // quantite total de données recues
                    while (1)
                    {
                        // Attendre le paquet avec le numéro de séquence
                        int received_sequence_number;
                        ssize_t seq_len = recvfrom(sockfd, &received_sequence_number, sizeof(received_sequence_number), 0, (struct sockaddr *)in6, &addr_len);
                        if (seq_len == sizeof(received_sequence_number) && received_sequence_number == expected_sequence_number)
                        {
                            // Répondre avec l'ACK
                            CHECK(sendto(sockfd, &received_sequence_number, sizeof(received_sequence_number), 0, (struct sockaddr *)in6, addr_len));

                            // Attendre le paquet de données
                            ssize_t recv_len = recvfrom(sockfd, msg, MAX_MESSAGE_SIZE, 0, (struct sockaddr *)in6, &addr_len);
                            CHECK(recv_len);
                            totalReceivedSize = totalReceivedSize + recv_len;

                            // Ecrire le contenu dans le fichier de reception
                            int ret = write(file_out, msg, recv_len);
                            CHECK(ret);
                            expected_sequence_number++;

                            // Taille du fichier
                            struct stat file_stat;
                            CHECK(stat(filename, &file_stat));
                            off_t file_size = file_stat.st_size;
                            // Condition pour sortir de la boucle si la taille total des données envoyé = la taille total des donnees recues
                            if (totalReceivedSize == file_size)
                            {
                                printf("Fichier recu\n");
                                break;
                            }
                        }
                        else
                        {
                            // Réenvoyer l'ACK attendu si le numéro de séquence ne correspond pas
                            CHECK(sendto(sockfd, &expected_sequence_number, sizeof(expected_sequence_number), 0, (struct sockaddr *)in6, addr_len));
                        }
                    }
                    CHECK(close(file_out));
                }
                else
                {
                    /* Event: recv DATA
                Action: print DATA */
                    printf("%s", msg);
                }

#else
                /* Event: recv DATA
                Action: print DATA */
                printf("%s", msg);
#endif
            }
#endif
        }
    }
    /* close socket */
    close(sockfd);

    return 0;
}