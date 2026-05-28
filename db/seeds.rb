puts "Cleaning database..."

Message.destroy_all
Chat.destroy_all
Cocktail.destroy_all
User.destroy_all

puts "Creating users..."

users = User.create!([
  {
    email: "lucas@example.com",
    password: "123456",
    password_confirmation: "123456",
    over18: true
  },
  {
    email: "emma@example.com",
    password: "password123",
    password_confirmation: "password123",
    over18: true
  },
  {
    email: "nathan@example.com",
    password: "password123",
    password_confirmation: "password123",
    over18: true
  },
  {
    email: "sarah@example.com",
    password: "password123",
    password_confirmation: "password123",
    over18: true
  },
  {
    email: "leo@example.com",
    password: "password123",
    password_confirmation: "password123",
    over18: true
  }
])

puts "Creating cocktails..."

owner = users.first

Cocktail.create!([
  {
    name: "Mojito",
    mood: "rafraîchissant",
    ingredients: "Rhum blanc, menthe fraîche, citron vert, sucre de canne, eau pétillante",
    recipe: "Écraser délicatement la menthe, le citron vert et le sucre. Ajouter le rhum, des glaçons puis compléter avec de l’eau pétillante.",
    user: owner
  },
  {
    name: "Espresso Martini",
    mood: "fatigué mais sociable",
    ingredients: "Vodka, liqueur de café, expresso, sirop de sucre",
    recipe: "Verser tous les ingrédients dans un shaker avec des glaçons. Secouer énergiquement puis filtrer dans un verre bien frais.",
    user: owner
  },
  {
    name: "Virgin Mule",
    mood: "apaisé",
    ingredients: "Ginger beer, citron vert, menthe fraîche, concombre",
    recipe: "Remplir un verre de glaçons, ajouter les ingrédients puis mélanger délicatement avant de servir bien frais.",
    user: owner
  },
  {
    name: "Old Fashioned",
    mood: "nostalgique",
    ingredients: "Whisky, sucre, bitters, zeste d’orange",
    recipe: "Mélanger le sucre et les bitters, ajouter le whisky et des glaçons puis remuer doucement. Terminer avec un zeste d’orange.",
    user: owner
  },
  {
    name: "Negroni",
    mood: "mélancolique",
    ingredients: "Gin, Campari, vermouth rouge, zeste d’orange",
    recipe: "Mélanger le gin, le Campari et le vermouth avec des glaçons puis servir avec un zeste d’orange.",
    user: owner
  }
])

puts "Finished!"
