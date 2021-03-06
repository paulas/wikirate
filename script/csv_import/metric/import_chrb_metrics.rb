require_relative "../../../config/environment"
require_relative "metric_csv_row"
require_relative "../../../vendor/card-mods/csv_import/lib/import_manager/script_import_manager.rb"

csv_path = File.expand_path "../data/CHRB_import.csv", __FILE__

file = CsvFile.new(csv_path, MetricCsvRow, col_sep: ";", headers: true)

ScriptImportManager.new(file, user: "Philipp Kuehl", error_policy: :report).import
