require "test_helper"

class LocaleTest < ActionDispatch::IntegrationTest
  test "default locale is Swedish" do
    assert_equal :sv, I18n.default_locale
  end

  test "available locales include Swedish and English" do
    assert_includes I18n.available_locales, :sv
    assert_includes I18n.available_locales, :en
  end

  test "Swedish translation exists for common keys" do
    I18n.with_locale(:sv) do
      assert_not_equal "translation missing", I18n.t("helpers.submit.create")
      assert_equal "Skapa", I18n.t("helpers.submit.create")
    end
  end

  test "falls back to English when Swedish translation missing" do
    I18n.with_locale(:sv) do
      # Test fallback using a key that's defined only in English
      I18n.backend.store_translations(:en, { test_fallback: "English fallback" })
      assert_equal "English fallback", I18n.t("test_fallback")
    end
  end
end
