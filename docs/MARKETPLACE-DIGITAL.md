# HaitiBoutik — marketplace de produits numériques

## Décisions confirmées
- Produit : marketplace multi-vendeurs de produits numériques uniquement.
- Langue : français ; marché prioritaire : Haïti ; devise d'affichage : GDS.
- Un vendeur paie un abonnement de **500 GDS par mois** pour publier et vendre.
- Commission de la plateforme : 20 % de chaque vente payée.
- Part vendeur : 80 % du montant de vente, avant les éventuels frais du prestataire de paiement.
- Les acheteurs paient sur le site et téléchargent leurs fichiers après confirmation du paiement.
- Aucun fournisseur physique, coursier, livraison ou commande WhatsApp dans ce modèle.

## Paramètres encore à décider
- Prix exact de l'abonnement mensuel (en GDS).
- Prestataire(s) de paiement et méthode réelle de confirmation des transactions.
- Fréquence et méthode des reversements aux vendeurs (MonCash, NatCash ou autre).
- Règles de remboursement, litiges et délais de conservation des fichiers.

## Parcours acheteur
1. Parcourir les produits numériques et leurs fiches.
2. Créer un compte ou se connecter.
3. Ajouter un ou plusieurs produits au panier et payer.
4. Le serveur vérifie la transaction auprès du prestataire ou après validation administrative.
5. Une commande payée crée un droit d'accès au téléchargement.
6. Le client retrouve ses achats dans « Mes téléchargements ».

Ne jamais accorder l'accès à un fichier sur la seule base d'un paramètre URL, d'une capture d'écran ou d'une déclaration du navigateur.

## Parcours vendeur
1. Créer un compte acheteur puis demander l'accès vendeur.
2. Accepter les conditions vendeur et payer l'abonnement mensuel.
3. Après confirmation, le compte vendeur devient actif jusqu'à la date d'expiration.
4. Ajouter un produit : titre, description, catégorie, prix GDS, image de couverture et fichier numérique.
5. Soumettre le produit à modération ou le publier selon les règles de la plateforme.
6. Suivre commandes, chiffre d'affaires, commission de 20 %, part nette de 80 % et reversements.

Un abonnement expiré bloque les nouvelles publications/ventes, mais ne doit pas supprimer les produits, commandes ou droits de téléchargement déjà acquis par les acheteurs.

## Parcours administrateur
- Gérer utilisateurs, demandes vendeurs, abonnements et statuts.
- Modérer, masquer ou retirer des produits.
- Consulter commandes, paiements, remboursements et commissions.
- Examiner les soldes vendeurs et enregistrer les reversements.
- Consulter un journal d'audit des actions sensibles.

## Modèle de données cible
- `profiles` : identité et rôle attribué par un processus de confiance.
- `seller_accounts` : état du compte vendeur.
- `seller_subscriptions` : période d'abonnement, statut, montant, référence et confirmation.
- `digital_products` : vendeur propriétaire, métadonnées, prix, statut de publication et chemin du fichier privé.
- `digital_orders` et `digital_order_items` : commandes et prix figés au moment de l'achat.
- `payment_records` : paiements acheteur et abonnements.
- `download_entitlements` : droit de téléchargement créé uniquement après paiement confirmé.
- `seller_ledger` : écritures immuables de vente, commission de plateforme, remboursement et reversement.
- `seller_payouts` : demandes et suivi des reversements.

Les montants doivent être calculés côté serveur à partir des prix enregistrés en base, jamais à partir des totaux envoyés par le navigateur. La commission est calculée en centimes de GDS avec une règle d'arrondi définie et testée.

## Sécurité indispensable
- Les fichiers vendus doivent être dans un bucket Supabase Storage privé.
- Le navigateur ne reçoit qu'un lien signé de courte durée après vérification d'un droit de téléchargement valide.
- RLS activé sur toutes les tables exposées ; chaque vendeur ne voit que ses propres produits, ventes et relevés.
- Le rôle administrateur ne peut jamais être choisi depuis le formulaire d'inscription ni depuis les métadonnées modifiables par l'utilisateur.
- Les clés secrètes et secrets des prestataires restent côté serveur.
- Vérifier les webhooks, empêcher le traitement multiple d'un même paiement et journaliser les opérations financières.
- Prévoir limites de taille/type de fichiers, antivirus ou contrôle de fichiers, modération et signalement des contenus illicites.
- Afficher clairement les conditions, remboursements, droits d'auteur et règles de contenu.

## État d'implémentation
Ce document fixe le nouveau périmètre fonctionnel. Le dépôt contient encore l'ancien parcours de boutiques physiques et fournisseurs ; il ne faut pas le présenter comme un marketplace numérique opérationnel tant que les pages, schéma, politiques RLS, stockage privé et paiements n'ont pas été adaptés et testés.

## Lancement et paiements
MonCash/NatCash ne sont pas encore intégrés à ce parcours. L'activation des abonnements et la livraison des fichiers doivent rester en mode test ou validation administrative tant qu'un compte marchand, une intégration officielle et des webhooks vérifiés ne sont pas configurés. Les contrats de paiement et reversement peuvent exiger un adulte responsable et des justificatifs selon les règles du prestataire.
