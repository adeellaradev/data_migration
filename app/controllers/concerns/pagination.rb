module Pagination
  PER_PAGE = 50

  extend ActiveSupport::Concern

  included do
    helper_method :current_page, :total_pages
  end

  private
    def paginate(scope)
      @total_pages = [ (scope.count / PER_PAGE.to_f).ceil, 1 ].max
      @current_page = params[:page].to_i.clamp(1, @total_pages)
      scope.limit(PER_PAGE).offset((@current_page - 1) * PER_PAGE)
    end

    def current_page
      @current_page || 1
    end

    def total_pages
      @total_pages || 1
    end
end
