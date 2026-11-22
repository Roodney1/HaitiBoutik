# HaitiBoutik — plan de construction

## Décisions confirmées
- Marché prioritaire : Haïti ; interface : français ; devise : GDS.
- Type de plateforme : marketplace multi-vendeurs de produits numériques uniquement.
- Les vendeurs paient un abonnement mensuel pour vendre.
- Commission HaitiBoutik : 20 % sur chaque vente payée ; part vendeur : 80 % avant frais éventuels du prestataire.
- Les acheteurs paient sur le site et téléchargent après confirmation du paiement.
- Pas de fournisseur physique, stock, coursier, livraison ou commande WhatsApp.

## Paramètres à confirmer
- Prix de l'abonnement mensuel.
- Prestataire(s) et mécanisme de paiement réel.
- Méthode et fréquence des reversements vendeurs.
- Conditions de remboursement, litige et modération.

## État actuel
Le dépôt contient encore l'ancien parcours de boutiques physiques, produits en stock et fournisseurs. Le catalogue de 30 produits est une démonstration d'articles physiques ; il ne constitue pas un catalogue de fichiers numériques. Le parcours vendeur, le schéma SQL, les commandes, les paiements et l'administration doivent être adaptés avant toute mise en production.

## Architecture cible
- Frontend : pages responsives en français, utilisables depuis Android.
- Backend : Supabase Auth, PostgreSQL, RLS, fonctions serveur et Supabase Storage privé.
- Produits : métadonnées publiques et fichiers numériques conservés dans un bucket privé.
- Téléchargement : droit d'accès créé uniquement après confirmation de paiement ; lien signé de courte durée.
- Paiements : intégration officielle côté serveur après obtention des accès marchands et documentation actuelle.
- Reversements : registre financier vérifiable, commissions et paiements vendeurs suivis séparément.
- Hébergement : HTTPS obligatoire ; secrets uniquement côté serveur.

## Étapes de réalisation
1. Remplacer les pages et textes de l'ancien modèle physique par les parcours marketplace numérique.
2. Créer le modèle de données vendeurs, abonnements, produits numériques, commandes, paiements, droits de téléchargement, commissions et reversements.
3. Écrire et vérifier les politiques RLS pour acheteurs, vendeurs et administrateurs.
4. Configurer un bucket privé pour les fichiers et des règles d'accès strictes.
5. Construire l'inscription acheteur et la demande d'accès vendeur.
6. Construire l'abonnement mensuel et l'activation après confirmation serveur/administrative.
7. Construire le tableau de bord vendeur : produits, fichiers, ventes, commissions et reversements.
8. Construire le catalogue public, panier, paiement et espace « Mes téléchargements ».
9. Construire l'administration protégée : vendeurs, abonnements, produits, commandes, paiements, litiges et reversements.
10. Intégrer les prestataires de paiement officiels et leurs webhooks idempotents.
11. Tester les permissions, les liens de téléchargement, les paiements, les remboursements, les sauvegardes et l'expérience mobile.

## Sécurité
- Ne jamais donner un fichier avant qu'un paiement soit confirmé.
- Ne jamais faire confiance aux montants calculés dans le navigateur.
- Ne jamais exposer les fichiers vendus via des URL publiques permanentes.
- Le rôle administrateur ne peut pas être attribué par auto-inscription ou métadonnées modifiables.
- Ne jamais publier de clé secrète, PIN, OTP ou mot de passe dans GitHub ou le JavaScript public.
- Un compte vendeur expiré ne doit pas annuler les achats déjà payés par les clients.
- Les intégrations de paiement et reversement doivent respecter les conditions des prestataires ; une personne adulte responsable peut être nécessaire pour les démarches contractuelles.
