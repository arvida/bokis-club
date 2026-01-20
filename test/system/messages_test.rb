require "application_system_test_case"

class MessagesTest < ApplicationSystemTestCase
  include Passwordless::TestHelpers

  setup do
    @user = create(:user, name: "Anna")
    @club = create(:club)
    create(:membership, user: @user, club: @club)
  end

  test "member can view messages page" do
    passwordless_sign_in(@user)
    visit club_messages_path(@club)

    assert_selector "h1", text: "Diskussion"
    assert_text "Inga meddelanden ännu"
  end

  test "member can create a message" do
    passwordless_sign_in(@user)
    visit club_messages_path(@club)

    find("button[aria-label='Nytt meddelande']").click

    within "#message-modal" do
      fill_in placeholder: "Skriv ditt meddelande...", with: "Hej alla! Vad tyckte ni om boken?"
      click_button "Skicka"
    end

    assert_text "Hej alla! Vad tyckte ni om boken?"
    assert_text "Anna"
  end

  test "member can reply to a message" do
    message = create(:message, club: @club, user: @user, content: "Första meddelandet")

    passwordless_sign_in(@user)
    visit club_messages_path(@club)

    assert_text "Första meddelandet"
    click_button "Svara"

    fill_in placeholder: "Skriv ett svar...", with: "Bra fråga!"
    click_button "Svara"

    assert_text "Bra fråga!"
  end

  test "author can delete their message" do
    message = create(:message, club: @club, user: @user, content: "Mitt meddelande")

    passwordless_sign_in(@user)
    visit club_messages_path(@club)

    assert_text "Mitt meddelande"

    within "##{dom_id(message)}" do
      find("[data-dropdown-target='button']").click
      accept_confirm do
        click_button "Ta bort"
      end
    end

    assert_no_text "Mitt meddelande"
  end

  test "can access messages from club page" do
    passwordless_sign_in(@user)
    visit club_path(@club)

    click_link "Diskussion"

    assert_current_path club_messages_path(@club)
  end

  test "mentions are highlighted" do
    other_user = create(:user, name: "Erik")
    create(:membership, user: other_user, club: @club)

    message = create(:message, club: @club, user: @user, content: "Hej @Erik! Vad tycker du?")

    passwordless_sign_in(@user)
    visit club_messages_path(@club)

    assert_selector ".text-vermillion", text: "@Erik"
  end
end
