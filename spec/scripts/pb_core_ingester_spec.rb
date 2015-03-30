require_relative '../../scripts/lib/pb_core_ingester'
require 'tmpdir'

describe PBCoreIngester do
  let(:path) { File.dirname(File.dirname(__FILE__)) + '/fixtures/pbcore/clean-MOCK.xml' }

  before(:each) do
    @ingester = PBCoreIngester.new(same_mount: true)
    @ingester.delete_all
  end

  it 'fails without same_mount' do
    expect { PBCoreIngester.new(same_mount: false) }.to raise_error
  end

  it 'fails with non-existent file' do
    expect { @ingester.ingest(path: '/non-existent.xml') }.to raise_error(PBCoreIngester::ReadError)
  end

  it 'fails with invalid file' do
    # obviously this file is not valid pbcore.
    expect { @ingester.ingest(path: __FILE__) }.to raise_error(PBCoreIngester::ValidationError)
  end

  it 'works for single ingest' do
    expect_results(0)
    expect { @ingester.ingest(path: path) }.not_to raise_error
    expect_results(1)
    expect { @ingester.ingest(path: path) }.not_to raise_error
    expect_results(1)
    expect { @ingester.delete_all }.not_to raise_error
    expect_results(0)
  end

  it 'works for collection' do
    Dir.mktmpdir do |dir|
      expect_results(0)
      document = File.read(path)
      collection = "<pbcoreCollection>#{document}</pbcoreCollection>"
      collection_path = "#{dir}/collection.xml"
      File.write(collection_path, collection)
      expect { @ingester.ingest(path: collection_path) }.not_to raise_error
      expect_results(1)
      expect { @ingester.delete_all }.not_to raise_error
      expect_results(0)
    end
  end

  it 'works for all fixtures' do
    expect_results(0)
    glob = File.dirname(path) + '/clean-*'
    Dir[glob].each do |fixture_path|
      expect { @ingester.ingest(path: fixture_path) }.not_to raise_error
    end
    expect_results(19)
  end

  def expect_results(count)
    expect(@ingester.solr.get('select', params: { q: '*:*' })['response']['numFound']).to eq(count)
  end
end
