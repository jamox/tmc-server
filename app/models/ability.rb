# CanCan ability definitions.
#
# See: https://github.com/ryanb/cancan/wiki/Defining-Abilities
class Ability
  include CanCan::Ability

  # About the nonstandard second session parameter: https://github.com/ryanb/cancan/issues/133
  def initialize(user, session)
    if user.administrator?
      can :manage, :all
      can :create_course, Course
      can :refresh, Course
      can :refresh_course, Course
      can :view, :participants_list
      can :rerun_submission, Submission
      can :refresh_gdocs_spreadsheet, Course do |c|
        !c.spreadsheet_key.blank?
      end

      can :read_vm_log, Submission do |s|
        !s.vm_log.blank?
      end

      can :manage_permissions
      can :manage_permissions, Course
      can :list_all_submissios, Course
      can :create_code_reviews, Course
      can :manage_feedback_answers, Course
      can :create_submission, Course
      can :download_exercise, Course
      can :list_all_submissions, Course
      can :read_submission, Course
      can :read_exercise, Course
      can :read_exercise, Exercise
      can :read_feedback_answers, Course
      can :read_feedback_questions, Course
      can :update_review, Review
      can :view_participants_list, Course
      can :read_solution, Solution
      can :read_code_reviews, Course
      can :read_course, Course
      can :list_user_emails
      can :create_feedback_questions
      can :update_feedback_questions, FeedbackQuestions
      can :delete_feedback_questions, FeedbackQuestion
      can :list_all_participants
      can :show_administrators_in_points_list, Course
      can :show_administrators_in_points_list, Course
      can :list_reviewd_submissions, Course

      can :delete_review, Review

      can :list_reviewd_submissions, Course
    else
      can :read, :all

      # TODO not used
      can :manage_permissions, Course do |c|
        Permission.check!(user, c, :manage_permissions)
      end

      can :delete_review, Review do |r|
        Permission.check!(user, r.submission.course, :delete_review)
      end

      can :rerun_submission, Submission do |s|
        Permission.check!(user, s.exercise.course, :rerun_submission)
      end

      can :view_expired_pastes, Submission do |s|
        Permission.check!(user, s.exercise.course, :view_expired_pastes)
      end

      can :dismiss_review, Submission do |s|
        Permission.check!(user, s.exercise.course, :dismiss_review)
      end

      can :list_reviewd_submissions, Course do |c|
        Permission.check!(user, c, :list_reviewd_submissions)
      end
      can :show_administrators_in_points_list, Course do |c|
        Permission.check!(user, c,  :show_administrators_in_points_list)
      end

      can :read_vm_log, Submission do |s|
        !s.vm_log.blank? && Permission.check!(user, s.course, :read_vm_log)
      end

      can :show_administrators_in_points_list, Course do |c|
        Permission.check!(user, c, :show_administrators_in_points_list)
      end

      # TODO pit'sk; t'' muutenkin sallia, koska kai ne jotain kursseja saa n'hd' :D
      can :read_course, Course do |c|
        Permission.check!(user, c, :read_course)
      end

      can :view_participants_list, Course do ||
        Permission.check!(user, c, :view_participants_list)
      end
      can :refresh_course, Course do |c|
        Permission.check!(user, c, :refresh_course)
      end

      # TODO change references
      can :create, Review do |r|
        Permission.has_access_to_course(user, r.submission.course)
      end
      can :create_code_reviews, Course do |c|
        Permission.check!(user, c, :create_code_reviews)
      end


      can :read_feedback_questions, Course do |c|
        Permission.check!(user, c, :read_feedback_questions)
      end

      can :read_feedback_questions, Submission do |s|
        Permission.check!(user, s, :read_feedback_questions)
      end

      can :manage_feedback_answers, Course do |c|
        Permission.check!(user, c, :manage_feedback_answers)
      end

      can :read_feedback_answers, Submission do |s|
        Permission.check!(user, s.exercise.course, :read_feedback_answers)
      end
      can :read_feedback_answers, Course do |c|
        Permission.check!(user, c, :read_feedback_answers)
      end
      cannot :read, User


      # TODO poista viitteet
      cannot :read, :course_information

      can:read_course_information, Course do |c|
        Permission.check!(user, c, :read_course_information)
      end

      can :read, User, :id => user.id
      can :create_user, User if SiteSetting.value(:enable_signup)

      # TODO kato miten kurssilistauksen teko pitas tehda
      cannot :read, Course

      # TODO maybe change to permissions check?
      can :read, Course do |c|
        c.visible_to?(user)
      end

      can :list_all_submissions, Course do |c|
        Permission.check!(user, c, :list_all_submissions)
      end



      # TODO remove, korvaa: read_feedback_answers
      can :view_all_feedback_answers, Course do |c|
        raise "muuta"
      end

      # TODO remove
      can :update, Review do |r|
        Permission.check!(user, r.submission.course) && r.reviewer_id == user.id
      end

      # Non admin cannot edit other users reviews
      can :update_review, Review do |r|
        Permission.check!(user, r.submission.course) && r.reviewer_id == user.id
      end

      cannot :read, Exercise

      # TODO remove
      can :read, Exercise do |ex|
        ex.visible_to?(user)
      end

      can :read_exercise, Course do |c|
        Permission.check!(user, c, :read_exercise)
      en_feedback_answerd

      can :read_exercise, Exercise do |e|
        Permission.check!(user, e.course, :read_exercise)
      end

      # TODO remove
      can :download, Exercise do |ex|
        ex.downloadable_by?(user)
      end

      can :download_exercise do |c|
        ex.downloadable_by?(user) || Permission.check!(user, c, :download_exercise)
      end

      # TODO remove
      cannot :read, Submission


      can :read, Submission, :user_id => user.id

      can :read_submission, Course do |c|
        Permission.check!(user, c, :read_submission)
      end

      can :create, Submission do |sub|
        sub.exercise.submittable_by?(user)
      end
      can :create_submission, Submission do |s|
        sub.exercise.submittable_by?(user) || Permission.check!(user, s.course, :create_submission)
      end

      # TODO remove
      cannot :read, FeedbackAnswer
      # TODO remove
      can :create_feedback_answer, FeedbackAnswer do |ans|
        ans.submission.user_id == user.id
      end

      # TODO remove
      cannot :read, Solution
      # TODO remove
      can :read, Solution do |sol|
        sol.visible_to?(user)
      end

      # TODO rename (pluralized)
      can :read_solutions, Solution do |s|
        # TODO, how to find out course!!!!
        sol.visible_to?(user) || Permission.check!(user, s, :read_solutions)
      end

      cannot :mark_as_read, Review

      can :mark_as_read, Review do |r|
        r.submission.user_id == user.id
      end
      cannot :mark_as_unread, Review
      can :mark_as_unread, Review do |r|
        r.submission.user_id == user.id
      end

      can :read_code_reviews, Course do |c|
        c.submissions.exists?(:user_id => user.id, :reviewed => true) || Permission.check!(user, c, :read_code_reviews)
      end
      # TODO poista viitteet
      cannot :read, :code_reviews

      #can :read_code_reviews, Course do |c|
      #  Permission.check!(user, c, :read_code_reviews)
      #end

      can :create_feedback_questions, FeedbackQuestions do |f|
        Permission.check!(user, f.course, :create_feedback_questions)
      end
      can :update_feedback_questions, FeedbackQuestions do |f|
        Permission.check!(user, f.course, :update_feedback_questions)
      end

      can :delete_feedback_questions, FeedbackQuestion do |f|
        Permission.check!(user, f.course, :delete_feedback_questions)
      end
      # TODO ignore for noe
      cannot :reply_feedback_answer, FeedbackAnswer
      cannot :email, CourseNotification
    end
  end
end
