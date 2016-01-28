require 'spec_helper'

class ActiveModelUserFilter < StubModelBase
  ac_field :full_name

  def self.test_data
    [
        {full_name: 'Laura Nelson', interest_ids: [1, 2]},
        {full_name: 'Laura Flores', interest_ids: [2, 3]},
        {full_name: 'Laura Larson', interest_ids: [3, 4]}
    ]
  end

  def self.populate
    test_data.each_with_index do |data, id|
      u = new(data)
      u.id = id
      u.save
    end
  end

  def to_indexed_json
    for_json = {}
    attrs = [:id, :created_at, :interest_ids] + self.class.ac_search_attrs
    attrs.each do |attr|
      for_json[attr] = send(attr)
    end
    MultiJson.encode(for_json)
  end
end

describe 'search filters' do
  before :all do
    @model = ActiveModelUserFilter
    @model.setup_index
  end

  it 'filter suggestions with or terms' do
    expect(@model.ac_search('Laura', or: [{interest_ids: [1]}, {interest_ids: '4'}]).map(&:full_name)).to\
      match_array ['Laura Nelson', 'Laura Larson']
  end

  it 'filter suggestions with terms' do
    expect(@model.ac_search('Laura', with: {interest_ids: [2]}).map(&:full_name)).to match_array ['Laura Nelson', 'Laura Flores']
  end

  it 'accept coma separated string for filter' do
    expect(@model.ac_search('Laura', with: {interest_ids: '1,4'}).map(&:full_name)).to match_array ['Laura Nelson', 'Laura Larson']
  end

  it 'filter suggestions without terms' do
    expect(@model.ac_search('Laura', without: {interest_ids: [2]}).map(&:full_name)).to match_array ['Laura Larson']
  end

  it 'can order suggestions desc' do
    res = @model.ac_search('Laura', order: :id, sort_mode: 'desc').map(&:id)
    expect(res).to eq res.sort.reverse
  end

  it 'can order suggestions asc' do
    res = @model.ac_search('Laura', order: :id, sort_mode: 'asc').map(&:id)
    expect(res).to eq res.sort
  end

  it 'limit suggestions collection size' do
    expect(@model.ac_search('Laura', per_page: 1).to_a.length).to eq 1
  end

  it 'paginate suggestions' do
    res = @model.ac_search('Laura', order: :id, per_page: 1, page: 2).to_a
    expect(res.length).to eq 1
    expect(res.first.full_name).to eq 'Laura Flores'
  end
end
