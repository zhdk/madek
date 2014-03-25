class API::Application < ActiveRecord::Base
  belongs_to :user
  
  attr_accessor :authorization_header

  default_scope lambda{ reorder(id: :asc) }

  validates :id, format: {with: /\A[a-z][a-z0-9_-]+\z/, 
                          message: %[only alpha-numeric ascii characters as well as dashes and underscores are allowed, 
                                    first character must be a letter, all letters must be lowercase]}
  validates :id, length: {in: 3..20}

  def authorization_header 
    %[Authorization: Basic #{::Base64.strict_encode64("#{id}:#{secret}")}]
  end

  # hacky way to show the auth header when listing attributes
  def attributes
    original= super
    original.merge("authorization_header" => authorization_header)
  end


end
