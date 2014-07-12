class Permission < ActiveRecord::Base

  validates :user_id, :presence => true
  validates :course_id, :presence => true

  belongs_to :user
  belongs_to :course

  def self.add_permission(user, course)
    permission = Permission.where("user_id = ? and course_id = ?", user.id, course.id)
    unless permission.any?
      permission = Permission.create!(user: user, course: course)
    end
    permission
  end


  def self.has_access_to_course(user, course)
    Permission.where(user_id: user, course_id: course).any?
  end
end

