# Algorithmes des réseaux

## Expéditeur UDP IPv6

Complétez le programme `sender-udp.c` pour envoyer le message texte `hello world` avec les protocoles `IPv6` et `UDP`.

Le programme admet en argument l'adresse IP et le numéro de port de l'hôte distant à contacter :

    ./sender-udp ip_addr port_number

Les seuls numéros de port valides sont ceux contenus dans l'intervalle `[10000; 65000]`.

**Objectifs :** savoir créer un socket IPv6 et transmettre un message texte en UDP.

## Marche à suivre :

Vous pouvez directement reprendre le code réalisé dans l'exercice 2 et mettre à jour les parties spécifiques à `IPv4`. Ici l'hôte distant sera joignable sur l'adresse `::1` et le port passé en argument du programme.

Vous pouvez tester votre programme en exécutant la commande `nc` (netcat) dans un autre terminal afin d'écouter en UDP sur l'adresse `::1` et le port de votre choix :

    nc -6ul ::1 port_number

Vous pouvez ensuite lancer votre programme dans un autre terminal et vérifier que le message transmis est bien affiché par `netcat` sur la sortie standard.

## Validation

Votre programme doit obligatoirement passer tous les tests sur gitlab (il suffit de `commit/push` le fichier source pour déclencher le pipeline de compilation et de tests) avant de passer à l'exercice suivant.
