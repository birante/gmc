puts "Seeding EduCMS…"

# --- Users ---
User.find_or_create_by!(email: "admin@educms.local") do |u|
  u.password = "password123"
  u.first_name = "Ada"
  u.last_name  = "Admin"
  u.role       = :admin
end
User.find_or_create_by!(email: "editor@educms.local") do |u|
  u.password = "password123"
  u.first_name = "Ed"
  u.last_name  = "Editor"
  u.role       = :editor
end
User.find_or_create_by!(email: "author@educms.local") do |u|
  u.password = "password123"
  u.first_name = "Amina"
  u.last_name  = "Author"
  u.role       = :author
end

# --- Categories ---
categories = [
  { name: "Computer Science", description: "Articles about computer science topics" },
  { name: "Programming",      description: "Programming tutorials and guides" },
  { name: "Web Development",  description: "Web development resources" },
  { name: "Data Science",     description: "Data science and analytics" },
  { name: "Artificial Intelligence", description: "AI and machine learning topics" },
]
categories.each_with_index do |attrs, idx|
  Category.find_or_create_by!(name: attrs[:name]) do |c|
    c.description   = attrs[:description]
    c.display_order = idx + 1
    c.active        = true
  end
end

# --- Tags ---
%w[JavaScript Python React Rails Node.js MachineLearning Tutorial Beginner Advanced].each do |name|
  Tag.find_or_create_by!(name: name)
end

# --- Posts ---
admin  = User.find_by(email: "admin@educms.local")
author = User.find_by(email: "author@educms.local")
cs     = Category.find_by(name: "Computer Science")
web    = Category.find_by(name: "Web Development")
ds     = Category.find_by(name: "Data Science")

Post.find_or_create_by!(title: "Getting started with Rails 8") do |p|
  p.author = admin
  p.category = web
  p.content = "<p>Rails 8 ships with Solid Cable, Solid Cache and Solid Queue by default — no Redis needed for many apps.</p><p>Add authentication, WYSIWYG editing and a headless API and you have a full CMS in a few days.</p>"
  p.excerpt = "A quick tour of what ships in the box with the latest Rails."
  p.status  = :published
  p.tags    = Tag.where(name: %w[Rails Tutorial Beginner])
  p.is_featured = true
end

Post.find_or_create_by!(title: "Building a headless CMS") do |p|
  p.author = author
  p.category = web
  p.content = "<p>A headless CMS separates content storage from presentation. The API layer exposes JSON to any frontend — React, Vue, Svelte, or a mobile app.</p>"
  p.excerpt = "Content editing in Rails, JSON out to any frontend."
  p.status  = :published
  p.tags    = Tag.where(name: %w[React Tutorial Advanced])
end

Post.find_or_create_by!(title: "Machine learning fundamentals") do |p|
  p.author = author
  p.category = ds
  p.content = "<p>Supervised, unsupervised, reinforcement — the three broad families of machine learning, and when each is the right tool.</p>"
  p.excerpt = "The three families of ML, in plain language."
  p.status  = :published
  p.tags    = Tag.where(name: %w[MachineLearning Python Beginner])
end

puts "Done. Users: admin@educms.local / editor@educms.local / author@educms.local (password: password123)"
