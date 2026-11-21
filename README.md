# HaitiBoutik

Plateforme en construction pour permettre aux commerçants en Haïti de créer et gérer leur boutique en ligne.

## Décisions produit
- Interface en français ; marché haïtien ; prix en GDS.
- Frais d'activation : 750 GDS, une seule fois par boutique.
- Paiements prévus : MonCash et NatCash.
- Livraison : coursier partenaire HaitiBoutik ou coursier choisi par le marchand.
- Le marchand prend en charge les frais de livraison.

## Fichiers
- `index.html` : tableau de bord marchand (prototype visuel).
- `boutique.html` : catalogue de démonstration avec 30 fiches produits, photos, recherche, filtres, tri et panier local.
- `connexion.html` : maquette de connexion (aucune authentification active).
- `admin.html` : aperçu du centre d'administration (maquette non sécurisée).
- `livraison.html` : aperçu des deux modes de livraison et des règles de suivi.
- `manifest.webmanifest`, `sw.js`, `assets/icon.svg` : installation comme application web et cache hors ligne de base.
- `supabase/schema.sql` : première structure SQL et politiques RLS.
- `docs/PLAN-IMPLEMENTATION.md` : architecture et étapes.
- `docs/INTEGRATIONS-A-FAIRE.md` : prérequis MonCash, NatCash et livraison.

## Important — état réel
Ce dépôt est un prototype de développement, pas une plateforme de commerce prête pour la production. Les produits, commandes et historiques de démonstration ne sont pas des données réelles. Les indicateurs du tableau de bord sont remis à zéro. Les formulaires ne créent pas de comptes, le panier ne passe pas de commande et aucun paiement MonCash/NatCash n'est connecté. Les règles SQL ne remplacent pas encore des fonctions serveur sécurisées pour la création des commandes et la validation des paiements. Le mode hors ligne ne synchronise pas les données : il met seulement en cache les pages statiques.

Ne publiez pas de clés secrètes, PIN, OTP ou mots de passe dans le dépôt. Les intégrations de paiement nécessitent des accès marchands et une validation officielle.

## Catalogue de produits (démo)
La vitrine contient 30 fiches de produits électroniques et accessoires. Les prix en GDS sont indicatifs : certains sont relevés sur des annonces publiques haïtiennes, d'autres sont des estimations à confirmer auprès du fournisseur. Les photos sont chargées depuis des pages publiques ORA Haiti, BiZZY et Nuvoteq ; elles ne sont pas hébergées dans ce dépôt et leur utilisation commerciale doit être autorisée par les ayants droit ou remplacée par des photos fournies par les marchands. Le panier reste une démonstration locale : il ne crée aucune commande et ne déclenche aucun paiement.
