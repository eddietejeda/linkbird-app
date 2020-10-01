require File.dirname(__FILE__) + '/acceptance_helper'

DatabaseCleaner.strategy = :truncation
DatabaseCleaner.clean

describe 'Visit public pages' do
  it "Visit home page" do
    visit '/'
    expect(page).to have_content("Get a reading list from your Twitter feed.")
  end

  it "Visit terms of service page" do
    visit '/terms-of-service'
    expect(page).to have_content("Terms of Service")
  end

  it "Visit privacy page" do
    visit '/terms-of-service'
    expect(page).to have_content("Privacy")
  end
end


#
#
# include SpecTestHelper
#
# describe 'Visit logged in pages' do
#
#
#   let(:user) do
#     FactoryBot.create(:user) do |user|
#       FactoryBot.create_list(:tweet, 5, user: user)
#     end
#   end
#
#   before do
#     user = User.first
#     request.session[:uid] = user.uid
#     request.cookies[:cookie_key] = SecureRandom.uuid
#
#     user_secrets = {}
#     user_secrets['access_token'] = SecureRandom.uuid
#     user_secrets['access_token_secret'] = SecureRandom.uuid
#
#     new_cookie = {
#       public_id: request.cookies[:cookie_key].hash.abs,
#       cookie_key: request.cookies[:cookie_key],
#       last_login: DateTime.now,
#       browser: request.env['HTTP_USER_AGENT']
#     }
#     user.cookie_keys = add_or_update_active_cookies(user.cookie_keys, new_cookie)
#     user.save!
#   end
#
#
#   it "Visit home page" do
#     visit '/'
#     expect(page).to have_content("Get a reading list from your Twitter feed.")
#   end
#
#   it "Visit terms of service page" do
#     visit '/terms-of-service'
#     expect(page).to have_content("Terms of Service")
#   end
#
#   it "Visit privacy page" do
#     visit '/terms-of-service'
#     expect(page).to have_content("Privacy")
#   end
# end
#
