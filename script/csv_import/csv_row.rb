require_relative "csv_row/normalizer"

# Use CSVRow to process a csv row.
# CSVFile creates an instance of CSVRow for every row and calls #create
class CSVRow
  include ::Card::Model::SaveHelper
  include Normalizer

  @columns = []
  @required = [] # array of required fields or :all

  # Use column names as keys and method names as values to define normalization
  # and validation methods.
  # The normalization methods get the original field value as
  # argument. The validation methods get the normalize value as argument.
  # The return value of normalize methods replaces the field value.
  # If validate methods return false then the import fails.
  @normalize = {}
  @validate = {}

  class << self
    attr_reader :columns, :required

    def normalize key
      @normalize && @normalize[key]
    end

    def validate key
      @validate && @validate[key]
    end
  end

  attr_reader :errors

  def initialize row, index
    @row = row
    @index = index
    @errors = []
    required.each do |key|
      error "value for #{key} missing" unless row[key].present?
    end
    normalize
    validate

  end

  def error msg
    @errors << msg
    raise StandardError, msg
  end

  def required
    self.class.required == :all ? columns : self.class.required
  end

  def columns
    self.class.columns
  end

  def normalize
    @row.each do |k, v|
      normalize_field k, v
    end
  end

  def validate
    @row.each do |k, v|
      validate_field k, v
    end
  end

  def normalize_field field, value
    return unless (method_name = method_name(field, :normalize))
    @row[field] = send method_name, value
  end

  def validate_field field, value
    return unless (method_name = method_name(field, :validate))
    return if send method_name, value
    error "row #{@index}: invalid value for #{field}: #{value}"
  end

  # @param type [:normalize, :validate]
  def method_name field, type
    method_name = "#{type}_#{field}".to_sym
    respond_to?(method_name) ? method_name : self.class.send(type, field)
  end

  def method_missing method_name, *args
    respond_to_missing?(method_name) ? @row[method_name] : super
  end

  def respond_to_missing? method_name, _include_private=false
    @row.keys.include? method_name
  end
end
