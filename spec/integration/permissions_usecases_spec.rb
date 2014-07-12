require 'spec_helper'

describe "Permissions system", :integration => true do
  include IntegrationTestActions

  before :each do
    repo_path = Dir.pwd + '/remote_repo'
    create_bare_repo(repo_path)
    @course = Course.create!(:name => 'mycourse', :source_backend => 'git', :source_url => repo_path)
    @repo = clone_course_repo(@course)
    @repo.copy_simple_exercise('MyExercise')
    @repo.add_commit_push

    @course.refresh

    @user = Factory.create(:user, :password => 'xooxer')

    visit '/'
    log_in_as(@user.login, 'xooxer')
    click_link 'mycourse'
  end

  # Yeah, kinda lame test
  it "should not affect users without any permissions" do
    page.should_not have_content('Refresh')
    page.should_not have_content('Source URL')
  end


  it "user with pershould not affect users without any permissions" do
    ex = FixtureExercise::SimpleExercise.new('MyExercise')
    ex.solve_all
    ex.make_zip

    click_link 'MyExercise'
    attach_file('Zipped project', 'MyExercise.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed
    page.should have_content('All tests successful')
    page.should have_content('Ok')

    visit '/'
    click_link 'mycourse'
    page.should_not have_content('No data available in table')
    log_out


    @other_user = Factory.create(:user,:login => "uuseri", :password => 'xooxer')

    log_in_as(@other_user.login, 'xooxer')

    page.should_not have_content('Refresh')
    page.should_not have_content('Source URL')
    page.should have_content('No data available in table') # Cannot see any submissions since has not made any and has no permissions

    click_link 'myexercise'
    page.should have_content('No submissions yet')

    log_out
    visit '/'
    click_link 'mycourse'

    @another_user = Factory.create(:user,:login => "uusuuseri", :password => 'xooxer')

    Permission.add_permission(@another_user, @course)
    log_in_as(@another_user.login, 'xooxer')

    page.should_not have_content('Refresh')
    page.should_not have_content('Source URL')

    page.should have_content('View points')
    page.should have_content('View code reviews')
    page.should have_content('View feedback')
    page.should_not have_content('Manage feedback questions')

    page.should_not have_content('No data available in table')
    page.should have_content(@user.login)    # See the other users submission
    page.should have_content('Not required') # For review
    click_link 'Details'
    page.should have_content('Test Results')
    page.should have_content('Files')

    click_link ' Exercise myexercise'
    page.should_not have_content('No submissions yet')
    page.should have_content(@user.login)    # See the other users submission
    page.should have_content('Not required') # For review

  end


end

