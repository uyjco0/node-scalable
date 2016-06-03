-- @author Jorge Couchet (jorge.couchet@gmail.com)



------ *******************************************
------ *******************************************
------          start CSVS
------ *******************************************
------ *******************************************

-- start table CSVS

-- The table is used to load the CSV files:
--    1. The table has several CSV files inside
--    2. Each row corresponds to a single line from a CSV file
CREATE TABLE csvs (
    id             bigserial      CONSTRAINT csvs_id_pk
                                  PRIMARY KEY,
    -- Somebody name
    name           varchar        DEFAULT '',
    -- Somebody email
    email          varchar        DEFAULT '',
    -- The time when added to the db. It is not asked, but
    -- could be useful for several things (as for example
    -- sharding, etc)
    added          timestamp      DEFAULT NOW()
                                  CONSTRAINT csvs_added_nn
                                  NOT NULL
);

-- With the current information about the system 's posible
-- queries, the following are the more natural candidate indexes:
CREATE INDEX csvs_name_idx ON csvs USING btree(name);
CREATE INDEX csvs_email_idx ON csvs USING btree(email);

-- end table CSVS

------ *******************************************
------ *******************************************
------                 end CSVS
------ *******************************************
------ *******************************************
