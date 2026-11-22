# HaitiBoutik

Marketplace haïtien de produits numériques en construction.

## Modèle confirmé
- Interface en français ; marché prioritaire : Haïti ; devise d'affichage : GDS.
- Les acheteurs achètent des PDF, e-books, modèles et autres fichiers numériques.
- Les vendeurs paient un abonnement de **500 GDS par mois** pour publier et vendre.
- HaitiBoutik prélève 20 % sur chaque vente payée ; le vendeur reçoit 80 % avant les éventuels frais de paiement.
- Après confirmation du paiement, l'acheteur obtient un accès sécurisé au téléchargement.
- Aucun stock physique, fournisseur, coursier ou livraison physique.

## État actuel — important
Le dépôt provient d'un ancien prototype de boutiques de produits physiques avec fournisseurs. Le nouveau périmètre est documenté dans [docs/MARKETPLACE-DIGITAL.md](docs/MARKETPLACE-DIGITAL.md) et le plan de migration est dans [docs/PLAN-IMPLEMENTATION.md](docs/PLAN-IMPLEMENTATION.md).

**Le marketplace numérique n'est pas encore opérationnel.** Les pages, le schéma de données, les politiques RLS, le stockage privé des fichiers, les paiements, les abonnements et les reversements doivent encore être adaptés et testés. Ne prenez pas de vrais paiements et ne promettez pas de téléchargements automatiques tant que ces éléments ne sont pas validés.

## Paramètres à décider
- Prix de l'abonnement mensuel vendeur.
- Prestataire de paiement et validation réelle des transactions.
- Méthode/fréquence des reversements vendeurs.
- Règles de remboursement, litiges et modération.

## Sécurité
- Ne jamais exposer de clé secrète, PIN, OTP ou mot de passe dans le dépôt ou le navigateur.
- Les fichiers numériques doivent rester dans un stockage privé et être servis via des liens temporaires après contrôle du droit d'accès.
- La confirmation de paiement doit être vérifiée côté serveur ou par une validation administrative contrôlée.
- Le rôle administrateur ne doit jamais être attribué via l'inscription publique.
- Les contrats de paiement peuvent nécessiter un adulte responsable selon les règles du prestataire.

## Projet
- Dépôt : https://github.com/Roodney1/HaitiBoutik
- Branche de travail : `single-store-whatsapp-orders`
