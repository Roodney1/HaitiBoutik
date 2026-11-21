# HaitiBoutik

Plateforme en construction pour permettre aux commerçants en Haïti de créer et gérer leur boutique en ligne.

## Décisions produit
- Interface en français ; marché haïtien ; prix en GDS.
- Frais d'activation : 750 GDS, une seule fois par boutique.
- Paiements prévus : MonCash et NatCash.
- Livraison : coursier partenaire HaitiBoutik ou coursier choisi par le marchand.
- Le marchand prend en charge les frais de livraison.

## Fichiers
- `index.html` : page d’accueil en français qui présente HaitiBoutik et guide les visiteurs vers la création de leur boutique.
- `creer-boutique.html` : assistant de création en trois étapes ; enregistre la boutique dans Supabase après connexion.
- `ma-boutique.html` : aperçu local de la vitrine personnalisée.
- `espace-marchand.html` : tableau de bord marchand connecté à Supabase pour charger et gérer les produits de sa boutique.
- `boutique.html` : catalogue de démonstration avec 30 fiches produits, photos, recherche, filtres, tri et panier local.
- `connexion.html` : inscription et connexion des marchands avec Supabase Auth.
- `admin.html` : aperçu du centre d'administration (maquette non sécurisée).
- `livraison.html` : aperçu des règles de livraison.
- `fournisseurs.html` : présentation du portail fournisseur et de l’expédition directe au client.
- `supabase/migrations/` : migrations déployées pour le schéma, le portail fournisseur, les règles RLS et les droits de modification des boutiques.
- `manifest.webmanifest`, `sw.js`, `assets/icon.svg` : installation comme application web et cache hors ligne de base.
- `supabase/schema.sql` : structure initiale SQL et politiques RLS.
- `supabase-client.js` : client navigateur Supabase configuré avec l'URL du projet et une clé publishable uniquement (aucune clé secrète).
- `supabase/migrations/` : migrations versionnées correspondant au schéma initial, aux fournisseurs, à la sécurité des profils, aux champs de boutique et à l’optimisation des politiques RLS.
- `supabase/migrations/20261121_profile_security.sql` : création automatique du profil après inscription Supabase et protection contre l'auto-attribution du rôle administrateur.
- `docs/PLAN-IMPLEMENTATION.md` : architecture et étapes.
- `docs/INTEGRATIONS-A-FAIRE.md` : prérequis MonCash, NatCash et livraison.

## Important — état réel
Le projet Supabase HaitiBoutik est créé et actif. Les tables principales, les politiques RLS, les profils automatiques et les migrations fournisseurs sont installés. L'inscription/connexion marchands, la création réelle de boutique, la gestion des produits, le portail d'inscription fournisseur, le catalogue fournisseur et un parcours de commande sécurisé via la fonction Edge `create-customer-order` (avec limitation de fréquence) pour les boutiques actives sont reliés à Supabase. Le passage de commande exige qu'un produit publié soit associé à un produit de catalogue appartenant à un fournisseur approuvé et disposant du stock requis. Le dépôt reste en développement et n'est pas prêt pour le commerce en production : les paiements, l'activation automatisée à 750 GDS, la validation administrative des fournisseurs, les notifications et les preuves de livraison ne sont pas encore opérationnels. La progression de livraison du fournisseur met à jour le statut de la commande et de la livraison, mais doit encore être testée avec de vrais partenaires. Les fournisseurs doivent être recrutés et vérifiés avant toute promesse de livraison. Les images du catalogue de démonstration doivent aussi être vérifiées pour leurs droits d'utilisation. Avant les premiers tests d'inscription, configurez dans Supabase > Authentication > URL Configuration l'URL du site `https://roodney1.github.io/HaitiBoutik/` et autorisez la redirection `https://roodney1.github.io/HaitiBoutik/connexion.html`. Le mode hors ligne ne synchronise pas les données : il met seulement en cache les pages statiques.

Ne publiez pas de clés secrètes, PIN, OTP ou mots de passe dans le dépôt. Les intégrations de paiement nécessitent des accès marchands et une validation officielle.

## Catalogue de produits (démo)
La vitrine contient 30 fiches de produits électroniques et accessoires. Les prix en GDS sont indicatifs : certains sont relevés sur des annonces publiques haïtiennes, d'autres sont des estimations à confirmer auprès du fournisseur. Les photos sont chargées depuis des pages publiques ORA Haiti, BiZZY et Nuvoteq ; elles ne sont pas hébergées dans ce dépôt et leur utilisation commerciale doit être autorisée par les ayants droit ou remplacée par des photos fournies par les marchands. Le panier reste une démonstration locale : il ne crée aucune commande et ne déclenche aucun paiement.
