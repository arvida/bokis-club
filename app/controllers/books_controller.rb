class BooksController < ApplicationController
  before_action :require_user!

  def search
    @query = params[:q].to_s.strip
    @results = search_books(@query)
  end

  private

  def search_books(query)
    return [] if query.blank?

    GoogleBooksService.new.search(query)
  end
end
