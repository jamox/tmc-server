class Permission < ActiveRecord::Base

  validates :user_id, :presence => true
  validates :course_id, :presence => true

  belongs_to :user
  belongs_to :course


  PERMISSION_IMPLICATION_MAP = {
    admin: [
      :apprentice,
      :create_course,  # cannot be given to apprentice as no context i.e. course cannot be given - or course should be nil
      :create_feedback_questions,
      :delete_feedback_questions,
      :delete_review,
      :dismiss_review,
      :list_all_participants, #cannot be given to individual users, only admins
      :list_reviewd_submissions,
      :list_user_emails,
      :manage_feedback_answers,
      :manage_permissions, # cannot be givrn to apprentice as no context, well easily - TODO
      :read_vm_log,
      :refresh_course,
      :reorder_feedback_questions,
      :reply_feedback_answer, # we dont really use this yet
      :rerun_submission,
      :show_administrators_in_points_list,
      :update_feedback_questions
    ],
    apprentice: [
      :create_code_reviews,
      :create_submission,
      :download_exercise,
      :list_all_submissions,
      :read_code_reviews,
      :read_course,
      :read_exercise,
      :read_feedback_answers,  # TODO WTF, whe not use manage_feedback_questions
      :read_feedback_questions,
      :read_solutions,
      :read_submission,
      :update_review,
      :view_expired_pastes,
      # :view_participant_details # TODO maybe we should implement this
      :view_participants_list
    ],
    student: [
      :create_feedback_answer,  #permission always for own submissions
      :mark_as_read, # Always for own reviews
      :mark_as_unread # Always for own reviews
    ]
  }.freeze

  def self.check!(user, course, type)
    type = type.to_sym unless type === Symbol
    users_permissions_for_course = Permission.where(user_id: user,course_id: course).first.permissions.split(",").map(&:to_sym)

    permission_in_permission_chain?(requested_permission, users_permissions_for_course)
  end

  def self.add_permission(user, course, permission_type)
    permission = Permission.where(user: user.id, course: course.id).first
    if permission
      perms = permission.permissions.split(",").sort.map(&:to_sym)
      perms << permission_type
      perms = perms.uniq.sort
      permission.permissions = perms.join(",")
      permission.save!
    else
      permission = Permission.create!(user: user, course: course, permission: permission_type)
    end
    permission
  end

  def self.remove_permission(user, course, permission_type)
    permission = Permission.where(user: user.id, course: course.id).first
    if permission
      perms = permission.permissions.split(",").sort.uniq
      perms.delete  permission_type
      perms = perms.uniq.sort
      permission.permissions = perms.join(",")
      permission.save!
    end
  end

  def self.permission_in_permission_chain?(requested_permission, users_permissions_for_course)
    self.find_path(requested_permission) do |permission|
      users_permissions_for_course.include? permission
    end
  end

  private
  def self.get_map
    PERMISSION_IMPLICATION_MAP
  end


  def self.has_access_to_course(user, course)
    Permission.where(user_id: user, course_id: course).any?
  end


  def self.find_path(start, visited = [], &is_destination)
    start = start.to_sym if start === Symbol
    return start if is_destination.call(start)
    possible_permissions = self.transpose[start]
    (possible_permissions - visited).each do |perm|
      result = find_path(perm, visited << start, &is_destination)
      return result if result
    end
  end

  def self.transpose
    @@transpose ||=
      PERMISSION_IMPLICATION_MAP.each_with_object({}) do |(k,v), acc|
      v.each_with_object(acc) do |k1, acc1|
        acc1[k1] ||= []
        acc1[k1] << k
        acc1
      end
      acc
      end.freeze
  end
end

