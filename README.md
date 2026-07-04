# Bill

Bill est une application web Rails qui propose une experience de bar conversationnel. L'utilisateur discute avec Bill, decrit son humeur, son energie ou l'ambiance recherchee, puis l'application recommande un cocktail adapte avec une fiche detaillee.

Le projet combine une interface Rails / Hotwire, une authentification Devise, un assistant conversationnel pilote par LLM et une integration avec TheCocktailDB pour recuperer de vrais cocktails, leurs ingredients et leurs recettes.

> Projet initialement realise en formation, repris dans ce depot pour le nettoyer, le documenter et le preparer comme projet portfolio.

## Statut

- Application web Rails fonctionnelle.
- Authentification utilisateur avec Devise.
- Conversations sauvegardees par utilisateur.
- Recommandations de cocktails via RubyLLM, GitHub Models et TheCocktailDB.
- Historique des chats et cocktails recommandes.
- README en cours de preparation pour une demonstration recruteur.

## Fonctionnalites

- creation de compte et connexion utilisateur ;
- verification d'age via le champ `over18` ;
- demarrage d'une conversation avec Bill ;
- prise en compte de l'humeur, du contexte et des preferences ;
- recommandation progressive apres quelques messages ;
- recuperation d'un cocktail reel depuis TheCocktailDB ;
- traduction des ingredients et de la recette en francais ;
- affichage d'une carte cocktail ;
- historique des conversations ;
- bibliotheque personnelle de cocktails recommandes ou crees.

## Stack

| Partie | Technologies |
| --- | --- |
| Backend | Ruby on Rails 8.1 |
| Auth | Devise |
| UI | Rails views, Hotwire, Turbo Streams, Stimulus |
| Styles | Bootstrap, Sass, Font Awesome |
| Base de donnees | PostgreSQL |
| IA | RubyLLM, GitHub Models, Azure OpenAI Playground |
| Donnees cocktail | TheCocktailDB |
| Tests | Minitest Rails |

## Architecture

```text
.
├── app/
│   ├── controllers/       # Chats, messages, cocktails
│   ├── models/            # User, Chat, Message, Cocktail
│   ├── tools/             # RecommendCocktailTool
│   └── views/             # Interface web Rails / Hotwire
├── config/
│   ├── routes.rb          # Routes Devise, chats, messages, cocktails
│   └── initializers/      # Configuration RubyLLM
├── db/                    # Schema, migrations, seeds
└── test/                  # Tests Rails a renforcer
```

## Installation locale

Prerequis:

- Ruby compatible Rails 8.1 ;
- PostgreSQL ;
- Bundler ;
- un jeton GitHub avec l'autorisation `Models` en lecture seule.

Installation:

```bash
bundle install
cp .env.example .env
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
bin/rails server
```

Puis ouvrir:

```text
http://localhost:3000
```

## Variables d'environnement

Le projet utilise RubyLLM avec GitHub Models via l'endpoint Azure OpenAI Playground du Wagon. En local, creer un fichier `.env` a partir de `.env.example`:

```bash
cp .env.example .env
```

Variables principales:

```text
GITHUB_TOKEN=github_pat_...
GITHUB_MODELS_API_BASE=https://models.inference.ai.azure.com
GITHUB_MODELS_MODEL=gpt-4o
```

Le token GitHub doit etre un fine-grained personal access token avec `Account permissions > Models > Read-only`.

## Compte de demonstration

Les seeds creent plusieurs utilisateurs. Compte principal:

```text
Email: lucas@example.com
Mot de passe: 123456
```

Autres comptes seeds:

- `emma@example.com` / `password123`
- `nathan@example.com` / `password123`
- `sarah@example.com` / `password123`
- `leo@example.com` / `password123`

## Routes principales

| Domaine | Routes |
| --- | --- |
| Accueil | `GET /` |
| Healthcheck | `GET /up` |
| Auth | routes Devise utilisateurs |
| Conversations | `GET/POST /chats`, `GET /chats/:id`, `DELETE /chats/:id` |
| Messages | `POST /chats/:chat_id/messages` |
| Cocktails | `GET/POST /cocktails`, `GET/PATCH/DELETE /cocktails/:id` |

## Tests et qualite

Commandes utiles:

```bash
bin/rails test
bin/rails test test/models
bin/rails test test/controllers
bundle exec brakeman
bundle exec rubocop
```

A renforcer avant presentation finale:

- tests modeles `User`, `Cocktail`, `Chat`, `Message` ;
- tests controleurs sur les parcours authentifies ;
- tests d'isolation entre utilisateurs ;
- tests du `RecommendCocktailTool` avec mocks pour GitHub Models et TheCocktailDB ;
- CI GitHub Actions.

## Notes produit

Bill recommande des cocktails, mais l'application doit rester claire sur la moderation. Le parcours utilisateur inclut une verification d'age et le prompt IA privilegie les options sans alcool quand le contexte le demande.

## Roadmap courte

- harmoniser tous les textes visibles autour du nom Bill ;
- ajouter les premiers tests Rails ;
- deployer l'application avec les variables d'environnement ;
- ajouter des captures d'ecran dans le README ;
- creer une release de demonstration.