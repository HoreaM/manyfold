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

        context "when entering user details" do
          let(:password) { SecureRandom.hex(64) }
          let(:params) {
            {
              user: {
                email: "test@example.com",
                username: "admin",
                password: password,
                password_confirmation: password
              }
            }
          }

          before do
            get "/users/sign_in"
            follow_redirect!
            follow_redirect!
          end

          it "sets password" do
            expect { patch "/users", params: params }.to change { User.first.encrypted_password }
          end

          it "sets username" do
            expect { patch "/users", params: params }.to change { User.first.username }.to("admin")
          end

          it "sets email" do
            expect { patch "/users", params: params }.to change { User.first.email }.to("test@example.com")
          end

          it "redirects to dashboard on success" do
            patch "/users", params: params
            expect(response).to redirect_to("/")
          end
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

        it "loads library creation page properly after redirection" do
          get "/"
          follow_redirect!
          expect(response).to have_http_status :success
        end
      end
    end
  end
end
