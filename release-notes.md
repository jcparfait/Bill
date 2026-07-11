# Bill v1.0.0-demo

Bill est une application Rails de bar conversationnel : l’utilisateur échange avec Bill, décrit son humeur et ses préférences, puis reçoit une recommandation de cocktail réelle avec ingrédients, recette et fiche détaillée.

## Démo

Application en ligne : https://bill-jcparfait.herokuapp.com

Compte démo recruteur :

- Email : demo@bill.app
- Mot de passe : 123456

## Fonctionnalités principales

- Authentification utilisateur avec Devise
- Conversations sauvegardées par utilisateur
- Réponses conversationnelles via RubyLLM et GitHub Models
- Logique métier Ruby pour analyser humeur, alcool, ingrédients à inclure ou éviter
- Recommandations de cocktails via catalogue interne et TheCocktailDB
- Prévention des doublons dans une même conversation
- Fiche cocktail avec image, ingrédients et recette
- Bibliothèque personnelle de cocktails
- Interface responsive desktop/mobile
- Déploiement Heroku avec PostgreSQL

## Stack technique

- Ruby on Rails 8.1
- PostgreSQL
- Devise
- Hotwire / Turbo Streams / Stimulus
- Bootstrap / Sass / Font Awesome
- RubyLLM
- GitHub Models
- TheCocktailDB API
- Heroku

## Points techniques intéressants

- Séparation entre la voix conversationnelle IA et la logique métier Ruby
- Prompts courts pour limiter le coût et garder un comportement prévisible
- Fallback applicatif si l’IA ou l’API cocktail ne répond pas
- Persistance des chats, messages et cocktails recommandés
- Gestion des contraintes utilisateur : sans alcool, sans ingrédient, avec ingrédient précis
- Affichage dynamique de la recommandation via Turbo Streams

## Statut

Version de démonstration portfolio destinée à un recruteur junior Rails/backend.
