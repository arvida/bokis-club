class ClubBooksController < ApplicationController
  before_action :require_user!
  before_action :set_club
  before_action :require_membership!
  before_action :require_admin!, except: [ :index, :show, :suggest, :vote, :archive ]
  before_action :set_club_book, only: [ :show, :set_reading, :destroy ]

  def index
    @suggested_books = @club.suggested_books.includes(:book, :suggested_by)
  end

  def show
  end

  def new
    @club_book = @club.club_books.new
  end

  def create
    book = find_or_create_book
    return redirect_to new_club_club_book_path(@club), alert: t("flash.club_books.book_not_found") unless book

    if params[:queue_next]
      if @club.next_club_book
        return redirect_to new_club_club_book_path(@club), alert: t("flash.club_books.has_next_book")
      end
      @club_book = @club.club_books.create!(book: book, status: "next", suggested_by: current_user)
      redirect_to club_path(@club), notice: t("flash.club_books.queued", title: book.title)
    else
      ClubBook.transaction do
        complete_current_book
        @club_book = @club.club_books.create!(book: book, status: "reading", suggested_by: current_user)
      end
      redirect_to club_path(@club), notice: t("flash.club_books.created", title: book.title)
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_club_club_book_path(@club), alert: e.message
  end

  def set_reading
    complete_current_book
    @club_book.update!(status: "reading")

    redirect_to club_path(@club), notice: t("flash.club_books.created", title: @club_book.book.title)
  end

  def destroy
    @club_book.soft_delete!
    redirect_to club_path(@club), notice: t("flash.club_books.removed")
  end

  def suggest
    if request.get? || request.head?
      @club_book = @club.club_books.new
      render :suggest
    else
      create_suggestion
    end
  end

  def start_voting
    if @club.next_club_book
      return redirect_to club_path(@club), alert: t("flash.club_books.has_next_book")
    end

    suggestions = @club.suggested_books

    if suggestions.count < 2
      return redirect_to club_club_books_path(@club), alert: t("flash.club_books.not_enough_suggestions")
    end

    deadline = if params[:voting_deadline].present?
                 parsed = Time.zone.parse(params[:voting_deadline])
                 if parsed.nil?
                   return redirect_to club_club_books_path(@club), alert: t("flash.club_books.invalid_deadline")
                 end
                 if parsed <= Time.current
                   return redirect_to club_club_books_path(@club), alert: t("flash.club_books.deadline_must_be_future")
                 end
                 parsed
    else
                 7.days.from_now
    end

    @club.update!(voting_deadline: deadline)
    suggestions.update_all(status: "voting")
    redirect_to vote_club_club_books_path(@club), notice: t("flash.club_books.voting_started")
  end

  def vote
    @voting_books = @club.voting_books.includes(:book, :votes)
    @suggestions_count = @club.suggested_books.count
    @user_vote = Vote.joins(:club_book)
                     .includes(club_book: :book)
                     .where(user: current_user)
                     .where(club_books: { club_id: @club.id, status: "voting" })
                     .first
    @has_voted = @user_vote.present?

    if request.post?
      if @club.voting_deadline_passed?
        return redirect_to vote_club_club_books_path(@club), alert: t("flash.club_books.voting_deadline_passed")
      end

      cast_vote unless @has_voted
    end
  end

  def end_voting
    winner = nil

    ClubBook.transaction do
      voting_books = @club.club_books.voting.lock("FOR UPDATE").includes(:votes).to_a

      if voting_books.empty?
        return redirect_to club_club_books_path(@club), alert: t("flash.club_books.no_voting")
      end

      winner = select_winner(voting_books)
      winner.update!(status: "next")

      ClubBook.where(id: voting_books.map(&:id)).where.not(id: winner.id).update_all(status: "suggested")
      Vote.where(club_book_id: voting_books.map(&:id)).delete_all
      @club.clear_voting_deadline!
    end

    redirect_to club_path(@club), notice: t("flash.club_books.voting_ended", title: winner.book.title)
  end

  def archive
    @completed_books = @club.completed_books.includes(:book)
  end

  def start_next_book
    next_club_book = @club.next_club_book

    unless next_club_book
      return redirect_to club_path(@club), alert: t("flash.club_books.no_next_book")
    end

    ClubBook.transaction do
      complete_current_book
      next_club_book.update!(status: "reading")
    end

    redirect_to club_path(@club), notice: t("flash.club_books.started_reading", title: next_club_book.book.title)
  end

  def cancel_next_book
    next_club_book = @club.next_club_book

    unless next_club_book
      return redirect_to club_path(@club), alert: t("flash.club_books.no_next_book")
    end

    next_club_book.update!(status: "suggested")
    redirect_to club_path(@club), notice: t("flash.club_books.next_cancelled")
  end

  def mark_complete
    current = @club.current_club_book

    unless current
      return redirect_to club_path(@club), alert: t("flash.club_books.no_current_book")
    end

    current.update!(status: "completed")
    redirect_to club_path(@club), notice: t("flash.club_books.marked_complete", title: current.book.title)
  end

  private

  def create_suggestion
    book = find_or_create_book
    return redirect_to suggest_club_club_books_path(@club), alert: t("flash.club_books.book_not_found") unless book

    @club_book = @club.club_books.create!(
      book: book,
      status: "suggested",
      suggested_by: current_user,
      notes: params[:notes]
    )

    redirect_to club_club_books_path(@club), notice: t("flash.club_books.suggested")
  rescue ActiveRecord::RecordInvalid => e
    redirect_to suggest_club_club_books_path(@club), alert: e.message
  end

  def set_club
    @club = Club.active.find(params[:club_id])
  end

  def set_club_book
    @club_book = @club.club_books.find(params[:id])
  end

  def require_membership!
    return if @club.member?(current_user)

    redirect_to club_path(@club), alert: t("flash.members.not_member")
  end

  def require_admin!
    return if @club.admin?(current_user)

    redirect_to club_path(@club), alert: t("flash.members.not_admin")
  end

  def find_or_create_book
    if params[:google_books_id].present?
      GoogleBooksService.new.find_or_create_book(params[:google_books_id])
    elsif params[:book].present?
      create_manual_book
    end
  end

  def create_manual_book
    book_params = params.require(:book).permit(:title, :description, :page_count, :isbn, :authors_string)
    authors = book_params.delete(:authors_string).to_s.split(",").map(&:strip).reject(&:blank?)

    Book.create!(book_params.merge(authors: authors))
  end

  def complete_current_book
    current = @club.current_club_book
    current&.update!(status: "completed")
  end

  def select_winner(voting_books)
    max_votes = voting_books.map(&:vote_count).max
    top_books = voting_books.select { |cb| cb.vote_count == max_votes }
    top_books.sample
  end

  def cast_vote
    club_book = @club.club_books.find(params[:club_book_id])
    Vote.create!(club_book: club_book, user: current_user)
    redirect_to vote_club_club_books_path(@club), notice: t("flash.club_books.vote_cast")
  rescue ActiveRecord::RecordInvalid
    redirect_to vote_club_club_books_path(@club), alert: t("flash.club_books.already_voted")
  end
end
