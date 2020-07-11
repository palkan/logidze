\set naccounts 100000 * :scale
\set aid random (1, :naccounts)
\set delta random(-5000, 5000)
BEGIN;
UPDATE pgbench_accounts SET abalance = abalance + :delta WHERE aid = :aid;
END;
