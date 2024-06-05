# Algorithmes des réseaux

## Transfert de fichier TCP - expéditeur

Complétez le programme `sender-tcp.c` pour transmettre le contenu d'un fichier avec les protocoles IPv6 et TCP.

Le programme `sender-tcp` admet en argument l'adresse IP et le numéro de port de l'hôte distant à contacter ainsi que le nom du fichier à transmettre :

    ./sender-udp ip_addr port_number filename

Ce programme devra copier les données lues depuis le fichier passé en argument le socket à destination de l'hôte distant.

Les seuls numéros de port valides sont ceux contenus dans l'intervalle `[10000; 65000]`.

**Objectifs :** savoir transmettre un fichier avec le protocole TCP.

## Marche à suivre

Vous pouvez reprendre une grande partie du code produit pour l'exercice 7. Vous devez simplement mettre à jour les parties spécifiques à IPv4. Le programme `sender-tcp` devra transmettre les données du fichier vers l'adresse IP et le port passé en argument du programme.

La copie (depuis le fichier source vers le socket) devra être réalisée par la fonction à compléter :

    void cpy (int in, int out)

où `in` et `out` sont respectivement les descripteurs sur lesquels lire et écrire. Vous devez obligatoirement réaliser une lecture du fichier par blocs.

Pour tester votre programme, vous pouvez lancez dans un terminal la commande suivante :

    nc -6l IP PORT > copy.tmp

où `ÌP` et `PORT` sont respectivement l'adresse IP et le numéro de port qui seront passés à votre programme. L'adresse IP doit évidemment être une adresse IPv6 disponible sur votre poste. Exécutez ensuite votre programme et vérifiez que le fichier source et sa copie `copy.tmp` sont identiques via le commande suivante :

    cmp filename copy.tmp

On vous conseille de tester votre programme sur de gros fichiers binaires.

# Validation

Votre programme doit obligatoirement passer tous les tests sur gitlab (il suffit de `commit/push` le fichier source pour déclencher le pipeline de compilation et de tests) avant de passer à l'exercice suivant.
