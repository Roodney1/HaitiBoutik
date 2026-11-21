# Éléments externes nécessaires avant lancement réel

## MonCash et NatCash
Le dépôt ne contient pas de connexion active à ces fournisseurs. Pour l'intégration réelle, le propriétaire doit obtenir les conditions et accès marchands officiels, les identifiants API, les URL de retour/webhook et les règles de règlement. Les secrets doivent être stockés dans les variables d'environnement du serveur, jamais dans un fichier HTML ou JavaScript public.

À fournir/valider avec le fournisseur :
- compte marchand admissible et vérifié ;
- documentation API à jour et environnement de test ;
- identifiants privés et mécanisme de signature ;
- confirmation serveur-à-serveur du paiement ;
- frais, limites, remboursements et délais de règlement.

Ne partage jamais de mot de passe, PIN, code OTP ou clé privée dans GitHub ou dans cette conversation.

## Livraison réelle
Pour le mode plateforme, il faut recruter des coursiers/partenaires, définir les zones desservies, les tarifs, les responsabilités en cas de perte et la preuve de livraison.
Pour le mode marchand, le marchand saisit les informations du coursier et met à jour le statut.
Le prototype peut gérer des statuts, mais il ne peut pas envoyer un coursier physique sans réseau logistique.

## Conditions de lancement
- Conditions d'utilisation, politique de confidentialité et politique de remboursement.
- Support client et procédure de litige.
- Vérification des marchands et règles contre les fraudes.
- Tests avec de petites transactions réelles après autorisation.
- Un adulte responsable peut devoir accompagner les démarches contractuelles et de vérification, compte tenu de l'âge du porteur du projet.

## Ce qui n'est pas encore activé
Aucune transaction MonCash/NatCash réelle, aucune activation automatique réelle, aucun coursier connecté, aucune commande réelle garantie par un backend tant que les services et les tests ci-dessus ne sont pas configurés.
