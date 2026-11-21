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
- `boutique.html` : vitrine publique d'exemple avec panier local.
- `connexion.html` : maquette de connexion (aucune authentification active).
- `supabase/schema.sql` : première structure SQL et politiques RLS.
- `docs/PLAN-IMPLEMENTATION.md` : architecture et étapes.
- `docs/INTEGRATIONS-A-FAIRE.md` : prérequis MonCash, NatCash et livraison.

## Important — état réel
Ce dépôt est un prototype de développement, pas une plateforme de commerce prête pour la production. Les produits de démonstration ne sont pas des offres réelles. Les formulaires ne créent pas de comptes, le panier ne passe pas de commande et aucun paiement MonCash/NatCash n'est connecté. Les règles SQL ne remplacent pas encore des fonctions serveur sécurisées pour la création des commandes et la validation des paiements.

Ne publiez pas de clés secrètes, PIN, OTP ou mots de passe dans le dépôt. Les intégrations de paiement nécessitent des accès marchands et une validation officielle.