class CreateBarkdataFunctions < ActiveRecord::Migration
  def up
    q = %Q{
      CREATE OR REPLACE FUNCTION barkdata.if_modified_func() RETURNS TRIGGER AS $body$
      BEGIN
        IF TG_WHEN <> 'AFTER' THEN
          RAISE EXCEPTION 'barkdata.if_modified_func() may only run as an AFTER trigger';
        END IF;

        IF (TG_OP = 'UPDATE' AND TG_LEVEL = 'ROW') THEN
          INSERT INTO barkdata.changelog (schema_name, table_name, user_name, action, old_values, new_values, updated_cols, query)
          VALUES (tg_table_schema::text, tg_table_name::text, current_user::text, 'U', hstore(old.*), hstore(new.*), akeys(hstore(new.*) - hstore(old.*)), current_query());
          RETURN new;
        ELSIF (TG_OP = 'DELETE' AND TG_LEVEL = 'ROW') THEN
          INSERT INTO barkdata.changelog (schema_name, table_name, user_name, action, old_values, query)
          VALUES (tg_table_schema::text, tg_table_name::text, current_user::text, 'D', hstore(old.*), current_query());
          RETURN old;
        ELSIF (TG_OP = 'INSERT' AND TG_LEVEL = 'ROW') THEN
          INSERT INTO barkdata.changelog (schema_name, table_name, user_name, action, new_values, query)
          VALUES (tg_table_schema::text, tg_table_name::text, current_user::text, 'I', hstore(new.*), current_query());
          RETURN new;
        ELSIF (TG_OP = 'TRUNCATE' AND TG_LEVEL = 'STATEMENT') THEN
          INSERT INTO barkdata.changelog (schema_name, table_name, user_name, action, query)
          VALUES (tg_table_schema::text, tg_table_name::text, current_user::text, 'T', current_query());
          RETURN NULL;
        END IF;
      END;
      $body$
      LANGUAGE plpgsql;
    }
    ActiveRecord::Base.connection.execute(q)
  end

  def down
    q = %Q{
      -- DROP FUNCTION barkdata.if_modified_func()
    }
    ActiveRecord::Base.connection.execute(q)
  end
end
