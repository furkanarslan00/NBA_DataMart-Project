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

INSERT INTO [449_DW].dbo.Team(id,full_name,abbreviation,nickname,city,[state],year_founded)
	SELECT id,full_name,abbreviation,nickname,city,[state],year_founded
	FROM [449_STAGING].dbo.Team;

INSERT INTO [449_DW].dbo.Game(game_id,season_id,matchup,season_type)
	SELECT game_id,season_id,matchup,season_type
	FROM [449_STAGING].dbo.Game;

INSERT INTO [449_DW].dbo.[Date](date_id,[day],[month],[year])
	SELECT date_id,[day],[month],[year]
	FROM [449_STAGING].dbo.[Date];

INSERT INTO Performance(home_team_id,away_team_id,game_id,date_id,wl_home,[min],
	fgm_home,fga_home,fg_pct_home,fg3m_home,fg3a_home,
    fg3_pct_home,ftm_home,fta_home,ft_pct_home,oreb_home,dreb_home,reb_home,
    ast_home,stl_home,blk_home,tov_home,pf_home,pts_home,plus_minus_home,wl_away,
    fgm_away,fga_away,fg_pct_away,fg3m_away,fg3a_away,fg3_pct_away,ftm_away,
    fta_away,ft_pct_away,oreb_away,dreb_away,reb_away,ast_away,stl_away,blk_away,tov_away,pf_away,pts_away,
    plus_minus_away,home_performance,away_performance,home_winstreak,home_losestreak, 
	away_winstreak, away_losestreak)
	SELECT home_team_id,away_team_id,game_id,date_id,wl_home,[min],
	fgm_home,fga_home,fg_pct_home,fg3m_home,fg3a_home,
    fg3_pct_home,ftm_home,fta_home,ft_pct_home,oreb_home,dreb_home,reb_home,
    ast_home,stl_home,blk_home,tov_home,pf_home,pts_home,plus_minus_home,wl_away,
    fgm_away,fga_away,fg_pct_away,fg3m_away,fg3a_away,fg3_pct_away,ftm_away,
    fta_away,ft_pct_away,oreb_away,dreb_away,reb_away,ast_away,stl_away,blk_away,tov_away,pf_away,pts_away,
    plus_minus_away,home_performance,away_performance,home_winstreak,home_losestreak, 
	away_winstreak, away_losestreak
	FROM [449_STAGING].dbo.Performance;


--Sonraki maçlarý kazanma ihtimali yüksek olan ev sahibi takýmlar hangileri?
SELECT DISTINCT t.id, t.full_name AS team_name, p.home_winstreak
FROM Performance p
JOIN Team t ON t.id = p.home_team_id
WHERE p.home_winstreak >= 3
ORDER BY p.home_winstreak desc;

--Sonraki maçlarý kazanma ihtimali yüksek olan deplasman takýmlarý hangileri?
SELECT DISTINCT t.id, t.full_name AS team_name, p.away_winstreak
FROM Performance p
JOIN Team t ON t.id = p.away_team_id
WHERE p.away_winstreak >= 3
ORDER BY p.away_winstreak desc;

--En yüksek toplam skoru yapan takýmlar hangileri?
SELECT TOP 50 
    t1.full_name AS home_team, 
    t2.full_name AS away_team, 
    (p.pts_home + p.pts_away) AS total_score
FROM Performance p
JOIN Team t1 ON t1.id = p.home_team_id
JOIN Team t2 ON t2.id = p.away_team_id
ORDER BY total_score DESC;


--2010'dan sonra En iyi 3 sayý yüzdesine sahip takýmlar hangileri?
SELECT TOP 5 
    t.full_name AS team_name, 
    AVG(CAST(p.fg3_pct_home AS FLOAT)) AS avg_fg3_pct
FROM Performance p
JOIN Team t ON t.id = p.home_team_id
JOIN [Date] d ON d.date_id = p.date_id
WHERE (d.[year]>2010)
GROUP BY t.full_name
ORDER BY avg_fg3_pct DESC;


--En fazla galibiyet serisi olan takýmlar hangileri?
SELECT TOP 5 
    team_name, 
    MAX(winstreak) AS max_winstreak
