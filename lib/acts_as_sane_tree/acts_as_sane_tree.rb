require 'active_record'
require 'acts_as_sane_tree/instance_methods'
require 'acts_as_sane_tree/singleton_methods.rb'

module ActsAsSaneTree
  
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
  end

  # Specify this +acts_as+ extension if you want to model a tree structure by providing a parent association and a children
  # association. This requires that you have a foreign key column, which by default is called +parent_id+.
  #
  #   class Category < ActiveRecord::Base
  #     acts_as_sane_tree :order => "name"
  #   end
  #
  #   Example:
  #   root
  #    \_ child1
  #         \_ subchild1
  #         \_ subchild2
  #
  #   root      = Category.create("name" => "root")
  #   child1    = root.children.create("name" => "child1")
  #   subchild1 = child1.children.create("name" => "subchild1")
  #
  #   root.parent   # => nil
  #   child1.parent # => root
  #   root.children # => [child1]
  #   root.children.first.children.first # => subchild1
  #
  # The following class methods are also added:
  # 
  # * <tt>nodes_within?(src, chk)</tt> - Returns true if chk contains any nodes found within src and all ancestors of nodes within src
  # * <tt>nodes_within(src, chk)</tt> - Returns any matching nodes from chk found within src and all ancestors within src
  # * <tt>nodes_and_descendents(*args)</tt> - Returns all nodes and descendents for given IDs or records. Accepts multiple IDs and records. Valid options:
  #   * :raw - No Hash nesting
  #   * :no_self - Will not return given nodes in result set
  #   * {:depth => n} - Will set maximum depth to query
  #   * {:to_depth => n} - Alias for :depth
  #   * {:at_depth => n} - Will return times at given depth (takes precedence over :depth/:to_depth)
  module ClassMethods
    # Configuration options are:
    #
    # * <tt>foreign_key</tt> - specifies the column name to use for tracking of the tree (default: +parent_id+)
    # * <tt>order</tt> - makes it possible to sort the children according to this SQL snippet.
    # * <tt>counter_cache</tt> - keeps a count in a +children_count+ column if set to +true+ (default: +false+).
    def acts_as_sane_tree(options = {})
      @configuration = { :foreign_key => "parent_id", :order => nil, :counter_cache => nil, :max_depth => 10000 }
      @configuration.update(options) if options.is_a?(Hash)

      class_eval do
        belongs_to :parent, :class_name => name, :foreign_key => @configuration[:foreign_key], :counter_cache => @configuration[:counter_cache]
        has_many :children, :class_name => name, :foreign_key => @configuration[:foreign_key], :order => @configuration[:order], :dependent => :destroy
        
        validates_each @configuration[:foreign_key] do |record, attr, value|
          record.errors.add attr, 'cannot be own parent.' if !record.id.nil? && value.to_i == record.id.to_i
        end
      end
      include ActsAsSaneTree::InstanceMethods
      extend ActsAsSaneTree::SingletonMethods
    end
  end
end