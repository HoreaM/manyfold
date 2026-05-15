require "rails_helper"

# root GET    /                                                                       home#index

RSpec.describe "Home" do
  context "when signed out" do
    it "needs testing when multiuser is enabled"
  end

  context "when signed in", :after_first_run, :as_member do
    describe "GET /dashboard" do
      it "shows the dashboard" do
        get "/dashboard"
        expect(response).to have_http_status(:success)
      end
    end
  end
end
