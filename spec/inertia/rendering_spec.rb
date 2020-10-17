RSpec.describe 'rendering inertia views', type: :request do
  subject { response.body }

  context 'first load' do
    let(:page) { InertiaRails::Renderer.new('TestComponent', '', request, response, '', props: nil, view_data: nil).send(:page) }

    context 'with props' do
      let(:page) { InertiaRails::Renderer.new('TestComponent', '', request, response, '', props: {name: 'Brandon', sport: 'hockey'}, view_data: nil).send(:page) }
      before { get props_path }

      it { is_expected.to include inertia_div(page) }
    end

    context 'with view data' do
      before { get view_data_path }

      it { is_expected.to include inertia_div(page) }
      it { is_expected.to include({name: 'Brian', sport: 'basketball'}.to_json) }
    end

    context 'with no data' do
      before { get component_path }

      it { is_expected.to include inertia_div(page) }
    end
  end

  context 'subsequent requests' do
    let(:page) { InertiaRails::Renderer.new('TestComponent', '', request, response, '', props: {name: 'Brandon', sport: 'hockey'}, view_data: nil).send(:page) }
    let(:headers) { {'X-Inertia' => true} }

    before { get props_path, headers: headers }

    it { is_expected.to eq page.to_json }


    it 'has the proper headers' do
      expect(response.headers['X-Inertia']).to eq 'true'
      expect(response.headers['Vary']).to eq 'Accept'
      expect(response.headers['Content-Type']).to eq 'application/json; charset=utf-8'
    end

    it 'has the proper body' do
      expect(JSON.parse(response.body)).to include('url' => '/props')
    end
  end

  context 'preserving headers' do
    let(:headers) {
      {
        'X-Inertia' => true,
        'X-Inertia-Version' => original_version,
        'Referer' => referer_url
      }
    }

    let(:original_version) { "1.0" }
    let(:updated_version) { "1.1" }
    let(:referer_url) { "/some-path" }

    before {
      InertiaRails.configure{|c| c.version = updated_version}
      post with_url_path, headers: headers
    }

    after {
      InertiaRails.configure{|c| c.version = nil}
    }

    it 'preserves the version' do
      expect(JSON.parse(response.body)).to include('version' => original_version)
    end

    it 'preserves the url' do
      expect(JSON.parse(response.body)).to include('url' => referer_url)
    end
  end
end

def inertia_div(page)
  "<div id=\"app\" data-page=\"#{CGI::escape_html(page.to_json)}\"></div>"
end
