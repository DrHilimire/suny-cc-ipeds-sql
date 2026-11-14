-- !preview conn=con
-- 02_find_peers.sql
-- New York's public 2-year colleges (sector 4) and the system each belongs to.

SELECT UNITID, INSTNM, CITY, F1SYSNAM
FROM hd
WHERE STABBR = 'NY'
  AND SECTOR = 4
  AND year = (SELECT max(year) FROM hd)
ORDER BY INSTNM;
