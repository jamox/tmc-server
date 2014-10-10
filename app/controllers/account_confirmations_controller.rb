class AccountConfirmationsController < ApplicationController

  skip_authorization_check
  def confirm
    key = AccountConfirmationKey.where(code: params[:key]).first

    raise ActiveRecord::RecordNotFound.new('Invalid account activation code') if key.nil? || key.expired?
    @user = @key.user
    @user.activated = true
    @user.save!

    @key.delete

    flash[:notice] = "Account activated successfully, you may now login"
    redirect_to root_path
  end

  def resend
    user = User.where(id: params[:participant_id]).first
    AccountConfirmationMailer.confirmation_email(user, user.account_confirmation_key).deliver
  end

  def index
    @user = User.where(id: params[:participant_id]).first
  end
end
