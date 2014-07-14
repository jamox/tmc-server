# Handles replying to a feedback answer by e-mail.
class FeedbackRepliesController < ApplicationController
  def create
    authorize! :reply_feedback_answer, FeedbackAnswer

    answer = FeedbackAnswer.find(params["answer_id"])
    answer.reply_to_feedback_answers.create(:from => current_user.email, :body => params["body"])

    FeedbackReplyMailer.feedback_email(
      current_user.email,
      params["email"],
      params["body"],
      answer.exercise_name
    ).deliver

    redirect_to :back, :notice => "Reply to a review was mailed"
  end
end
