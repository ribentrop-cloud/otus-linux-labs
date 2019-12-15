CREATE USER jiradbuser PASSWORD 'jiradbpassword';
GRANT ALL ON SCHEMA public TO jiradbuser;
GRANT ALL ON ALL TABLES IN SCHEMA public TO jiradbuser;
CREATE DATABASE jiradb WITH ENCODING 'UNICODE' LC_COLLATE 'C' LC_CTYPE 'C' TEMPLATE template0 OWNER=jiradbuser CONNECTION LIMIT=-1;
