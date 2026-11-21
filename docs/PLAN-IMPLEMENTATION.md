# HaitiBoutik — plan de construction

## Décisions confirmées
- Marché : Haïti ; interface : français ; monnaie : gourde haïtienne (GDS).
- Activation d'une boutique : 750 GDS, paiement unique.
- Paiements visés : MonCash et NatCash.
- Livraison : deux modes, coursier partenaire HaitiBoutik ou coursier du marchand.
- Le marchand prend en charge les frais de livraison.
- Chaque marchand doit gérer sa propre boutique.

## État actuel
Le dépôt contient une interface frontend responsive, un catalogue de démonstration de 30 produits et une première structure SQL. Le tableau de bord permet maintenant de gérer localement des produits (ajout, modification, suppression, prix, stock, photo et description). Ces données restent dans le navigateur utilisé et ne sont pas synchronisées. Ce n'est pas encore une plateforme prête à recevoir de vrais clients.

## Architecture proposée
- Frontend : pages web responsives, compatibles avec navigateur Android et Acode.
- Backend : Supabase Auth + PostgreSQL + politiques RLS, à configurer dans un projet appartenant au propriétaire.
- Paiements : intégration serveur officielle après obtention d'un compte marchand et des accès API.
- Livraison : affectation manuelle au départ, puis portail coursier et suivi après accords avec des partenaires.
- Hébergement : HTTPS obligatoire, variables secrètes conservées côté serveur.

## Modèle de données
Voir `supabase/schema.sql` : profils, boutiques, produits, commandes, lignes de commande, livraisons et paiements.

## Étapes restantes avant un lancement réel
1. Tester l'interface actuelle sur téléphone : navigation, formulaire produit, modification, suppression et affichage mobile.
2. Créer un projet Supabase et appliquer `supabase/schema.sql`.
3. Exécuter `supabase/migrations/20261121_profile_security.sql` dans le SQL Editor.
4. Construire et tester inscription/connexion, récupération de mot de passe et profils.
5. Construire la création de boutique, son slug public et le verrouillage tant que l'activation n'est pas vérifiée.
6. Connecter les produits au backend avec stockage d'images et permissions par boutique.
7. Construire le catalogue public, le panier et une création de commande sécurisée côté serveur.
8. Construire le tableau de bord marchand et les outils d'administration protégés.
9. Définir les zones, tarifs, contrats et partenaires de livraison, puis construire l'affectation des courses.
10. Ajouter MonCash/NatCash avec documentation officielle, accès marchand, webhooks et validation serveur.
11. Tester les autorisations, les paiements, les sauvegardes, la protection des données et le déploiement.

## Sécurité
- Ne jamais activer une boutique parce qu'un client a cliqué « payé » ou envoyé une capture d'écran.
- La confirmation de paiement doit venir d'une vérification serveur ou d'une validation administrative fiable.
- Ne jamais placer une clé secrète, un PIN, un OTP ou un mot de passe dans GitHub ou dans le JavaScript public.
- Les rôles administrateur doivent être attribués uniquement par un processus de confiance, jamais par auto-inscription.
