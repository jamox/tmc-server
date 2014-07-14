# Shows an admin the list of submissions that have already been reviewed.
class ReviewedSubmissionsController < ApplicationController

  def index
    @course = Course.find(params[:course_id])
    authorize! :list_reviewd_submissions, @course
    add_course_breadcrumb
    add_breadcrumb "Reviewed submissions", course_reviewed_submissions_path(@course)

    @submissions = @course.submissions.
      where(:reviewed => true).
      includes(:reviews => :reviewer).
      includes(:user).
      order('created_at DESC')
  end
end
