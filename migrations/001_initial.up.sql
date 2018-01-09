-- update date time on update_at field
CREATE OR REPLACE FUNCTION update_datetime()
RETURNS TRIGGER AS $$
BEGIN
        NEW.last_update = now();
        RETURN NEW;
END;
$$ language 'plpgsql';

-- uuid extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- audit trigger
CREATE OR REPLACE FUNCTION update_audit()
RETURNS TRIGGER AS $$
BEGIN
        INSERT INTO audits
        (uuid, key, node, version, object)
        VALUES
        (OLD.uuid, NEW.key, NEW.node, uuid_generate_v4(), OLD.object);
        RETURN NEW;
END;
$$ language 'plpgsql';

-- objects table
CREATE TABLE objects
(
        uuid uuid DEFAULT uuid_generate_v4() NOT NULL,
        key character varying(150) NOT NULL,
        node character varying(150) NOT NULL,
        object jsonb,
        created_at timestamp without time zone NOT NULL DEFAULT now(),
        last_update timestamp without time zone NOT NULL DEFAULT now(),
        PRIMARY KEY (uuid),
        CONSTRAINT unique_objects UNIQUE (key, node)
);

ALTER TABLE objects
        ALTER COLUMN object SET STORAGE EXTERNAL;

CREATE TRIGGER update_objects
        BEFORE UPDATE ON objects
        FOR EACH ROW EXECUTE PROCEDURE update_datetime();

CREATE TRIGGER update_audits
        BEFORE UPDATE ON objects
        FOR EACH ROW EXECUTE PROCEDURE update_audit();

-- audit table
CREATE TABLE audits
(
        uuid uuid NOT NULL,
        key character varying(150) NOT NULL,
        node character varying(150) NOT NULL,
        version uuid NOT NULL,
        object jsonb,
        created_at timestamp without time zone NOT NULL DEFAULT now(),
        last_update timestamp without time zone NOT NULL DEFAULT now(),
        CONSTRAINT unique_audits UNIQUE (uuid, key, node, version)
);

ALTER TABLE audits
        ALTER COLUMN object SET STORAGE EXTERNAL;
