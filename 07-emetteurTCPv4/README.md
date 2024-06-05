# Algorithmes des réseaux

## Expéditeur TCP IPv4

Complétez le programme `sender-tcp.c` pour envoyer le message `hello world` avec les protocoles `IPv4` et `TCP`.

Le programme admet en argument l'adresse IP et le numéro de port de l'hôte distant à contacter :

    ./sender-tcp ip_addr port_number

Les seuls numéros de port valides sont ceux contenus dans l'intervalle [10000; 65000].

**Objectifs :** savoir créer un socket et transmettre un message texte en TCP.

## Marche à suivre

Vous devez dans un premier temps créer un socket `IPv4` et `TCP` via la primitive :

    int socket (int domain, int type, int protocol)

Ensuite, vous pouvez récupérer votre code de l'exercice 2 pour renseigner l'adresse `IPv4` et le port du destinataire à l'aide de la fonction `getaddrinfo()`. Le destinataire sera joignable sur l'adresse et le port passés en argument du programme. N'oubliez pas de mettre à jour le type de socket dans la structure `hints`.

Vous devez maintenant vous connecter au serveur pour initier la transaction TCP (3-ways handshake) via la fonction :

    int connect (int socket, const struct sockaddr *address, socklen_t address_len)
    
Enfin, l'envoi du message se fait via la primitive :

    ssize_t send (int socket, const void *buffer, size_t length, int flags)

Sans option (`flags = 0`), cette primitive est équivalente à :

    ssize_t write (int fildes, const void *buf, size_t nbyte)

que vous pouvez utiliser si vous êtes nostalgique de l'UE programmation système.

Vous pouvez tester votre programme en exécutant la commande `nc` (netcat) dans un autre terminal afin d'écouter en TCP sur l'une des adresses IP de votre poste et le port de votre choix :

    nc -4l ip_addr port_number

Vous pouvez ensuite lancer votre programme dans un autre terminal avec la même adresse IP et le même port en argument et vérifier que le message transmis est bien affiché par `netcat` sur la sortie standard.

## Validation

Votre programme doit obligatoirement passer tous les tests sur gitlab (il suffit de `commit/push` le fichier source pour déclencher le pipeline de compilation et de tests) avant de passer à l'exercice suivant.
