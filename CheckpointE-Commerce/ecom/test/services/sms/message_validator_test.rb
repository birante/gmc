# frozen_string_literal: true

require "test_helper"

class Sms::MessageValidatorTest < ActiveSupport::TestCase
  test "unicode? returns false for GSM-7 characters" do
    message = "Hello World 123"
    assert_not Sms::MessageValidator.unicode?(message)
  end

  test "unicode? returns true for Unicode characters" do
    message = "Hello 🌍 World"
    assert Sms::MessageValidator.unicode?(message)
  end

  test "unicode? returns true for accented characters" do
    message = "Bonjour à tous"
    # Les accents peuvent être dans GSM-7 étendu, mais pour simplifier on considère comme Unicode
    # En réalité, certains accents sont dans GSM-7, mais on garde cette logique simple
    assert Sms::MessageValidator.unicode?(message)
  end

  test "calculate_segments returns 1 segment for short GSM-7 message" do
    message = "Hello" * 10 # 50 caractères
    info = Sms::MessageValidator.calculate_segments(message)

    assert_equal 1, info[:segments]
    assert_equal "gsm7", info[:encoding]
    assert_equal 50, info[:total_length]
  end

  test "calculate_segments returns multiple segments for long GSM-7 message" do
    message = "A" * 200 # 200 caractères, devrait faire 2 segments (153 + 47)
    info = Sms::MessageValidator.calculate_segments(message)

    assert_equal 2, info[:segments]
    assert_equal "gsm7", info[:encoding]
    assert_equal 200, info[:total_length]
    assert_equal 2, info[:cost_multiplier]
  end

  test "calculate_segments returns 1 segment for short Unicode message" do
    message = "Hello 🌍" * 5 # ~35 caractères
    info = Sms::MessageValidator.calculate_segments(message)

    assert_equal 1, info[:segments]
    assert_equal "unicode", info[:encoding]
  end

  test "calculate_segments returns multiple segments for long Unicode message" do
    message = "🌍" * 100 # 100 caractères Unicode, devrait faire 2 segments (67 + 33)
    info = Sms::MessageValidator.calculate_segments(message)

    assert info[:segments] >= 2
    assert_equal "unicode", info[:encoding]
  end

  test "validate! raises error for message exceeding max_segments" do
    message = "A" * 500 # Très long message

    assert_raises(Sms::MessageValidator::MessageTooLongError) do
      Sms::MessageValidator.validate!(message, max_segments: 2)
    end
  end

  test "validate! does not raise for message within limit" do
    message = "A" * 100 # Message court

    assert_nothing_raised do
      Sms::MessageValidator.validate!(message, max_segments: 3)
    end
  end

  test "validate returns warning for segmented message" do
    message = "A" * 200 # Message qui nécessite 2 segments

    result = Sms::MessageValidator.validate(message, max_segments: 3)

    assert result[:valid]
    assert_not_nil result[:warning]
    assert_match(/segmenté/, result[:warning])
  end

  test "validate returns invalid for message exceeding max_segments" do
    message = "A" * 500 # Très long message

    result = Sms::MessageValidator.validate(message, max_segments: 2)

    assert_not result[:valid]
    assert_not_nil result[:warning]
  end
end
