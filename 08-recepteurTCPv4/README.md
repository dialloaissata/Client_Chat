# Algorithmes des réseaux

## Récepteur TCP IPv4

Complétez le programme `receiver-tcp.c` pour recevoir un message texte avec les protocoles `IPv4` et `TCP` et l'afficher sur la sortie standard. Vous devrez également afficher l'adresse IP et le port du client dès sa connexion à votre programme.

Le programme admet en argument l'adresse IP et le numéro de port sur lequel le programme doit écouter :

    ./receiver-tcp ip_addr port_number

Les seuls numéros de port valides sont ceux contenus dans l'intervalle `[10000; 65000]`.

La sortie de votre programme doit être de la forme suivante :

    ./receiver-tcp 192.168.1.233 12345
    192.168.1.1 54678
    hello world

Une telle sortie indique que le client ayant pour adresse `192.168.1.1` et le port `54678` s'est connecté à votre programme et a transmis le message `hello world`.

Votre programme devra être en mesure de recevoir jusqu'à SIZE octets.

**Objectifs :** savoir créer un socket, se mettre en attente d'une connexion TCP entrante, et réceptionner un message texte en TCP.

## Marche à suivre

Vous devez dans un premier temps créer un socket `IPv4` et `TCP` via la primitive :

    int socket (int domain, int type, int protocol)

Le protocole `TCP` met un temps non négligeable pour fermer un socket afin d'être sûr que tous les segments appartenant à la connexion qui vient de se terminer ne puissent pas être acceptés à tort par une nouvelle connexion avec le même quadruplet (adresse source, port source, adresse destination, port destination). Cela permet également de s'assurer que l'hôte distant a bien terminé la connexion. Cependant, ce mécanisme ralentit significativement les tests qui utilisent le même quadruplet à plusieurs reprises. Pour éviter cette attente, vous devez ajouter le code suivant après avoir créé le socket (en supposant que le descripteur correspondant est contenu dans la variable `sockfd`):

    /* SO_REUSEADDR option allows re-starting the program without delay */
    int iSetOption = 1;
    CHECK (setsockopt (sockfd, SOL_SOCKET, SO_REUSEADDR, &iSetOption, sizeof iSetOption));

Ensuite, vous pouvez récupérer votre code de l'exercice 4 pour renseigner l'adresse IP et le port passés en argument du programme à l'aide de la fonction `getaddrinfo()` et lier le socket avec `bind()`. N'oubliez pas de mettre à jour le type de socket dans la structure `hints`.

Il faut maintenant configurer la taille de la file d'attente pour les connexions entrantes via la primitive :

    int listen (int socket, int backlog)

Ensuite il faut attendre les demandes de connexion (réception de messages `SYN`) via la primitive :

    int accept (int socket, struct sockaddr *restrict address, socklen_t *restrict address_len)

Vous pouvez récupérer des informations sur le client qui vient de se connecter via les deux derniers paramètres de la primitive `accept()` qui permettent de compléter une variable de type `struct sockaddr_storage` castée en une structure `struct sockaddr`.

Ensuite, vous pouvez transformer les informations contenues dans cette structure (adresse IP et port) en des chaînes de caractères via la fonction `getnameinfo()` comme réalisé dans l'exercie 4.

Enfin, la réception d'un message sur le nouveau socket retourné par `accept()` se fait via la primitive :

    ssize_t recv (int socket, void *buffer, size_t length, int flags)

Sans option (`flags = 0`) cette primitive est équivalente à :

    ssize_t read (int desc, void *buf, size_t nbyte)

que vous pouvez utiliser si vous êtes nostalgique de l'UE programmation système.

Vous pouvez tester votre programme avec le programme réalisé dans l'exercice précédent ou en exécutant la commande `nc` (netcat) dans un autre terminal. Lancez votre programme dans un terminal puis exécutez la commande suivante dans un second terminal afin d'envoyer le message `hello world` en `TCP` sur l'adresse IP et le port utilisé par votre programme, et en utilisant le port local de votre choix :

    echo "hello world" | nc -4 -w1 ip_du_prog port_du_prog -p port_local_pour_netcat

Vérifiez ensuite que l'adresse et le port de l'expéditeur ainsi que le message sont correctement affichés par votre programme sur la sortie standard.

## Validation

Votre programme doit obligatoirement passer tous les tests sur gitlab (il suffit de `commit/push` le fichier source pour déclencher le pipeline de compilation et de tests) avant de passer à l'exercice suivant.
