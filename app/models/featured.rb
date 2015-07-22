require 'yaml'

class Featured
  attr_reader :id
  attr_reader :org_name
  attr_reader :name
  attr_reader :thumbnail_url

  private

  def initialize(hash)
    @id = hash.delete('id') || fail('expected id')
    @org_name = hash.delete('org_name') || fail('expected org_name')
    @name = hash.delete('name') || fail('expected org_name')
    @thumbnail_url = hash.delete('thumbnail_url') || "http://americanarchive.org.s3.amazonaws.com/featured/#{@id}_gallery.jpg"
    fail("unexpected #{hash}") unless hash == {}
  end

  @@galleries = Hash[
    Dir[Rails.root + 'config/featured/*-featured.yml'].map do |gallery_path|
      [
        gallery_path.sub(/.*\//, '').sub('-featured.yml', ''),
        YAML.load_file(gallery_path).map { |hash| Featured.new(hash) }
      ]
    end
  ]

  def self.from_gallery(gallery_name)
    @@galleries[gallery_name]
  end
end
