class CreateBarkdataChangelog < ActiveRecord::Migration
  def up
    q = %Q{
      CREATE EXTENSION IF NOT EXISTS hstore;

      CREATE SCHEMA IF NOT EXISTS barkdata;

      CREATE TABLE barkdata.changelog (
        change_id bigserial primary key,
        schema_name text not null,
        table_name text not null,
        user_name text not null,
        action_timestamp timestamp not null default current_timestamp,
        action text not null check (action in ('I','D','U','T')),
        old_values hstore,
        new_values hstore,
        updated_cols text[],
        query text,
        archived boolean default false
      );
    }
    ActiveRecord::Base.connection.execute(q)
  end

  def down
    q = %Q{
      DROP TABLE barkdata.changelog;
    }
    ActiveRecord::Base.connection.execute(q)
  end
end
