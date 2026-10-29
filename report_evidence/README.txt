Supporting evidence for SuperMart_DBMS_Project_Report_Final.docx

diagrams/
  usecase.png, architecture.png  - drawn from index (1).html and supabase_schema.sql (sources: the .html files)

verification_sql/  (run on PostgreSQL 16.15 in a disposable Docker container, 28 Oct 2026)
  Preparation for plain PostgreSQL (Supabase already has these):
    CREATE SCHEMA extensions; CREATE ROLE anon NOLOGIN; CREATE ROLE authenticated NOLOGIN;
    ALTER DATABASE supermart SET search_path = public, extensions;
    then: psql -f supabase_schema.sql
  01_queries.sql  -> 01_queries.out   Q1-Q25 (Chapter 7)
  02_tests.sql    -> 02_tests.out     TX1-TX9, constraint tests, savepoint (Chapters 7-8)
  03_more.sql     -> 03_more.out      life-cycle, GRANT/REVOKE and anon security tests (Chapter 10)
  04_perf.sql                         synthetic load (separate database "perf")
  05_explain.sql  -> 05_explain.out   EXPLAIN ANALYZE plans (Chapter 9)
  06_extra.sql    -> 06_extra.out     view, identity sequence, isolation level
  conc_a.out / conc_b.out             two-session last-unit test (Section 8.8)
  dl_a.out / dl_b.out                 deadlock test (Section 8.9)
Tests 02/03 change data; restore the baseline (pg_dump -Fc after loading the schema) between runs.

SuperMart_DBMS_Project_Report_Final_preview.pdf - PDF export used to check the layout.
