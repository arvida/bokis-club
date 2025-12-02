class Vote < ApplicationRecord
  belongs_to :club_book
  belongs_to :user

  validate :one_vote_per_club_voting_round
  validate :club_book_is_voting

  private

  def club_book_is_voting
    return if club_book.nil?
    return if club_book.status == "voting"

    errors.add(:club_book, :not_voting)
  end

  def one_vote_per_club_voting_round
    return if club_book.nil? || user.nil?

    club = club_book.club
    return if club.nil? || club.id.nil?

    existing_vote = Vote.joins(:club_book)
                        .where(user: user)
                        .where(club_books: { club_id: club.id, status: "voting" })
                        .where.not(id: id)
                        .exists?

    if existing_vote
      errors.add(:user_id, :already_voted)
    end
  end
end
