-- Winners
WITH acha AS (
  SELECT id, name, description FROM memory.default.achievements_calendar
  UNION ALL
  SELECT id, name, description FROM memory.default.achievements_changed_files
  UNION ALL
  SELECT id, name, description FROM memory.default.achievements_changed_lines
  UNION ALL
  SELECT id, name, description FROM memory.default.achievements_languages
  UNION ALL
  SELECT id, name, description FROM memory.default.achievements_words
), acq AS (
  SELECT * FROM memory.default.acquired_calendar
  UNION ALL
  SELECT * FROM memory.default.acquired_changed_files
  UNION ALL
  SELECT * FROM memory.default.acquired_changed_lines
  UNION ALL
  SELECT * FROM memory.default.acquired_languages
  UNION ALL
  SELECT * FROM memory.default.acquired_words
), winners AS (
  SELECT
    acq.author_name AS author_name,
    array_join(transform(array_agg(DISTINCT acq.email), email -> regexp_replace(email, '(?<=.)[^@](?=[^@]*?@)|(?:(?<=@.)|(?!^)\G(?=[^@]*$)).(?=.*\.)', '*')), ',', 'NULL') AS emails,
    count(acq.id) AS num_achievements,
    array_join(transform(
                   zip(array_agg(acq.id), array_agg(acq.name), array_agg(acq.achieved_at), array_agg(acq.achieved_in)),
                   ac -> format('<a href="https://github.com/trinodb/trino/commit/%s"><img src="aches/%s@6x.png" title="%s - achieved on %s" /></a>', ac[4], ac[1], ac[2], ac[3])) , ' ', '') AS achievements
  FROM acq
  GROUP BY acq.author_name)
SELECT
  winners.author_name,
  winners.emails,
  winners.num_achievements,
  format('%.2f', 100 * CAST(winners.num_achievements AS DOUBLE) / a.achievements_count) AS percent_achievements,
  winners.achievements
FROM winners
CROSS JOIN (SELECT COUNT(*) AS achievements_count FROM acha) a
ORDER BY num_achievements DESC
;
