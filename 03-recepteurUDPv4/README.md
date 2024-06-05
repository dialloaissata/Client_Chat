# Algorithmes des réseaux

## Récepteur UDP IPv4

Complétez le programme `receiver-udp.c` pour recevoir un message texte avec les protocoles `IPv4` et `UDP` et l'afficher sur la sortie standard.

Le programme admet en argument le numéro de port sur lequel le programme doit écouter :

    ./receiver-udp port_number

Les seuls numéros de port valides sont ceux contenus dans l'intervalle `[10000; 65000]`.

On fera l'hypothèse que le message aura une taille maximum de `SIZE` caractères avec `SIZE < 100`.

**Objectifs :** savoir recevoir un message texte en UDP.

## Marche à suivre

Vous devez créer un socket `IPv4` et `UDP` puis renseigner un structure d'adresse avec l'adresse `127.0.0.1` et le port passé en argument du programme à l'aide de la fonction `getaddrinfo()` introduite dans l'exercice précédent.

Il faut ensuite associer le socket avec votre l'adresse et le port via la primitive :

    int bind (int socket, const struct sockaddr *address, socklen_t address_len)

L'idée ici consiste à directement utiliser les informations présentes dans la structure `struct addrinfo` retournée par `getaddrinfo()` pour les lier au socket.

Enfin, la réception d'un message se fait via la primitive :

    ssize_t recvfrom (int socket, void *restrict buffer, size_t length, int flags, struct sockaddr *restrict address,
                      socklen_t *restrict address_len)

Vous pouvez utiliser le pointeur `NULL` pour les deux derniers arguments de cette primitive.

Vous pouvez tester votre programme avec le programme réalisé dans l'exercice 2 ou en exécutant la commande `nc` (netcat) dans un autre terminal. Lancez votre programme dans un terminal puis exécutez la commande suivante dans un second terminal afin d'envoyer le message `hello world` en `UDP` sur l'adresse `127.0.0.1` et le port utilisé par votre programme :

    echo "hello world" | nc -4u -w1 127.0.0.1 port_number

Vérifiez ensuite que le message est correctement reçu et affiché par votre programme sur la sortie standard.

## Validation

Votre programme doit obligatoirement passer tous les tests sur gitlab (il suffit de `commit/push` le fichier source pour déclencher le pipeline de compilation et de tests) avant de passer à l'exercice suivant.
