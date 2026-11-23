# HaitiBoutik — commissions, retraits et paiements

## Modifications préparées dans cette branche
- Identité visuelle vert, blanc et noir, avec affichage responsive.
- Page d'accueil orientée vers une boutique officielle unique et le parcours client : catalogue, commande, suivi.

## Ajout technique dans cette branche
- `finances.html` : tableau de bord réservé à l'administrateur, soldes en GDS, historique des commissions et demandes de retrait NatCash.
- `20261123_commissions_and_natcash_payouts.sql` : tables, calcul de commission et RPC de demande de retrait.
- Commission de plateforme prévue : 10 % du montant des produits, plafonnée à la marge restante après coût fournisseur.
- Une commission n'est comptabilisée que si la commande est livrée ET qu'un paiement client est marqué vérifié.
- Le retrait crée une demande; aucun transfert NatCash automatique n'est simulé.

## Activation requise
1. Appliquer le fichier SQL dans Supabase SQL Editor après les migrations existantes.
2. Vérifier que le compte administrateur autorisé est bien configuré.
3. Connecter un compte marchand et une API officielle de paiement avant d'accepter de vrais paiements.

## Moyens de paiement visés
- Haïti : MonCash et NatCash.
- France et États-Unis : cartes Visa/Mastercard via un prestataire qui accepte explicitement le marchand, le pays d'établissement et les règlements vers Haïti.
Ces moyens sont des objectifs d'intégration, pas des connexions actives. Les clés privées, PIN et OTP ne doivent jamais être ajoutés au dépôt.

## Limites actuelles
- La page ne transfère pas d'argent.
- Le calcul dépend des données fournisseur correctement renseignées dans `supplier_catalog.supplier_price_gds`.
- Le recalcul retire désormais une commission si la commande n'est plus livrée ou si le paiement est invalidé.
- Le fournisseur est un partenaire de préparation/livraison : le versement effectif après commande n'est pas automatisé dans cette version. Il faut une intégration de paiement fournisseur sécurisée, un accord commercial et un mécanisme de rapprochement avant d'envoyer de l'argent.
- L'enregistrement du moyen de paiement choisi à la commande et les webhooks de confirmation nécessitent une intégration serveur dédiée.
- Les règles de remboursement, litige, taxes, frais de change et conformité doivent être définies avant lancement réel.
