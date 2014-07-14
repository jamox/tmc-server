
# Handles the feedback question editing UI.
#
# TODO: While this is nice, I think feedback questions should live in a conf file in the repo so that the entire course is defined by the repo.
class FeedbackQuestionsController < ApplicationController
  before_filter :get_course

  def index
    add_course_breadcrumb
    add_breadcrumb 'Feedback questions'

    @questions = @course.feedback_questions.order(:position)
    authorize! :read_feedback_questions, @questions
  end

  def new
    @question = FeedbackQuestion.new(:course => @course)
    authorize! :create_feedback_questions, @question
  end

  def create
    @question = FeedbackQuestion.new(params[:feedback_question])
    @question.course = @course
    authorize! :create_feedback_questions, @question

    fix_question_kind(@question)

    if @question.save
      flash[:success] = 'Question created.'
      redirect_to course_feedback_questions_path(@question.course)
    else
      flash.now[:error] = 'Failed to create question.'
      render :new
    end
  end

  def show
    @question = FeedbackQuestion.find(params[:id])
    @course = @question.course
    authorize! :read_question,  @question
    authorize! :read_course,  @course
  end

  def update
    @question = FeedbackQuestion.find(params[:id])
    @course = @question.course
    authorize! :read_course,  @course
    authorize! :update_feedback_questions, @question

    @question.question = params[:feedback_question][:question]
    @question.title = params[:feedback_question][:title]

    if @question.save
      flash[:success] = 'Question updated.'
      redirect_to course_feedback_questions_path(@question.course)
    else
      flash.now[:error] = 'Failed to update question.'
      render :new
    end
  end

  def destroy
    @question = FeedbackQuestion.find(params[:id])
    @course = @question.course
    authorize! :read_course,  @course
    authorize! :delete_feedback_questions, @question

    begin
      @question.destroy
      flash[:success] = 'Question deleted.'
      redirect_to course_feedback_questions_path(@course)
    rescue
      flash[:error] = "Failed to delete question: #{$!}"
      redirect_to course_feedback_questions_path(@course)
    end
  end

private
  def get_course
    @course = Course.find(params[:course_id]) if params[:course_id]
    authorize! :read_course, @course
  end

  def fix_question_kind(question)
    if question.kind == 'intrange'
      question.kind += "[#{params[:intrange_min]}..#{params[:intrange_max]}]"
    end
  end
end
