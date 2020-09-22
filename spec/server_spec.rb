require File.dirname(__FILE__) + '/acceptance_helper'

describe 'Pages that do not require login' do
  it "Visit home page" do
    visit '/'
    expect(page).to have_content("Ad-free, distraction-free, newsfeed.")
  end

  it "Visit terms of service" do
    visit '/terms-of-service'
    expect(page).to have_content("LinkBird")
  end

  it "Visit privacy" do
    visit '/terms-of-service'
    expect(page).to have_content("LinkBird")
  end


  it "Visit visit refresh page" do
    visit '/refresh'    
    expect(page).to have_content("LinkBird")
  end
end


describe 'Pages that do not require login' do
  it "Visit home page" do
    visit '/'
    expect(page).to have_content("Ad-free, distraction-free, newsfeed.")
  end
end

