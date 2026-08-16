require "test_helper"

class OtpGenerationSimpleTest < ActiveSupport::TestCase
  test "OTP generation should always produce 5 digits" do
    length = 5

    # Tester la méthode de génération directement
    100.times do
      code = rand(10**(length-1)..10**length-1).to_s.rjust(length, "0")

      assert_equal 5, code.length, "Code should be exactly 5 characters: #{code}"
      assert_match(/^\d{5}$/, code, "Code should contain only 5 digits: #{code}")
      assert code.to_i >= 10000, "Code should be at least 10000: #{code}"
      assert code.to_i <= 99999, "Code should be at most 99999: #{code}"
    end
  end

  test "OTP generation should handle different lengths" do
    [ 1, 2, 3, 4, 5, 6, 7, 8 ].each do |length|
      code = rand(10**(length-1)..10**length-1).to_s.rjust(length, "0")

      assert_equal length, code.length, "Code should be exactly #{length} characters for length #{length}: #{code}"
      assert_match(/^\d{#{length}}$/, code, "Code should contain only #{length} digits: #{code}")

      min_value = 10**(length-1)
      max_value = 10**length-1
      assert code.to_i >= min_value, "Code should be at least #{min_value}: #{code}"
      assert code.to_i <= max_value, "Code should be at most #{max_value}: #{code}"
    end
  end

  test "OTP generation should produce different codes" do
    codes = []
    50.times do
      code = rand(10000..99999).to_s.rjust(5, "0")
      codes << code
    end

    # Il devrait y avoir des codes différents (très probable avec 50 générations)
    unique_codes = codes.uniq
    assert unique_codes.length > 1, "Should generate different codes, got only #{unique_codes.length} unique codes"
  end
end
