\set naccounts 100000 * :scale
\setrandom aid 1 :naccounts
\setrandom delta -5000 5000
BEGIN;
UPDATE pgbench_accounts SET abalance = abalance + :delta WHERE aid = :aid;
END;
