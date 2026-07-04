# Bill

Bill est une application web Rails qui propose une experience de bar conversationnel. L'utilisateur discute avec Bill, decrit son humeur, son energie ou l'ambiance recherchee, puis l'application recommande un cocktail adapte avec une fiche detaillee.

Le projet combine une interface Rails / Hotwire, une authentification Devise, une voix conversationnelle pilotee par LLM avec des prompts courts, une logique de recommandation Ruby sobre en tokens et une integration avec TheCocktailDB pour recuperer de vrais cocktails, leurs ingredients et leurs recettes.

> Projet initialement realise en formation, repris dans ce depot pour le nettoyer, le documenter et le preparer comme projet portfolio.

## Statut

- Application web Rails fonctionnelle.
- Authentification utilisateur avec Devise.
- Conversations sauvegardees par utilisateur.
- Reponses naturelles de Bill via RubyLLM et GitHub Models, avec prompts courts.
- Recommandations de cocktails via regles metier et TheCocktailDB.
- Historique des chats et cocktails recommandes.
- README en cours de preparation pour une demonstration recruteur.

## Fonctionnalites

- creation de compte et connexion utilisateur ;
- verification d'age via le champ `over18` ;
- demarrage d'une conversation avec Bill ;
- trois questions minimum pour cerner l'humeur, l'envie sensorielle et les contraintes ;
- voix de Bill: calme, seche, ironique, humaine, sans reponses robotiques ;
- extraction du mood avec des regles Ruby simples ;
- gestion de contraintes avec ou sans certains ingredients ;
- prevention des recommandations en doublon dans une meme conversation ;
- recuperation d'un cocktail reel depuis TheCocktailDB ;
- affichage des ingredients et de la recette fournis par l'API cocktail ;
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
| Voix IA | RubyLLM, GitHub Models, Azure OpenAI Playground |
| Recommandation | Regles Ruby, catalogue interne, TheCocktailDB |
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

## Flux de recommandation

Bill limite les appels LLM tout en gardant une vraie personnalite:

1. Le code decide quelle information manque: humeur, envie sensorielle, alcool ou contraintes d'ingredients.
2. Un mini prompt LLM formule la reponse de Bill de facon naturelle et variee.
3. Bill pose au moins trois questions avant de recommander, sauf demande tres explicite apres assez de contexte.
4. Les reponses utilisateur sont analysees par des regles Ruby: humeur, energie, alcool ou sans alcool, ingredients a inclure ou eviter.
5. Le code choisit des candidats dans un catalogue interne de cocktails connus.
6. Le code exclut les cocktails deja proposes dans le meme chat.
7. TheCocktailDB fournit la fiche reelle du cocktail.
8. Un mini prompt LLM peut formuler la phrase de recommandation, sans ingredients ni recette.

Cette approche garde l'interet IA du projet sans consommer plusieurs gros prompts par message.

## Installation locale

Prerequis:

- Ruby compatible Rails 8.1 ;
- PostgreSQL ;
- Bundler ;
- un jeton GitHub avec l'autorisation `Models` en lecture seule pour activer la voix IA.

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

Le projet utilise RubyLLM avec GitHub Models via l'endpoint Azure OpenAI Playground du Wagon.

En local, creer un fichier `.env` a partir de `.env.example`:

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
- tests du `RecommendCocktailTool` avec mocks pour TheCocktailDB ;
- tests du choix de cocktail selon mood et ingredients ;
- CI GitHub Actions.

## Notes produit

Bill recommande des cocktails, mais l'application doit rester claire sur la moderation. Le parcours utilisateur inclut une verification d'age et la logique de recommandation privilegie les options sans alcool quand le contexte le demande.

## Roadmap courte

- ajouter les premiers tests Rails ;
- deployer l'application avec les variables d'environnement ;
- ajouter des captures d'ecran dans le README ;
- creer une release de demonstration ;
- ajuster le prompt court de Bill selon les retours de test.