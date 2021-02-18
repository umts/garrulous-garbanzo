# frozen_string_literal: true

require 'assignments_ics'

class AssignmentsController < ApplicationController
  before_action :find_assignment, only: %i[destroy edit update]
  before_action :require_admin_in_roster, only: %i[generate_rotation
                                                   rotation_generator]
  skip_before_action :set_current_user, :set_roster, only: :feed

  def create
    ass_params = params.require(:assignment)
                       .permit :start_date, :end_date,
                               :user_id, :roster_id
    assignment = Assignment.new ass_params
    viewed_date = session.delete(:last_viewed_month) || assignment.start_date
    unless @current_user.admin_in?(@roster) || taking_ownership?(ass_params)
      # ... and return is correct here
      require_taking_ownership and return
    end

    if assignment.save
      confirm_change(assignment)
      assignment.notify :owner, of: :new_assignment, by: @current_user
      redirect_to roster_assignments_path(@roster, date: viewed_date)
    else report_errors(assignment, fallback_location: roster_assignments_path)
    end
  end

  def destroy
    @assignment.notify :owner, of: :deleted_assignment, by: @current_user
    @assignment.destroy
    confirm_change(@assignment)
    viewed_date = session.delete(:last_viewed_month) || @month_date
    redirect_to roster_assignments_path(@roster, date: viewed_date)
  end

  def edit
    @users = @roster.users.active.order :last_name
  end

  def generate_rotation
    start_date = Date.parse params.require(:start_date)
    end_date = Date.parse params.require(:end_date)
    user_ids = params.require :user_ids
    start_user = params.require :starting_user_id
    unless user_ids.include? start_user
      flash[:errors] = 'The starting user must be in the rotation.'
      # ... and return is correct here
      redirect_back(fallback_location:
                    roster_assignments_path(@roster)) and return
    end
    @roster.generate_assignments(user_ids, start_date,
                                 end_date, start_user).each do |assignment|
      assignment.notify :owner, of: :new_assignment, by: @current_user
    end
    flash[:message] = 'Rotation has been generated.'
    redirect_to roster_assignments_path(@roster, date: start_date)
  end

  def index
    respond_to do |format|
      format.html do
        setup_calendar_view
        @assignments = @current_user.assignments.in(@roster)
                                    .upcoming
                                    .order :start_date
        @current_assignment = @roster.assignments.current
        @switchover_hour = CONFIG[:switchover_hour]
        @fallback_user = @roster.fallback_user
      end
      format.ics { render_ics_feed }
    end
  end

  def new
    @start_date = Date.parse params.require(:date)
    @end_date = @start_date + 6.days
    @users = @roster.users.active.order :last_name
  end

  def rotation_generator
    @users = @roster.users.active.order :last_name
    @start_date = Assignment.next_rotation_start_date
  end

  def update
    ass_params = params.require(:assignment)
                       .permit :start_date, :end_date, :user_id
    viewed_date = session.delete(:last_viewed_month) || @assignment.start_date
    unless @current_user.admin_in?(@roster) || taking_ownership?(ass_params)
      # ... and return is correct here
      require_taking_ownership and return
    end

    @previous_owner = @assignment.user
    if @assignment.update ass_params
      confirm_change(@assignment)
      notify_appropriate_users
      redirect_to roster_assignments_path(@roster, date: viewed_date)
    else report_errors(@assignment, fallback_location: roster_assignments_path)
    end
  end

  def feed
    user = User.find_by(calendar_access_token: params[:token])
    roster = params[:roster].titleize.downcase
    @roster = Roster.where('lower(name) = ?', roster).first
    if user.nil?
      render file: 'public/404.html', layout: false, status: :not_found
    elsif params[:format] == 'ics' && user.rosters.include?(@roster)
      render_ics_feed
    else
      render file: 'public/401.html', layout: false, status: :unauthorized
    end
  end

  private

  def find_assignment
    @assignment = Assignment.includes(:user).find(params.require(:id))
  end

  # If the user's being changed, we effectively inform of the change
  # by telling the previous owner they're not responsible anymore,
  # and telling the new owner that they're newly responsible now.
  def notify_appropriate_users
    if @assignment.user == @previous_owner
      @assignment.notify :owner, of: :changed_assignment, by: @current_user
    else
      @assignment.notify :owner, of: :new_assignment, by: @current_user
      @assignment.notify @previous_owner, of: :deleted_assignment,
                                          by: @current_user
    end
  end

  def render_ics_feed
    ics = AssignmentsIcs.new(@roster.assignments)
    render plain: ics.output, content_type: 'text/calendar'
  end

  def require_taking_ownership
    flash[:errors] = [<<-TEXT]
      You may only edit or create assignments such that you become on call.
      The intended new owner of this assignment must take it themselves.
      Or, a roster administrator can perform this change for you.
    TEXT
    redirect_back fallback_location: roster_assignments_path(@roster)
  end

  def setup_calendar_view
    @month_date = if params[:date].present?
                    Date.parse params[:date]
                  else Time.zone.today
                  end.beginning_of_month
    session[:last_viewed_month] = @month_date
    start_date = @month_date.beginning_of_week(:sunday)
    end_date = @month_date.end_of_month.end_of_week(:sunday)
    @weeks = (start_date..end_date).each_slice(7)
  end

  def taking_ownership?(assignment_params)
    assignment_params.require(:user_id) == @current_user.id.to_s
  end
end
