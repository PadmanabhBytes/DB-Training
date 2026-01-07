WITH TopScores AS
        (SELECT TOP 10000 id, score
         FROM   (SELECT id, score, ROW_NUMBER() OVER (ORDER BY score DESC, id DESC) as rn
                FROM    #DataTable
                ) AS RankedScores_down
         WHERE  RankedScores_down.rn % 3 = 0
         ORDER BY RankedScores_down.rn
        ),
    LowScores AS
        (SELECT TOP 10000 id, score
         FROM   (SELECT id, score, ROW_NUMBER() OVER (ORDER BY score, id) as rn
                FROM    #DataTable
                ) AS RankedScores_up
         WHERE  RankedScores_up.rn % 3 = 0
         ORDER BY RankedScores_up.rn
        )
    SELECT * FROM TopScores
    UNION
    SELECT * FROM LowScores
    ORDER BY score, id;
