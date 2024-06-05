# Algorithmes des réseaux

## Affichage d'adresse IP et port

Dans l'exercice précédent, les informations de l'expéditeur (adresse IP et port) n'étaient pas enregistrées lors de l'appel à `recvfrom()`. Dans cet exercice, vous allez récupérer ces informations et les afficher sous la forme de chaînes de caractères.

Le programme admet en argument l'adresse IP et le numéro de port sur lequel le programme doit écouter :

    ./receiver-udp ip_addr port

Les seuls numéros de port valides sont ceux contenus dans l'intervalle `[10000; 65000]`.

La sortie de votre programme doit être de la forme suivante :

    ./receiver-udp 192.168.1.233 10001
    hello world
    192.168.1.1 57123

Une telle sortie indique que votre programme a reçu le message `hello world` d'une source dont l'adresse IP est `192.168.1.1` et le port est `57123`.

On fera l'hypothèse que le message aura une taille maximum de `SIZE` caractères.

**Objectifs :** savoir récupérer les informations d'un expéditeur et les afficher.

## Marche à suivre

Reprennez le code source de l'exercice précédent et mettez à jour la gestion des arguments.

Vous pouvez récupérer des informations sur l'expéditeur via les deux derniers paramètres de la primitive `recvfrom()` qui permettent de compléter une variable de type `struct sockaddr_storage` castée en un pointeur vers une structure `struct sockaddr`.

Ensuite, vous pouvez transformer les informations contenues dans cette structure (adresse IP et port) en des chaînes de caractères via la fonction :

     int getnameinfo (const struct sockaddr *sa, socklen_t salen, char *host, socklen_t hostlen, char *serv, socklen_t servlen, int flags)

Consultez le manuel utilisateur pour connaître les options possibles et comment traiter les erreurs associées à la fonction `getnameinfo()`.

Vous pouvez tester votre programme avec le programme réalisé dans l'exercice 2 ou en exécutant la commande `nc` (netcat) dans un autre terminal. Lancez votre programme dans un terminal puis exécutez la commande suivante dans un second terminal afin d'envoyer le message `hello world` en UDP sur l'adresse (par exemple `127.0.0.1`) et le port utilisé par votre programme, et le port de votre choix en tant que port local :

    echo "hello world" | nc -4u -w1 addr_du_prog port_du_prog -p port_local_pour_netcat

Vérifiez ensuite que l'adresse IP et le port affichés par votre programme sont conformes à ceux utilisés par l'expéditeur.

## Validation

Votre programme doit obligatoirement passer tous les tests sur gitlab (il suffit de `commit/push` le fichier source pour déclencher le pipeline de compilation et de tests) avant de passer à l'exercice suivant.
