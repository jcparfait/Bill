

puts "Cleaning database"
User.destroy_all
Cocktail.destroy_all

puts "Ceating Users"
User.create!([
  {
    email: "lucas@example.com",
    password: "password123",
    password_confirmation: "password123",
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

puts "finished !"
