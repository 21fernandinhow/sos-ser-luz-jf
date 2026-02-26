# Idempotent seeds. Run with: bin/rails db:seed
#
# NGO user for panel access. In production, set ENV:
#   NGO_SEED_EMAIL=projetoserluz@gmail.com
#   NGO_SEED_PASSWORD=your_secure_password

email = ENV.fetch("NGO_SEED_EMAIL", "projetoserluzjf@gmail.com")
password = ENV.fetch("NGO_SEED_PASSWORD", "trocar_senha_123")

user = User.find_or_initialize_by(email: email.strip.downcase)
user.password = password
user.save!
puts "NGO user ready: #{user.email}"
