# Bill - Product checklist

Checklist de préparation projet inspirée du workflow Le Wagon: design produit, build Rails, gestion projet et sign-off.

## Produit

- [x] Parcours principal défini: discuter avec Bill, préciser l'humeur et les contraintes, recevoir un cocktail.
- [x] Utilisateur cible clair: recruteur ou utilisateur testant une démo web conversationnelle.
- [x] MVP centré sur un seul usage fort: recommandation de cocktail conversationnelle.
- [x] Authentification utilisateur avec Devise.
- [x] Vérification d'âge à la création de compte.
- [x] Historique de conversations par utilisateur.
- [x] Collection personnelle de cocktails.
- [x] Profil utilisateur avec actions de compte.
- [x] Navigation desktop et mobile cohérente.

## Build Rails

- [x] Application Rails versionnée sur GitHub.
- [x] Modèles principaux en place: `User`, `Chat`, `Message`, `Cocktail`.
- [x] Associations et dépendances principales configurées.
- [x] Routes principales documentées dans le README.
- [x] Seeds disponibles avec compte de démonstration.
- [x] Variables d'environnement documentées dans `.env.example`.
- [x] RubyLLM configuré pour GitHub Models via `GITHUB_TOKEN`.
- [x] TheCocktailDB utilisé pour récupérer des cocktails réels.
- [x] Fallback de recommandation pour proposer le cocktail le plus proche quand la recherche stricte échoue.
- [x] Pages d'erreur 404, 422 et 500 brandées.
- [x] Manifest assets mis à jour pour précompiler `application.css` et les assets.
- [x] Favicon et logos ajoutés.
- [x] Meta description et Open Graph de base ajoutés.

## Qualité

- [x] README avec installation locale, variables d'environnement, compte de démo et commandes utiles.
- [x] Healthcheck Rails disponible sur `/up`.
- [x] UI responsive sur les pages principales.
- [x] Erreurs de compilation Sass corrigées.
- [x] Scroll du chat et carte cocktail ajustés desktop/mobile.
- [ ] Lancer `bin/rails test` après le dernier pull.
- [ ] Lancer `bundle exec brakeman` avant démo publique.
- [ ] Tester le parcours complet sur mobile réel.
- [ ] Tester création de compte, suppression/déconnexion, historique, collection cocktails.

## Sign-off et déploiement

- [ ] Vérifier que `git status` est clean localement.
- [ ] Pull le dernier `master` avant déploiement.
- [ ] Déployer sur Heroku ou plateforme cible.
- [ ] Lancer `rails db:migrate` en production.
- [ ] Vérifier que `APP_HOST`, `APP_PROTOCOL` et `GITHUB_TOKEN` sont configurés en production.
- [ ] Vérifier `/up` en production.
- [ ] Tester le compte de démonstration en production.
- [ ] Mettre à jour la page produit Kitt avec les liens GitHub, app déployée, README et démo.

## Notes restantes

Le lien GitHub public `https://github.com/lewagon/product/tree/master/checklist` renvoie un 404 depuis l'extérieur. Cette checklist reprend donc les documents disponibles dans le projet: kick-off, product design, building, project management et before sign-off.
