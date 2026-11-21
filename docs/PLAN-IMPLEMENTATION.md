# HaitiBoutik — plan de construction

## Décisions confirmées
- Marché : Haïti ; interface : français ; monnaie : gourde haïtienne (GDS).
- Activation d'une boutique : 750 GDS, paiement unique.
- Paiements visés : MonCash et NatCash.
- Livraison : deux modes, coursier de la plateforme ou coursier du marchand.
- Le marchand prend en charge les frais de livraison.
- Le projet doit permettre à chaque marchand de gérer sa propre boutique.

## État actuel
Le dépôt contient une première interface de tableau de bord et une base SQL initiale. Ce n'est pas encore une plateforme prête à recevoir de vrais clients. Les données de démonstration et les actions locales ne remplacent pas un serveur.

## Architecture proposée
- Frontend : pages web responsives, compatibles avec un navigateur Android et Acode.
- Backend : Supabase (Auth + PostgreSQL + règles RLS), à configurer dans un projet appartenant au propriétaire.
- Paiements : intégration serveur officielle après obtention d'un accès marchand/API.
- Livraison : affectation manuelle au départ, puis application/portail coursier et suivi.
- Hébergement : choisir après tests, avec variables secrètes conservées côté serveur.

## Modèle de données
Voir `supabase/schema.sql` : profils, boutiques, produits, commandes, lignes de commande, livraisons et paiements.

## Ordre de réalisation
1. Tester l'interface actuelle sur téléphone.
2. Créer un projet Supabase et appliquer le schéma SQL.
3. Construire inscription/connexion et création de profil.
4. Construire création de boutique, slug public et verrouillage tant que l'activation n'est pas vérifiée.
5. Construire catalogue public, panier et création de commande.
6. Construire tableau de bord marchand : produits, stock, commandes.
7. Construire administration : validation des paiements, activation/suspension, gestion des boutiques.
8. Construire dispatch des livraisons et espace coursier.
9. Ajouter MonCash/NatCash avec documentation officielle, tests et validation serveur.
10. Tester sécurité, permissions, mobile, sauvegardes et déploiement.

## Règle de sécurité importante
Ne jamais activer une boutique parce qu'un client a simplement cliqué « payé » ou envoyé une capture d'écran. L'activation doit suivre une vérification serveur ou une validation administrative fiable.
