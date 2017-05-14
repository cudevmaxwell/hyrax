require 'spec_helper'

RSpec.describe 'hyrax/base/_attribute_rows.html.erb', type: :view do
  let(:url) { "http://example.com" }
  let(:rights_statement_uri) { 'http://rightsstatements.org/vocab/InC/1.0/' }
  let(:ability) { double }
  let(:work) do
    stub_model(GenericWork,
               related_url: [url],
               rights_statement: [rights_statement_uri])
  end
  let(:solr_document) { SolrDocument.new(work.to_solr) }
  let(:presenter) { Hyrax::WorkShowPresenter.new(solr_document, ability) }

  let(:page) do
    render 'hyrax/base/attribute_rows', presenter: presenter
    Capybara::Node::Simple.new(rendered)
  end

  it 'shows external link with icon for related url field' do
    expect(page).to have_selector '.glyphicon-new-window'
    expect(page).to have_link(url)
  end

  it 'shows rights statement with link to statement URL' do
    expect(page).to have_link(rights_statement_uri)
  end
end