demo_password = ENV["DEMO_USER_PASSWORD"]

if demo_password.present?
  User.find_or_create_by!(email_address: "demo@example.com") { |user| user.password = demo_password }
  puts "Demo user ready: demo@example.com"
else
  puts "DEMO_USER_PASSWORD is not set; no demo user created."
end
