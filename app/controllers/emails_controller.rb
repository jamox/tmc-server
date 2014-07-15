
# Displays the raw list of participant e-mails, useful for mass-mailing scripts.
class EmailsController < ApplicationController

  def index
    authorize! :list_user_emails
    filter_params = params_starting_with('filter_', :all, :remove_prefix => true)
    filter_params['include_administrators'] = '1' # Always include administrators. Could make this exclude_administrators instead
    @emails = User.filter_by(filter_params).order(:email).map(&:email)
    respond_to do |format|
      format.text do
        render :text => @emails.join("\n")
      end
    end
  end

end
