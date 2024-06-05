# Algorithmes des réseaux

## Expéditeur UDP IPv4

Complétez le programme `sender-udp.c` pour envoyer le message texte `hello world` avec les protocoles `IPv4` et `UDP`.

Le programme admet en argument le numéro de port de l'hôte distant à contacter :

    ./sender-udp port_number

Les seuls numéros de port valides sont ceux contenus dans l'intervalle `[10000; 65000]`.

**Objectifs :** savoir créer un socket et transmettre un message texte en UDP.

## Marche à suivre

Vous devez dans un premier temps créer un socket `IPv4` et `UDP` via la primitive :

    int socket (int domain, int type, int protocol)

Ensuite, vous devez renseigner l'adresse `IPv4` et le port du destinataire dans une variable de type `struct sockaddr_in` définie dans `<netinet/in.h>` :

    struct sockaddr_in {
        short            sin_family;  // famille
        unsigned short   sin_port;    // port au format réseau
        struct in_addr   sin_addr;    // cf. struct in_addr ci-dessous
        char             sin_zero[8];
    };

    struct in_addr {
        unsigned long s_addr;  // adresse IPv4 au format réseau 
    };

Néanmoins, afin d'écrire des programmes les plus indépendants possibles des familles des sockets, il faut utiliser une variable de type `struct sockaddr_storage` et ensuite caster cette dernière suivant la famille traitée :

    struct sockaddr_storage ss;
    struct sockaddr_in *in = (struct sockaddr_in *) &ss;

L'adresse IPv4 du destinataire est déjà renseignée au bon format par la constante `IP` dans les sources du programme et peut être simplement affectée au champ correspondant dans la structure d'adresse.

Vous devez convertir le numéro de port passé en argument du programme en entier puis utiliser la macro `PORT()` disponible dans les sources du programme lors de son utilisation pour compléter une structure d'adresse. Vous pouvez laisser le système d'exploitation choisir l'adresse `IPv4` et le port utilisés localement par votre programme pour émettre le message.

Enfin, l'envoi du message se fait via la primitive :

    ssize_t sendto (int socket, const void *buffer, size_t length, int flags, const struct sockaddr *dest_addr, socklen_t dest_len)

Vous pouvez tester votre programme en exécutant la commande `nc` (netcat) dans un autre terminal afin d'écouter en `UDP` sur l'adresse `127.0.0.1` et le port de votre choix :

    nc -4ul 127.0.0.1 port_number

Vous pouvez ensuite lancer votre programme dans un autre terminal et vérifier que le message transmis est bien affiché par `netcat` sur la sortie standard.

## Validation

Votre programme doit obligatoirement passer tous les tests sur gitlab (il suffit de `commit/push` le fichier source pour déclencher le pipeline de compilation et de tests) avant de passer à l'exercice suivant.
