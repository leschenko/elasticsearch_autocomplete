require 'spec_helper'

class ActiveModelUserFilter < StubModelBase
  ac_field :full_name

  mapping do
    indexes :int, type: 'integer'
  end

  def self.test_data
    [
        {full_name: 'Laura Nelson', interest_ids: [1, 2], int: 3},
        {full_name: 'Laura Flores', interest_ids: [2, 3], int: 5},
        {full_name: 'Laura Larson', interest_ids: [3, 4], int: 4}
    ]
  end

  def self.populate
    test_data.each_with_index do |data, id|
      u = new(data)
      u.id = id
      u.save
    end
  end

  def as_indexed_json(*)
    attrs = [:id, :int, :created_at] + self.class.ac_search_attrs
    attrs.each_with_object({}) { |attr, json| json[attr] = send(attr) }
  end

end

describe 'search' do
  before :all do
    @model = ActiveModelUserFilter
    @model.setup_index
  end

  describe 'filters' do
    it 'filter suggestions with terms' do
      @model.ac_search('Laura', with: {interest_ids: [2]}).map(&:full_name).should =~ ['Laura Nelson', 'Laura Flores']
    end

    it 'accept coma separated string for filter' do
      @model.ac_search('Laura', with: {interest_ids: '1,4'}).map(&:full_name).should =~ ['Laura Nelson', 'Laura Larson']
    end

    it 'filter suggestions without terms' do
      @model.ac_search('Laura', without: {interest_ids: [2]}).map(&:full_name).should =~ ['Laura Larson']
    end
  end

  describe 'sort' do
    it 'sort suggestions desc' do
      res = @model.ac_search('Laura', order: :int, sort_mode: 'desc').map(&:int)
      res.should == res.sort.reverse
    end

    it 'sort suggestions asc' do
      res = @model.ac_search('Laura', order: :int, sort_mode: 'asc').map(&:int)
      res.should == res.sort
    end
  end

  describe 'pagination' do
    it 'limit suggestions collection size' do
      @model.ac_search('Laura', per_page: 1).to_a.length.should == 1
    end

    it 'paginate suggestions' do
      res = @model.ac_search('Laura', per_page: 1, page: 2).to_a
      res.length.should == 1
      res.first.full_name.should == 'Laura Flores'
    end
  end
end