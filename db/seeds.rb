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
    mood: "fresh",
    ingredients: "Rum, mint, lime, sugar, sparkling water",
    recipe: "Muddle mint, lime and sugar. Add rum, ice and sparkling water.",
    user: owner
  },
  {
    name: "Espresso Martini",
    mood: "tired but social",
    ingredients: "Vodka, coffee liqueur, espresso, sugar syrup",
    recipe: "Shake all ingredients with ice and strain into a chilled glass.",
    user: owner
  },
  {
    name: "Virgin Mule",
    mood: "calm",
    ingredients: "Ginger beer, lime, mint, cucumber",
    recipe: "Build all ingredients over ice and stir gently.",
    user: owner
  },
  {
    name: "Old Fashioned",
    mood: "nostalgic",
    ingredients: "Whiskey, sugar, bitters, orange peel",
    recipe: "Stir sugar and bitters, add whiskey gently over sugar and bitters, then garnish with orange peel.",
    user: owner
  },
  {
    name: "Negroni",
    mood: "melancholic",
    ingredients: "Gin, Campari, sweet vermouth, orange peel",
    recipe: "Stir gin, Campari and vermouth with ice. Serve with orange peel.",
    user: owner
  }
])

puts "Finished!"
