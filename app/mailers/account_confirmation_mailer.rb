class AccountConfirmationMailer < ActionMailer::Base
  def confirmation_email(user, key)
    settings = SiteSetting.value('emails')

    subject = '[TMC] Account Confirmation'
    @url = settings['baseurl'].sub(/\/+$/, '') + '/account_confirmations/' + key.code
    mail(:from => settings['from'], :to => user.email, :subject => subject)
  end
end
