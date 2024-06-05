# Algorithmes des réseaux

## Configuration adresse et port

Dans le programme précédent, l'adresse IP et le port du destinataire étaient fixes et fournis au bon format directement dans le code source. Dans cet exercice, vous allez laissez le système compléter la structure `struct sockaddr_storage` à partir d'une adresse IP et d'un port sous la forme de chaînes de caractères.

L'objectif reste le même que pour l'exercice précédent : complétez le programme `sender-udp.c` pour envoyer le message texte `hello world` avec les protocoles `IPv4` et `UDP`.

On rappelle que les seuls numéros de port valides sont ceux contenus dans l'intervalle `[10000; 65000]`.

**Objectifs :** savoir renseigner une structure d'adresse à l'aide de la fonction `getaddrinfo()`

## Marche à suivre

Après avoir créer un socket (via la primitive `socket`), vous pouvez appeler la fonction :

    int getaddrinfo (const char *hostname, const char *servname, const struct addrinfo *hints, struct addrinfo **res)

sur l'adresse `127.0.0.1` et le port passé en argument du programme, tout deux exprimés sous la forme de chaînes de caractères, afin de récupérer une liste de structure `struct addrinfo` :

    struct addrinfo {
        int              ai_flags;     /* options supplémentaires        */
        int              ai_family;    /* famille                        */
        int              ai_socktype;  /* type                           */
        int              ai_protocol;  /* protocole                      */
        size_t           ai_addrlen;   /* longueur de struct sockaddr    */
        struct sockaddr *ai_addr;      /* adresse et port                */
        char            *ai_canonname; /* nom de l'hôte                  */
        struct addrinfo *ai_next;      /* pointeur sur l'élément suivant */
    };

Ce type est défini dans `<netdb.h>`.

En cas de succès, le pointeur `res` pointe sur une liste de `struct addrinfo` terminée par `NULL` car un hôte peut posséder plusieurs adresses IP ou avoir plusieurs services (port) actifs :

![list of struct addrinfo](addrinfo.svg)

À l'aide du paramètre `hints` vous pouvez filtrer les résultats obtenus dans la liste. Consultez le manuel utilisateur pour connaître les options possibles et comment traiter les erreurs associées à la fonction `getaddrinfo()`.

En cas de succès, vous pouvez directement utiliser les informations présentes dans la structure `struct addrinfo` lors de l'appel à la fonction `sendto()`.

La fonction `getaddrinfo()` alloue dynamiquement la mémoire nécessaire pour stocker la liste de structures `struct addrinfo`. Il faut donc libérer cette dernière lorsque la liste n'est plus utile via la fonction :

    void freeaddrinfo (struct addrinfo *ai)

Vous pouvez tester votre programme en exécutant la commande `nc` (netcat) dans un autre terminal afin d'écouter en `UDP` sur l'adresse `127.0.0.1` et le port de votre choix :

    nc -4ul 127.0.0.1 port_number

Vous pouvez ensuite lancer votre programme dans un autre terminal et vérifier que le message transmis est bien affiché par `netcat` sur la sortie standard.

## Validation

Votre programme doit obligatoirement passer tous les tests sur gitlab (il suffit de `commit/push` le fichier source pour déclencher le pipeline de compilation et de tests) avant de passer à l'exercice suivant.
