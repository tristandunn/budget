# frozen_string_literal: true

require "fileutils"
require "tmpdir"

# Copy the production database to the local machine by piping the export from
# the production server into the local development database.
#
#   bin/kamal sqlite-export -d production | bin/rails sqlite:import
#
namespace :sqlite do
  desc "Export the primary database as Base64 to standard output"
  task export: :environment do
    Rails.logger.silence do
      Dir.mktmpdir do |directory|
        path = File.join(directory, "export.sqlite3")

        connection = ActiveRecord::Base.connection
        connection.execute("VACUUM INTO #{connection.quote(path)}")

        $stdout.write([File.binread(path)].pack("m0"))
      end
    end
  end

  desc "Import the primary database from Base64 on standard input"
  task import: :environment do
    if Rails.env.production?
      abort("Refusing to overwrite the production database.")
    end

    data = $stdin.read.unpack1("m")
    path = Rails.root.join(ActiveRecord::Base.connection_db_config.database)

    ActiveRecord::Base.connection_pool.disconnect!

    FileUtils.rm_f(["#{path}-shm", "#{path}-wal"])
    File.binwrite(path, data)
  end
end
