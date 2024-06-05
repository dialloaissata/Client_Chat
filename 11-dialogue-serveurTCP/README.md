# Algorithmes des réseaux

## Dialogue avec un serveur existant

Complétez le programme `client-http.c` pour dialoguer avec un serveur web et récupérer une page `html` via le protocole `TCP`.

Le programme `client-http` admet en argument le nom du serveur web à contacter (e.g. `google.com`) :

    ./client-http server_name

Votre programme doit être agnostique de la version du protocole IP utilisée par le serveur et devra permettre des connexions IPv4 ou IPv6.

**Objectifs :** développer un client web simple qui supporte la double pile IPv4/IPv6.

## Marche à suivre

Vous devez dans un premier temps récupérer l'adresse IP du serveur à partir du nom passé en argument du programme via la fonction `getaddrinfo()`. Pour le paramètre `servname` vous pouvez utiliser la chaîne de caractères `http`.

Ensuite, vous pouvez créer un socket de la bonne famille en fonction des informations retournées par `getaddrinfo()` et vous connecter au serveur via le protocole `TCP`.

Le protocole `http` est un protocole en mode texte, c'est-à-dire que les commandes à envoyer sont des chaînes de caractères. La commande `http` à transmettre au serveur sous la forme d'une chaîne de caractères est de la forme :

    GET / HTTP/1.1\r\nHost: server_name\r\nConnection:close\r\n\r\n

où `server_name` correspond au nom du serveur passé en argument du programme. Il faut donc construire la chaîne de caractères correspondant à la commande puis l'envoyer au serveur et récupérer sa réponse.
Vous afficherez sur la sortie standard la réponse du serveur.

Vous pouvez tester votre programme sur les serveurs suivants :

    mai-reseau-get.psi.ad.unistra.fr     // Dual stack IPv6 and IPv4 (preference depends on your OS/client) 
    mai-reseau-get-v4.psi.ad.unistra.fr  // IPv4 only
    mai-reseau-get-v6.psi.ad.unistra.fr  // IPv6 only

## Validation

Votre programme doit obligatoirement passer tous les tests sur gitlab (il suffit de `commit/push` le fichier source pour déclencher le pipeline de compilation et de tests) avant de passer à l'exercice suivant.
