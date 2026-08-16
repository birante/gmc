#!/usr/bin/env ruby
# Script test pour vérifier les changements

require_relative 'config/environment'

puts "\n" + "="*60
puts "🧪 TEST SUITE: Rules Simplification & Phone Normalization"
puts "="*60

# Test 1: Vérifier PhoneNormalizerService
puts "\n✅ Test 1: PhoneNormalizerService"
begin
  phone_service = PhoneNormalizerService.new("776857298", country_code: "SN")
  puts "   Créé: PhoneNormalizerService"
  puts "   Entrée: '776857298' (SN)"
  puts "   E.164: #{phone_service.to_e164}"
  puts "   LAM: #{phone_service.to_lam_format}"
rescue => e
  puts "   ❌ Erreur: #{e.message}"
end

# Test 2: Vérifier que multi_users rule n'existe pas
puts "\n✅ Test 2: Vérifier Rules"
multi_users_rule = Rule.find_by(code: "multi_users")
if multi_users_rule
  puts "   ⚠️  Rule 'multi_users' existe toujours: #{multi_users_rule.id}"
else
  puts "   ✅ Rule 'multi_users' supprimée"
end

# Afficher les règles actuelles
current_rules = Rule.pluck(:code).sort
puts "   Règles actuelles (#{current_rules.count}): #{current_rules.join(', ')}"

# Test 3: Vérifier les plans
puts "\n✅ Test 3: Vérifier Plans"
Plan.all.order(:code).each do |plan|
  # Récupérer max_employees de plan_rules
  max_emp_rule = plan.plan_rules.find_by(rule_code: "max_employees")
  max_emp_value = max_emp_rule&.value

  # Vérifier s'il y a toujours une règle multi_users
  multi_rule = plan.plan_rules.find_by(rule_code: "multi_users")

  puts "\n   Plan: #{plan.code}"
  puts "   - max_employees: #{max_emp_value.inspect}"
  puts "   - Multi-users enabled?: #{plan.max_employees.nil? || plan.max_employees.to_i > 1}"
  puts "   - OLD multi_users rule: #{multi_rule ? '❌ Existe' : '✅ Supprimée'}"

  # Liste toutes les règles du plan
  rules = plan.plan_rules.map(&:rule_code).sort
  puts "   - Règles du plan: #{rules.join(', ')}"
end

# Test 4: Vérifier la migration existe
puts "\n✅ Test 4: Vérifier Migration"
migration_file = Dir.glob("db/migrate/*remove_multi_users_rule*.rb").first
if migration_file
  puts "   ✅ Migration créée: #{File.basename(migration_file)}"
else
  puts "   ⚠️  Migration non trouvée (créer manuellement si production)"
end

puts "\n" + "="*60
puts "✅ TESTS COMPLÉTÉS"
puts "="*60 + "\n"
