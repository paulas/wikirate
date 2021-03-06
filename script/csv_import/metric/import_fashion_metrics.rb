require_relative "../../../config/environment"
require_relative "metric_csv_row"
import_manager_dir = "../../../vendor/card-mods/csv_import/lib/import_manager"
require_relative "#{import_manager_dir}/script_import_manager.rb"

csv_path = File.expand_path "../data/fashion_import.csv", __FILE__

file = CsvFile.new(csv_path, MetricCsvRow, col_sep: ",", headers: true)

ScriptImportManager.new(file, user: "Laureen van Breen", error_policy: :report).import
