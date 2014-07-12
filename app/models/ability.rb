# CanCan ability definitions.
#
# See: https://github.com/ryanb/cancan/wiki/Defining-Abilities
class Ability
  include CanCan::Ability

  # About the nonstandard second session parameter: https://github.com/ryanb/cancan/issues/133
  def initialize(user, session)
    if user.administrator?
      can :manage, :all
      can :create, Course
      can :refresh, Course
      can :view, :participants_list
      can :rerun, Submission
      can :refresh_gdocs_spreadsheet, Course do |c|
        !c.spreadsheet_key.blank?
      end

      can :read_vm_log, Submission do |s|
        !s.vm_log.blank?
      end

      can :list_all_submissios, Course
      can :create_code_reviews, Course
      can :manage_feedback_answers, Course
    else
      can :read, :all

      can :create_code_reviews, Course do |c|
        Permission.has_access_to_course(user, c)
      end

      can :read_feedback_question, Course do |c|
        Permission.has_access_to_course(user, c)
      end

      can :read_feedback_question, Submission do |c|
        Permission.has_access_to_course(user, c)
      end

      can :read_feedback_answer, Course do |c|
        Permission.has_access_to_course(user, c)
      end

      can :read_feedback_answer, Submission do |c|
        Permission.has_access_to_course(user, c)
      end
      cannot :read, User
      cannot :read, :code_reviews
      cannot :read, :course_information
      can :read, User, :id => user.id
      can :create, User if SiteSetting.value(:enable_signup)

      cannot :read, Course
      can :read, Course do |c|
        c.visible_to?(user)
      end

      can :list_all_submissions, Course do |c|
        Permission.has_access_to_course(user, c)
      end

      can :create, Review do |r|
        Permission.has_access_to_course(user, r.submission.course)
      end
      can :view_all_feedback_answers, Course do |c|
        Permission.has_access_to_course(user, c)
      end

      can :update, Review do |r|
        Permission.has_access_to_course(user, r.submission.course) && r.reviewer_id == user.id
      end

      cannot :read, Exercise
      can :read, Exercise do |ex|
        ex.visible_to?(user)
      end
      can :download, Exercise do |ex|
        ex.downloadable_by?(user)
      end

      cannot :read, Submission
      can :read, Submission, :user_id => user.id

      can :read, Submission do |s|
        Permission.has_access_to_course(user, s.course)
      end

      can :create, Submission do |sub|
        sub.exercise.submittable_by?(user)
      end

      cannot :read, FeedbackAnswer
      can :create, FeedbackAnswer do |ans|
        ans.submission.user_id == user.id
      end

      cannot :read, Solution
      can :read, Solution do |sol|
        sol.visible_to?(user)
      end

      cannot :mark_as_read, Review
      can :mark_as_read, Review do |r|
        r.submission.user_id == user.id
      end
      cannot :mark_as_unread, Review
      can :mark_as_unread, Review do |r|
        r.submission.user_id == user.id
      end

      can :view_code_reviews, Course do |c|
        c.submissions.exists?(:user_id => user.id, :reviewed => true)
      end

      cannot :reply, FeedbackAnswer
      cannot :email, CourseNotification
    end
  end
end
