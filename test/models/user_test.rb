require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user with all required attributes" do
    user = build(:user)
    assert user.valid?
  end

  test "email is required" do
    user = build(:user, email: nil)
    assert_not user.valid?
    assert_includes user.errors[:email], "måste anges"
  end

  test "email must be unique (case-insensitive)" do
    create(:user, email: "test@example.com")
    duplicate = build(:user, email: "TEST@example.com")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "används redan"
  end

  test "email must be valid format" do
    user = build(:user, email: "not-an-email")
    assert_not user.valid?
    assert_includes user.errors[:email], "är ogiltig"
  end

  test "name is required" do
    user = build(:user, name: nil)
    assert_not user.valid?
    assert_includes user.errors[:name], "måste anges"
  end

  test "name must not exceed 100 characters" do
    user = build(:user, name: "A" * 101)
    assert_not user.valid?
    assert_includes user.errors[:name], "är för lång (max 100 tecken)"
  end

  test "locale defaults to sv" do
    user = User.new(email: "test@example.com", name: "Test")
    assert_equal "sv", user.locale
  end

  test "locale must be sv or en" do
    user = build(:user, locale: "de")
    assert_not user.valid?
    assert_includes user.errors[:locale], "finns inte i listan"
  end

  test "locale can be set to en" do
    user = build(:user, locale: "en")
    assert user.valid?
  end

  test "initials returns first letters of name parts" do
    user = build(:user, name: "Anna Svensson")
    assert_equal "AS", user.initials
  end

  test "initials limits to two characters" do
    user = build(:user, name: "Anna Maria Svensson Johansson")
    assert_equal "AM", user.initials
  end

  test "initials handles single name" do
    user = build(:user, name: "Madonna")
    assert_equal "M", user.initials
  end

  test "initials handles lowercase" do
    user = build(:user, name: "anna svensson")
    assert_equal "AS", user.initials
  end
end
