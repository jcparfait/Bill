# Bill

Bill est une application web Rails qui simule un bar conversationnel. L'utilisateur discute avec Bill, décrit son humeur, ses goûts ou ses contraintes, puis l'application recommande un cocktail réel avec sa recette et ses ingrédients.

Le projet combine une interface Rails / Hotwire, une authentification Devise, une voix conversationnelle pilotée par LLM, une logique métier Ruby pour limiter les coûts en tokens et une intégration avec TheCocktailDB pour récupérer de vraies fiches cocktails.

> Projet initialement réalisé en formation, repris et nettoyé pour devenir un projet portfolio présentable à un recruteur.

## Démo

Application en ligne :

```text
https://bill-jcparfait-8fb7a6f900f1.herokuapp.com
```

Compte de démonstration :

```text
Email: demo@bill.app
Mot de passe: 123456
```

Le compte démo contient déjà quelques conversations et cocktails enregistrés afin de montrer le parcours sans partir d'une base vide.

## Pourquoi ce projet

Bill n'est pas seulement un chatbot. L'objectif est de montrer une application Rails complète qui combine :

- une expérience conversationnelle naturelle ;
- une vraie logique métier côté serveur ;
- un service externe pour obtenir des données fiables ;
- une interface responsive avec Turbo Streams ;
- une authentification et une collection personnelle par utilisateur.

## Fonctionnalités principales

- Création de compte et connexion utilisateur avec Devise.
- Discussion avec Bill, un barman fictif au ton calme, ironique et légèrement absurde.
- Compréhension du mood, des préférences et des contraintes d'ingrédients.
- Recommandation d'un cocktail adapté après échange conversationnel.
- Récupération des ingrédients, proportions et instructions depuis TheCocktailDB.
- Carte cocktail interactive : enregistrer ou passer la recommandation.
- Prévention des doublons dans une même conversation et avec les cocktails déjà enregistrés.
- Bibliothèque personnelle de cocktails.
- Historique des conversations.
- Profil utilisateur avec déconnexion et gestion de compte.
- Interface responsive desktop / mobile.

## Stack technique

| Partie | Technologies |
| --- | --- |
| Backend | Ruby on Rails 8.1 |
| Base de données | PostgreSQL |
| Authentification | Devise |
| UI | Rails views, Hotwire, Turbo Streams, Stimulus |
| Styles | Sass, Bootstrap, Font Awesome |
| IA conversationnelle | RubyLLM, GitHub Models, Azure OpenAI Playground |
| API externe | TheCocktailDB |
| Déploiement | Heroku |
| Tests | Minitest Rails |

## Architecture simplifiée

```text
.
├── app/
│   ├── controllers/       # Chats, messages, cocktails, profil
│   ├── models/            # User, Chat, Message, Cocktail
│   ├── tools/             # RecommendCocktailTool
│   └── views/             # Interface Rails / Hotwire
├── config/
│   ├── routes.rb          # Routes Devise, chats, messages, cocktails
│   └── initializers/      # RubyLLM et fallback cocktail
├── db/                    # Schema, migrations, seeds
└── test/                  # Tests Rails
```

## Logique de recommandation

Bill utilise l'IA pour la conversation et le ton, mais la recommandation n'est pas laissée entièrement au modèle.

Le flux principal :

1. Le contrôleur analyse la conversation et demande au LLM une décision structurée : continuer à discuter ou recommander.
2. Le LLM renvoie une réponse JSON courte : action, mood, tags, ingrédients à inclure ou exclure, alcool ou sans alcool.
3. Le code Ruby applique les contraintes métier : pas de doublon, respect des exclusions, prise en compte des cocktails déjà enregistrés.
4. L'application choisit des candidats dans un catalogue interne.
5. TheCocktailDB fournit la fiche réelle du cocktail.
6. Bill formule une recommandation courte, sans répéter la recette, car la carte cocktail l'affiche déjà.

