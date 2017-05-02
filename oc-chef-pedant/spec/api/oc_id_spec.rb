require 'pedant/rspec/common'

describe "oc_id API", :oc_id do
  context "status endpoint" do
    let(:request_url) { "#{platform.server}/id/v1/status" }
    let(:good_status) do
      {"status" => "ok",
       "erchef" => { "status" => "reachable" },
       "postgres"=>{ "status" => "reachable" }}
    end

    context "GET /id/v1/status" do
      it "retuns 200" do
        get(request_url, platform.superuser).should look_like({:status => 200,
                                                               :body => good_status})
      end
    end
  end

  context "signin" do
    let(:username) { platform.non_admin_user.name }
    let(:request_url) { "#{platform.server}/id/auth/chef/callback" }
    let(:request_body) { "username=#{username}&password=#{password}&authenticity_token=#{CGI.escape(csrf[:token])}&commit=Sign+In" }
    let(:request_headers) do
      {
        "Content-Type" => "application/x-www-form-urlencoded",
        "Cookie" => csrf[:cookie]
      }
    end

    let(:csrf) do
      response = get("#{platform.server}/id/signin", platform.superuser, headers: {"Accept" => "text/html"})
      cookie = response.headers[:set_cookie][1].split(";").first
      # I KNOW. I'll leave it up to reviewers whether we should pull
      # in nokogiri or hpricot just do to this
      re = /<meta name="csrf-token" content="(.*)" \/>/
      token = response.match(re)[1]
      { cookie: cookie, token: token}
    end

    let(:response) { post(request_url, platform.superuser, headers: request_headers, payload: request_body) }

    context "with correct password" do
      let(:password) { "foobar" } #hardcoded at the platform layer
      context "POST /id/auth/chef/callback" do
        it "redirects us to authorized applications" do
          expect(response.code).to eq(302)
          expect(response.headers[:location]).to match(%r{/id/oauth/authorized_applications})
        end
      end
    end

    context "with incorrect password" do
      let(:password) { "WRONGWRONGWRONG" }
      context "POST /id/auth/chef/callback" do
        it "redirects us to an error" do
          expect(response.code).to eq(302)
          expect(response.headers[:location]).to match(%r{/id/auth/failure\?message=invalid_credentials&strategy=chef})
        end
      end
    end


  end
end