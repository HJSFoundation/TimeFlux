class MonthReviewsController < ApplicationController
  
  before_filter :check_authentication, :check_parent_user
  
  def show
    @user = User.find(params[:user_id])
    @beginning_of_month = parse_or_create_date
    @period = Period.new(@user, @beginning_of_month.year, @beginning_of_month.month)
    @activities_summary = create_activity_summary(@user, @period)   
  end
  
  private
  
  def create_activity_summary(user,period)
    period.activities.sort.collect do |activity|
      { :name => activity.customer_project_name(50),
        :hours => activity.time_entries.for_user(user).between(period.start, period.end).sum(:hours) }
    end
  end

end