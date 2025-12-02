require "test_helper"

class VoteTest < ActiveSupport::TestCase
  test "valid vote with required attributes" do
    vote = build(:vote)
    assert vote.valid?
  end

  test "club_book is required" do
    vote = build(:vote, club_book: nil)
    assert_not vote.valid?
  end

  test "user is required" do
    vote = build(:vote, user: nil)
    assert_not vote.valid?
  end

  test "user can only vote once per club voting round" do
    club = create(:club)
    user = create(:user)
    club_book1 = create(:club_book, club: club, status: "voting")
    club_book2 = create(:club_book, club: club, status: "voting")

    create(:vote, club_book: club_book1, user: user)
    duplicate = build(:vote, club_book: club_book2, user: user)

    assert_not duplicate.valid?
  end

  test "user can vote in different clubs" do
    user = create(:user)
    club1 = create(:club)
    club2 = create(:club)
    club_book1 = create(:club_book, club: club1, status: "voting")
    club_book2 = create(:club_book, club: club2, status: "voting")

    create(:vote, club_book: club_book1, user: user)
    vote2 = build(:vote, club_book: club_book2, user: user)

    assert vote2.valid?
  end

  test "belongs to club_book" do
    club_book = create(:club_book, status: "voting")
    vote = create(:vote, club_book: club_book)

    assert_equal club_book, vote.club_book
  end

  test "belongs to user" do
    user = create(:user)
    vote = create(:vote, user: user)

    assert_equal user, vote.user
  end

  test "club_book has many votes" do
    club_book = create(:club_book, status: "voting")
    user1 = create(:user)
    user2 = create(:user)
    vote1 = create(:vote, club_book: club_book, user: user1)
    vote2 = create(:vote, club_book: club_book, user: user2)

    assert_includes club_book.votes, vote1
    assert_includes club_book.votes, vote2
  end

  test "vote_count returns number of votes" do
    club_book = create(:club_book, status: "voting")
    user1 = create(:user)
    user2 = create(:user)
    create(:vote, club_book: club_book, user: user1)
    create(:vote, club_book: club_book, user: user2)

    assert_equal 2, club_book.vote_count
  end

  test "cannot vote on non-voting book" do
    club_book = create(:club_book, status: "suggested")
    vote = build(:vote, club_book: club_book)

    assert_not vote.valid?
    assert vote.errors[:club_book].any?
  end
end
