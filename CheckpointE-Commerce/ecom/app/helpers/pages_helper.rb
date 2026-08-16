module PagesHelper
  # Affiche un compteur arrondi vers le bas avec un préfixe "+"
  # - 1 247  → "+1k"
  # - 12 940 → "+12k"
  # - 53 800 → "+50k"
  # - 1 000 000 → "+1M"
  def rounded_count_display(count)
    return "0" if count.to_i.zero?

    n = count.to_i
    if n >= 1_000_000
      "+#{(n / 1_000_000)}M"
    elsif n >= 1_000
      "+#{(n / 1_000)}k"
    elsif n >= 100
      "+#{(n / 100) * 100}"
    elsif n >= 10
      "+#{(n / 10) * 10}"
    else
      "+#{n}"
    end
  end
end
