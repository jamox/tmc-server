class Permission < ActiveRecord::Base

  validates :user_id, :presence => true
  validates :course_id, :presence => true

  belongs_to :user
  belongs_to :course


  PERMISSION_IMPLICATION_MAP = {
    admin: [
      :apprentice, #okish
      :create_course, # Vithin context of course, this canoot be useed for non admin users
      :create_feedback_questions, # ok
      :delete_feedback_questions, # ok
      :delete_review, # TODO
      :dismiss_review, # TODO
      :list_all_participants, #cannot be given to individual users, only admins
      :list_user_emails, # TODO
      :manage_feedback_questions, # TODO
      :manage_permissions, # TODO # cannot be givrn to apprentice as no context, well easily - TODO
      :read_vm_log, # TODO
      :refresh_course, # TODO
      :reorder_feedback_questions, # TODO
      :reply_feedback_answer, # TODO # we dont really use this yet
      :rerun_submission, # TODO
      :show_administrators_in_points_list, # TODO
      :update_feedback_questions # ok
    ],
    apprentice: [
      :create_code_reviews, #ok
      :create_submission_after_deadline, # not yet implemented (i think)
      :download_exercise, # not yet implemented
      :list_all_submissions, #ok
      :list_reviewd_submissions, #ok
      :read_code_reviews, #ok . vaaditaan jotta toisen kirjoittaman code reviewn voi nähdä
      :read_course, #ok
      :read_exercise, #ok
      :read_feedback_answers, # ok
      :read_feedback_questions, # ok, is really dependent to read_feedback_answers
      :read_solutions, #ok
      :read_submission, #ok
      :update_review, #ok
      :view_expired_pastes, # TODO not yet implemented
      # :view_participant_details # TODO maybe we should implement this
      :view_participants_list # TODO not yet implemented
    ],
    student: [
      :create_feedback_answer,  #permission always for own submissions
      :create_submission, # for open courses, not enforced yet
      :mark_as_read, # Always for own reviews
      :mark_as_unread # Always for own reviews
    ]
  }.freeze

  def self.check!(user, course, requested_permission)
    requested_permission = requested_permission.to_sym unless requested_permission === Symbol
    permission = Permission.where(user_id: user,course_id: course).first
    return false if permission.nil?
    users_permissions_for_course = permission.permissions.split(",").map(&:to_sym)

    result = permission_in_permission_chain?(requested_permission, users_permissions_for_course)
  end

  def self.add_permission(user, course, permission_type)
    permission = Permission.where(user_id: user.id, course_id: course.id).first
    if permission
      perms = permission.permissions.split(",").sort.map(&:to_sym)
      perms << permission_type
      perms = perms.uniq.sort
      permission.permissions = perms.join(",")
      permission.save!
    else
      permission = Permission.create!(user_id: user.id, course_id: course.id, permissions: permission_type)
    end
    permission
  end

  def self.remove_permission(user, course, permission_type)
    permission = Permission.where(user: user, course: course).first
    if permission
      perms = permission.permissions.split(",").sort.uniq
      perms.delete  permission_type
      perms = perms.uniq.sort
      permission.permissions = perms.join(",")
      permission.save!
    end
  end

  def self.permission_in_permission_chain?(requested_permission, users_permissions_for_course)
    return_value = false
    self.find_path(requested_permission) do |permission|
      value = users_permissions_for_course.include? permission
      return_value = permission if value
    end
    return_value
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
    res = is_destination.call(start)
    return res if res
    possible_permissions = self.transpose[start] || []
    (possible_permissions - visited).each do |perm|
      result = find_path(perm, visited << start, &is_destination)
      p RESULT: result
      return result if result
    end
  end

  def self.transpose
    @transpose ||=
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