Cette approche permet de garder l'intérêt IA du projet tout en évitant que le LLM contrôle toute la logique métier.

## Points techniques intéressants

- Utilisation de Turbo Streams pour afficher les messages et la carte cocktail sans rechargement complet.
- Séparation entre cocktail proposé et cocktail réellement sauvegardé.
- Fallback Ruby si l'IA ou l'API externe échoue.
- Exclusion des cocktails déjà proposés dans le chat.
- Exclusion des cocktails déjà présents dans la collection utilisateur.
- Prompt court pour réduire la consommation de tokens.
- Pages d'erreur personnalisées `404`, `422`, `500`.
- Configuration Heroku avec variables d'environnement pour GitHub Models.

## Installation locale

Prérequis :

- Ruby compatible Rails 8.1 ;
- PostgreSQL ;
- Bundler ;
- un jeton GitHub avec l'autorisation `Models: Read-only` pour activer l'IA.

Installation :

```bash
bundle install
cp .env.example .env
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
bin/rails server
```

Puis ouvrir :

```text
http://localhost:3000
```

## Variables d'environnement

En local, créer un fichier `.env` à partir de `.env.example` :

```bash
cp .env.example .env
```

Variables principales :

```text
GITHUB_TOKEN=github_pat_...
GITHUB_MODELS_API_BASE=https://models.inference.ai.azure.com
GITHUB_MODELS_MODEL=gpt-4o
APP_HOST=localhost:3000
APP_PROTOCOL=http
```

En production Heroku :

```bash
heroku config:set \
  GITHUB_TOKEN=github_pat_... \
  GITHUB_MODELS_API_BASE=https://models.inference.ai.azure.com \
  GITHUB_MODELS_MODEL=gpt-4o \
  APP_HOST=bill-jcparfait-8fb7a6f900f1.herokuapp.com \
  APP_PROTOCOL=https \
  RAILS_LOG_LEVEL=info \
  --app bill-jcparfait
```

Le token GitHub doit être un fine-grained personal access token avec :

```text
Account permissions > Models > Read-only
```

## Routes principales

| Domaine | Routes |
| --- | --- |
| Accueil | `GET /` |
| Healthcheck | `GET /up` |
| Auth | routes Devise utilisateurs |
| Conversations | `GET /chats`, `POST /chats`, `GET /chats/:id`, `DELETE /chats/:id` |
| Messages | `POST /chats/:chat_id/messages` |
| Cocktails | `GET /cocktails`, `POST /cocktails`, `GET /cocktails/:id`, `PATCH /cocktails/:id`, `DELETE /cocktails/:id` |
| Profil | `GET /profile` |

## Tests et qualité

Commandes utiles :

```bash
bin/rails test
bundle exec brakeman
bundle exec rubocop
RAILS_ENV=production bin/rails assets:precompile
```

Vérifications manuelles effectuées pour la démo :

- inscription ;
- connexion ;
- conversation avec Bill ;
- appel IA via GitHub Models ;
- recommandation cocktail ;
- enregistrement d'un cocktail ;
- refus d'un cocktail ;
- gestion d'un cocktail déjà enregistré ;
- page Mes cocktails ;
- page Profil ;
- affichage mobile ;
- favicon et pages d'erreur personnalisées.

## Limites connues

- L'IA dépend du quota GitHub Models disponible sur le token configuré.
- TheCocktailDB peut ne pas contenir exactement toutes les contraintes demandées ; l'application cherche alors le cocktail le plus proche.
- Les tests automatisés doivent encore être renforcés sur le parcours complet chat + API externe.

## Roadmap courte

- Ajouter des tests d'intégration avec mocks pour TheCocktailDB.
- Ajouter une CI GitHub Actions.
- Ajouter des captures d'écran dans le README.
- Améliorer l'accessibilité clavier et les états focus.
- Préparer une release GitHub `v1.0.0-demo`.
