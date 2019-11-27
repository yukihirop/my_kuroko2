# config/initializers/000_monkey_patches.rb
Dir[Rails.root.join('lib/monkey_patches/**/*.rb')].sort.each do |file|
  require file
end
