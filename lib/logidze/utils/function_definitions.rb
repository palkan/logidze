# frozen_string_literal: true

module Logidze
  module Utils
    class FuncDef < Struct.new(:name, :version, :signature); end

    module FunctionDefinitions
      class << self
        def from_fs
          function_paths = Dir.glob(File.join(__dir__, "..", "..", "generators", "logidze", "install", "functions", "*.sql"))
          function_paths.map do |path|
            name = path.match(/([^\/]+)\.sql/)[1]

            file = File.open(path)
            header, version_comment = file.readline, file.readline

            signature = parse_signature(header)
            version = parse_version(version_comment)
            FuncDef.new(name, version, signature)
          end
        end

        def from_db
          query = <<~SQL
            SELECT pp.proname, pg_get_functiondef(pp.oid) AS definition
            FROM pg_proc pp
            WHERE pp.proname like 'logidze_%'
            ORDER BY pp.oid;
          SQL
          ActiveRecord::Base.connection.execute(query).map do |row|
            version = parse_version(row["definition"])
            FuncDef.new(row["proname"], version, nil)
          end
        end

        private

        def parse_version(line)
          line.match(/version:\s+(\d+)/)&.[](1).to_i
        end

        def parse_signature(line)
          parameters = line.match(/CREATE OR REPLACE FUNCTION\s+[\w_]+\((.*)\)/)[1]
          parameters.split(/\s*,\s*/).map { |param| param.split(/\s+/, 2).last.sub(/\s+DEFAULT .*$/, "") }.join(", ")
        end
      end
    end
  end
end
