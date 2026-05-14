require "rails_helper"

RSpec.describe "First setup" do
  [:singleuser, :multiuser].each do |mode|
    context "when in #{mode} mode", mode do
      context "when signed out" do
        it "redirects to sign in" do
          get "/"
          expect(response).to redirect_to("/users/sign_in")
        end

        it "automatically signs in and redirects to user edit page" do
          get "/users/sign_in"
          follow_redirect!
          expect(response).to redirect_to("/users/edit")
        end
      end

      context "when signed in as new admin", :as_administrator do
        [ # rubocop:disable Performance/CollectionLiteralInLoop
          "/",
          "/dashboard",
          "/models",
          "/models/new",
          "/imports/new",
          "/creators",
          "/creators/new",
          "/collections",
          "/collections/new"
        ].each do |path|
          it "redirects from #{path} to library creation" do
            get path
            expect(response).to redirect_to(new_library_path)
          end
        end
      end
    end
  end
end
