-- 1. Geçici tablo oluþtur
IF OBJECT_ID('tempdb..#Streaks') IS NOT NULL
    DROP TABLE #Streaks;

CREATE TABLE #Streaks (
    team_id INT,
    game_id INT,
    date_id INT,
    result CHAR(1),
    winstreak INT DEFAULT 0,
    losestreak INT DEFAULT 0
);

-- 2. Maçlarý sýralý þekilde #Streaks tablosuna ekle
INSERT INTO #Streaks (team_id, game_id, date_id, result)
SELECT
    team_id,
    game_id,
    date_id,
    result
FROM (
    SELECT
        home_team_id AS team_id,
        game_id,
        date_id,
        wl_home AS result
    FROM Performance
    UNION ALL
    SELECT
        away_team_id AS team_id,
        game_id,
        date_id,
        wl_away AS result
    FROM Performance
) AS CombinedResults
ORDER BY team_id, date_id;

-- 3. Winstreak ve Losestreak deðerlerini hesapla
DECLARE @team_id INT, @game_id INT, @date_id INT, @result CHAR(1);
DECLARE @prev_winstreak INT = 0, @prev_losestreak INT = 0, @prev_team_id INT = NULL;

DECLARE streak_cursor CURSOR FOR
SELECT team_id, game_id, date_id, result
FROM #Streaks
ORDER BY team_id, date_id;

OPEN streak_cursor;

FETCH NEXT FROM streak_cursor INTO @team_id, @game_id, @date_id, @result;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @team_id <> @prev_team_id
    BEGIN
        -- Takým deðiþtiyse serileri sýfýrla
        SET @prev_winstreak = 0;
        SET @prev_losestreak = 0;
    END;

    -- Winstreak ve Losestreak hesaplama
    IF @result = 'W'
    BEGIN
        SET @prev_winstreak = @prev_winstreak + 1;
        SET @prev_losestreak = 0;
    END
    ELSE IF @result = 'L'
    BEGIN
        SET @prev_losestreak = @prev_losestreak + 1;
        SET @prev_winstreak = 0;
    END;

    -- Güncellenmiþ deðerleri tabloya yaz
    UPDATE #Streaks
    SET winstreak = @prev_winstreak,
        losestreak = @prev_losestreak
    WHERE team_id = @team_id AND game_id = @game_id;

    -- Önceki takým ID'sini güncelle
    SET @prev_team_id = @team_id;

    FETCH NEXT FROM streak_cursor INTO @team_id, @game_id, @date_id, @result;
END;

CLOSE streak_cursor;
DEALLOCATE streak_cursor;

-- 4. Sonuçlarý göster
SELECT *
FROM #Streaks
ORDER BY team_id, date_id;
-- 5. performance'a aktar
INSERT INTO Performance(home_team_id,away_team_id,game_id,date_id,wl_home,[min],
	fgm_home,fga_home,fg_pct_home,fg3m_home,fg3a_home,
    fg3_pct_home,ftm_home,fta_home,ft_pct_home,oreb_home,dreb_home,reb_home,
    ast_home,stl_home,blk_home,tov_home,pf_home,pts_home,plus_minus_home,wl_away,
    fgm_away,fga_away,fg_pct_away,fg3m_away,fg3a_away,fg3_pct_away,ftm_away,
    fta_away,ft_pct_away,oreb_away,dreb_away,reb_away,ast_away,stl_away,blk_away,tov_away,pf_away,pts_away,
    plus_minus_away,home_performance,away_performance,home_winstreak,home_losestreak, 
	away_winstreak, away_losestreak)
	SELECT team_id_home,team_id_away,g.game_id,g.game_id,wl_home,[min],
	fgm_home,fga_home,fg_pct_home,fg3m_home,fg3a_home,
    fg3_pct_home,ftm_home,fta_home,ft_pct_home,oreb_home,dreb_home,reb_home,
    ast_home,stl_home,blk_home,tov_home,pf_home,pts_home,plus_minus_home,wl_away,
    fgm_away,fga_away,fg_pct_away,fg3m_away,fg3a_away,fg3_pct_away,ftm_away,
    fta_away,ft_pct_away,oreb_away,dreb_away,reb_away,ast_away,stl_away,blk_away,tov_away,pf_away,pts_away,
    plus_minus_away,
	-- Home Performance
    ((pts_home + (oreb_home + dreb_home) + ast_home + stl_home + blk_home) 
	- ((fga_home - fgm_home) + (fta_home - ftm_home) + tov_home)) 
	* CASE WHEN wl_home = 'W' THEN 1.1 ELSE 0.9 
    END,
    -- Away Performance
    ((pts_away + (oreb_away + dreb_away) + ast_away + stl_away + blk_away) 
	- ((fga_away - fgm_away) + (fta_away - ftm_away) + tov_away)) 
	* CASE WHEN wl_away = 'W' THEN 1.1 ELSE 0.9 
    END,
	 -- Home Winstreak and Losestreak
    hs.winstreak,
    hs.losestreak,
    -- Away Winstreak and Losestreak
    as_.winstreak,
    as_.losestreak
FROM 
    [449_NBA].dbo.game g
LEFT JOIN #Streaks hs
    ON g.team_id_home = hs.team_id AND g.game_id = hs.game_id
LEFT JOIN #Streaks as_
    ON g.team_id_away = as_.team_id AND g.game_id = as_.game_id;
-- Geçici tabloyu sil
DROP TABLE #Streaks;
