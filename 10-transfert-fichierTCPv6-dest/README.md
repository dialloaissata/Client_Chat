# Algorithmes des réseaux

## Transfert de fichier TCP - destinataire

Complétez le programme `receiver-tcp.c` pour recevoir le contenu d'un fichier avec les protocoles IPv6 et TCP.

Le programme `receiver-tcp` admet en argument l'adresse IP et le numéro de port sur lequel le programme doit écouter :

    ./receiver-tcp ip_addr port_number

Ce programme devra copier les données reçues sur le socket dans le fichier `copy.tmp` qui devra être créé dans le répertoire courant.

Les seuls numéros de port valides sont ceux contenus dans l'intervalle `[10000; 65000]`.

**Objectifs :** savoir transmettre un fichier avec le protocole TCP.

## Marche à suivre

Vous pouvez reprendre une grande partie du code produit pour l'exercice 8. Vous devez simplement mettre à jour les parties spécifiques à IPv4. Le programme `receiver-tcp` devra écouter sur l'adresse IPv6 et le port passé en argument du programme.

La copie (depuis le socket vers le fichier `copy.tmp`) devra être réalisée par la fonction à compléter :

    void cpy (int in, int out)

où `in` et `out` sont respectivement les descripteurs sur lesquels lire et écrire. Vous veillerez à lire sur le socket par blocs d'octets pour limiter le nombre d'appels système.

N'oubliez pas d'ajouter le code suivant après la création du socket `sockfd` pour les raisons évoquées dans l'exercice 8 :

    /* SO_REUSEADDR option allows re-starting the program without delay */
    int iSetOption = 1;
    CHECK (setsockopt (sockfd, SOL_SOCKET, SO_REUSEADDR, &iSetOption, sizeof iSetOption));

Testez votre programme à l'aide du programme réalisé dans l'exercice précédent, ou via la commande :

    nc -6 adresse_ip_de_votre_programme  port_de_votre_programme < fichier_a_transmettre

Vérifier que le fichier source et sa copie `copy.tmp` sont identiques via la commande `cmp` :

    cmp fichier_a_transmettre copy.tmp

# Validation

Votre programme doit obligatoirement passer tous les tests sur gitlab (il suffit de `commit/push` le fichier source pour déclencher le pipeline de compilation et de tests) avant de passer à l'exercice suivant.