FROM (
    SELECT t.full_name AS team_name, p.home_winstreak AS winstreak
    FROM Performance p
    JOIN Team t ON t.id = p.home_team_id
    UNION ALL
    SELECT t.full_name AS team_name, p.away_winstreak AS winstreak
    FROM Performance p
    JOIN Team t ON t.id = p.away_team_id
) AS streaks
GROUP BY team_name
ORDER BY max_winstreak DESC;

--Maçlarda en fazla asist yapan takým hangisi?
SELECT TOP 5 
    t.full_name AS team_name, 
    SUM(p.ast_home) AS total_assists
FROM Performance p
JOIN Team t ON t.id = p.home_team_id
GROUP BY t.full_name
ORDER BY total_assists DESC;


--Maç kazanmada ev sahibi avantajý ne kadar önemli?
SELECT 
    CAST(100.0 * SUM(CASE WHEN p.wl_home = 'W' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5, 2)) AS home_win_percentage
FROM Performance p;


--Son 5 maçta performansý düþen ev sahibi takýmlar hangileri?
SELECT DISTINCT t.full_name AS team_name, p.home_losestreak
FROM Performance p
JOIN Team t ON t.id = p.home_team_id
WHERE p.home_losestreak >= 5
ORDER BY p.home_losestreak DESC;

--Son 5 maçta performansý düþen deplasman takýmlarý hangileri?
SELECT DISTINCT t.full_name AS team_name, p.away_losestreak
FROM Performance p
JOIN Team t ON t.id = p.away_team_id
WHERE p.away_losestreak >= 5
ORDER BY p.away_losestreak DESC;


--(Bir sezondaki) en skorer takým hangisi?
SELECT TOP 5 
    t.full_name AS team_name, 
    SUM(p.pts_home) AS total_points
FROM Performance p
JOIN Team t ON t.id = p.home_team_id
JOIN Game g ON g.game_id = p.game_id
WHERE g.season_id = 2010 -- Örnek sezon
GROUP BY t.full_name
ORDER BY total_points DESC;

--Tarihteki en yüksek farkla kazanýlan maçlar hangileri?
SELECT TOP 5 
    t1.full_name AS home_team, 
	p.wl_home as home_winlose,
    t2.full_name AS away_team, 
	p.wl_away as away_winlose,
    ABS(p.plus_minus_home) AS score_difference, 
    g.matchup,
	d.[day],
	d.[month],
	d.[year]
FROM Performance p
JOIN Team t1 ON t1.id = p.home_team_id
JOIN Team t2 ON t2.id = p.away_team_id
JOIN Game g ON g.game_id = p.game_id
JOIN [Date] d ON d.date_id = p.date_id
ORDER BY score_difference DESC;


--Home Ýken Ortalama Performansý En Yüksek Takýmlar
SELECT TOP 10 
    t.full_name AS team_name,
    AVG(p.home_performance) AS avg_home_performance
FROM Performance p
JOIN Team t ON t.id = p.home_team_id
GROUP BY t.full_name
ORDER BY avg_home_performance DESC;

--Away Ýken Ortalama Performansý En Yüksek 10 Takým
SELECT TOP 10 
    t.full_name AS team_name,
    AVG(p.away_performance) AS avg_away_performance
FROM Performance p
JOIN Team t ON t.id = p.away_team_id
GROUP BY t.full_name
ORDER BY avg_away_performance DESC;


--Home Ýken Ortalama Performansý En Düþük 10 Takým
SELECT TOP 10 
    t.full_name AS team_name,
    AVG(p.home_performance) AS avg_home_performance
FROM Performance p
JOIN Team t ON t.id = p.home_team_id
GROUP BY t.full_name
ORDER BY avg_home_performance ASC;

--Away Ýken Ortalama Performansý En Düþük 10 Takým
SELECT TOP 10 
    t.full_name AS team_name,
    AVG(p.away_performance) AS avg_away_performance
FROM Performance p
JOIN Team t ON t.id = p.away_team_id
GROUP BY t.full_name
ORDER BY avg_away_performance ASC;
