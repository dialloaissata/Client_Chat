# Algorithmes des réseaux

Ce dépôt contient une liste d'exercices pratiques pour apprendre à utiliser l'API socket du langage C. Les exercices sont progressifs et doivent être réalisés dans l'ordre.

## Compilation

Un squelette de programme C est fourni pour chaque exercice. Pour le compiler, vous pouvez simplement utiliser l'outil `SCons` qui est un équivalent de `make` :

    scons

Pour nettoyer le répertoire courant, il suffit de passer l'option `-c` :

    scons -c

## Tests locaux natifs

Un script de tests en `bash` est fourni pour chaque exercice. Après avoir compilé votre programme, vous pouvez le tester via le script :

    bash tests.sh

Suivant les exerices, plusieurs tests sont réalisés et un `OK` indique que le test est réussi. Sinon, un court message vous indique la raison de l'échec, vous permettant de corriger les erreurs dans votre programme.

Les scripts de tests sont fournis sans garantie de compatibilité avec votre système. 

## Tests locaux sur docker

Vous pouvez tester vos programmes dans une image docker (nécessite d'avoir `docker` installé sur votre système).

L'image `docker` configurée pour les exercices peut être récupérée localement et instanciée dans un conteneur via les commandes :

    docker pull montavont/algodesreseaux:2.0
    cd chemin/vers/la/copie/locale/du/dépôt/git
    docker run --rm -it -v $PWD:/home/alice montavont/algodesreseaux

Pour l'exercice 10, vous aurez besoin d'une connectivité IPv6 globale. Pour activer le support d'IPv6 dans docker, il faut :

1. créer un fichier de configuration dans `/etc/docker/daemon.json` avec le contenu suivant : 

        {
            "ipv6": true,
            "fixed-cidr-v6": "2001:db8:dead:beef::/64",
            "experimental": true,
            "ip6tables": true
        }

2. relancer le service docker :

        sudo systemctl restart docker

3. lancer le conteneur :

        sudo docker run --rm -it -v $PWD:/home/alice montavont/algodesreseaux

## Tests sur gitlab

Les tests peuvent également être directement exécutés par gitlab dans un conteneur docker exécuté sur un runner de gitlab. Tout `commit/push` sur l'un des fichiers source provoque sa compilation et l'exécution du script de tests. Vous pouvez configurer le dépôt gitlab pour être notifié en cas de succès (ou d'échec) des tests.

Sur l'interface de gitlab, il suffit d'aller dans `build/pipeline` pour visualiser le résultat des tests.

## Primitives système

Vous trouverez ci-dessous la signature des primitives système / fonctions de bibliothèque nécessaires à la réalisation des exercices. N'hésitez pas à consulter le manuel utilisateur pour obtenir des explications détaillées.

Attente de connexions :

    int accept (int socket, struct sockaddr *restrict address, socklen_t *restrict address_len)

Affectation d'une adresse :

    int bind (int socket, const struct sockaddr *address, socklen_t address_len)

Fermeture d'un socket :

    int close (int socket)

Tentative de connexion :

    int connect (int socket, const struct sockaddr *address, socklen_t address_len)

Configuration de la file d'attente :

    int listen (int socket, int backlog)

Lecture sur un socket :

    ssize_t recv (int socket, void *buffer, size_t length, int flags)
    ssize_t recvfrom (int socket, void *restrict buffer, size_t length, int flags, struct sockaddr *restrict address, socklen_t *restrict address_len)

Écriture sur un socket :

    ssize_t send (int socket, const void *buffer, size_t length, int flags)
    ssize_t sendto (int socket, const void *buffer, size_t length, int flags, const struct sockaddr *dest_addr, socklen_t dest_len)

Création d'un socket :

    int socket (int domain, int type, int protocol)

## Fonctions de bibliothèque

Traduit une adresse IP en nom :

    int getnameinfo (const struct sockaddr *sa, socklen_t salen, char *host, socklen_t hostlen, char *serv, socklen_t servlen, int flags)

Traduit un nom en adresses IP :

     int getaddrinfo (const char *hostname, const char *servname, const struct addrinfo *hints, struct addrinfo **res)

Libère la mémoire de la liste de `struct addrinfo` allouée par `getaddrinfo` :

    void freeaddrinfo (struct addrinfo *ai)
