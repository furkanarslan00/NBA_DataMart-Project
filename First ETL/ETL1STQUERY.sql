
CREATE TABLE Team(
	id int PRIMARY KEY,
	full_name VARCHAR(22),
	abbreviation VARCHAR(3),
	nickname VARCHAR(13),
	city VARCHAR(13),
	[state] VARCHAR(20),
	year_founded SMALLINT
);

CREATE TABLE [Date](
	date_id INT PRIMARY KEY,
	[day] INT,
	[month] INT,
	[year] INT
);

CREATE TABLE Game(
	game_id INT PRIMARY KEY,
	season_id INT,
	matchup VARCHAR(11),
	season_type VARCHAR(14)
);

CREATE TABLE Performance (
	home_team_id INT FOREIGN KEY REFERENCES Team(id),
	away_team_id INT FOREIGN KEY REFERENCES Team(id),
	game_id INT FOREIGN KEY REFERENCES Game(game_id),
	date_id INT FOREIGN KEY REFERENCES [Date](date_id),
    wl_home VARCHAR(1),
    [min] SMALLINT,
    fgm_home SMALLINT,
    fga_home SMALLINT,
    fg_pct_home FLOAT,
    fg3m_home SMALLINT,
    fg3a_home SMALLINT,
    fg3_pct_home FLOAT,
    ftm_home SMALLINT,
    fta_home SMALLINT,
    ft_pct_home FLOAT,
    oreb_home SMALLINT,
    dreb_home SMALLINT,
    reb_home SMALLINT,
    ast_home SMALLINT,
    stl_home SMALLINT,
    blk_home SMALLINT,
    tov_home SMALLINT,
    pf_home SMALLINT,
    pts_home SMALLINT,
    plus_minus_home SMALLINT,
    wl_away VARCHAR(1),
    fgm_away SMALLINT,
    fga_away SMALLINT,
    fg_pct_away FLOAT,
    fg3m_away SMALLINT,
    fg3a_away SMALLINT,
    fg3_pct_away FLOAT,
    ftm_away SMALLINT,
    fta_away SMALLINT,
    ft_pct_away FLOAT,
    oreb_away FLOAT,
    dreb_away SMALLINT,
    reb_away SMALLINT,
    ast_away SMALLINT,
    stl_away SMALLINT,
    blk_away SMALLINT,
    tov_away SMALLINT,
    pf_away SMALLINT,
    pts_away SMALLINT,
    plus_minus_away SMALLINT,
	home_performance INT,
	away_performance INT,
	home_winstreak INT, 
	home_losestreak INT, 
	away_winstreak INT, 
	away_losestreak INT
);

INSERT INTO [449_STAGING].dbo.Team(id,full_name,abbreviation,nickname,city,[state],year_founded)
	SELECT id,full_name,abbreviation,nickname,city,[state],year_founded
	FROM [449_NBA].dbo.team;

INSERT INTO [449_STAGING].dbo.Game(game_id,season_id,matchup,season_type)
	SELECT game_id,season_id,matchup_home,season_type
	FROM [449_NBA].dbo.game;

INSERT INTO [449_STAGING].dbo.[Date](date_id,[day],[month],[year])
	SELECT game_id,DATEPART(day,game_date),DATEPART(month,game_date),DATEPART(year,game_date)
	FROM [449_NBA].dbo.game;


--WIN/LOSE STREAK yapýldý.

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


