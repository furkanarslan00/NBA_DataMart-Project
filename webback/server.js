const sql = require("mssql");

const config = {
    server: "UNSALAILESI",
    database: "449_DW",
    driver: "msnodesqlv8",
    options: {
        trustedConnection: true,
        trustServerCertificate: true,
        encrypt: false,
    },
    user: "admin",
    password: "yukicukichungus",
};

const queries = {
    1: `SELECT DISTINCT t.id, t.full_name AS team_name, p.home_winstreak 
        FROM Performance p 
        JOIN Team t ON t.id = p.home_team_id 
        WHERE p.home_winstreak >= 3 
        ORDER BY p.home_winstreak DESC;`,
    2: `SELECT DISTINCT t.id, t.full_name AS team_name, p.away_winstreak 
        FROM Performance p 
        JOIN Team t ON t.id = p.away_team_id 
        WHERE p.away_winstreak >= 3 
        ORDER BY p.away_winstreak DESC;`,
    3: `SELECT TOP 50 t1.full_name AS home_team, t2.full_name AS away_team, (p.pts_home + p.pts_away) AS total_score 
        FROM Performance p 
        JOIN Team t1 ON t1.id = p.home_team_id 
        JOIN Team t2 ON t2.id = p.away_team_id 
        ORDER BY total_score DESC;`,
    4: `SELECT TOP 5 t.full_name AS team_name, AVG(CAST(p.fg3_pct_home AS FLOAT)) AS avg_fg3_pct 
        FROM Performance p 
        JOIN Team t ON t.id = p.home_team_id 
        JOIN [Date] d ON d.date_id = p.date_id 
        WHERE d.[year] > @year 
        GROUP BY t.full_name 
        ORDER BY avg_fg3_pct DESC;`,
    5: `SELECT TOP 5 team_name, MAX(winstreak) AS max_winstreak 
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
        ORDER BY max_winstreak DESC;`,
    6: `SELECT TOP 5 t.full_name AS team_name, SUM(p.ast_home) AS total_assists 
        FROM Performance p 
        JOIN Team t ON t.id = p.home_team_id 
        GROUP BY t.full_name 
        ORDER BY total_assists DESC;`,
    7: `SELECT CAST(100.0 * SUM(CASE WHEN p.wl_home = 'W' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5, 2)) AS home_win_percentage 
        FROM Performance p;`,
    8: `SELECT DISTINCT t.full_name AS team_name, p.home_losestreak 
        FROM Performance p 
        JOIN Team t ON t.id = p.home_team_id 
        WHERE p.home_losestreak >= 5 
        ORDER BY p.home_losestreak DESC;`,
    9: `SELECT DISTINCT t.full_name AS team_name, p.away_losestreak 
        FROM Performance p 
        JOIN Team t ON t.id = p.away_team_id 
        WHERE p.away_losestreak >= 5 
        ORDER BY p.away_losestreak DESC;`,
    10: `SELECT TOP 5 t.full_name AS team_name, SUM(p.pts_home) AS total_points 
        FROM Performance p 
        JOIN Team t ON t.id = p.home_team_id 
        JOIN Game g ON g.game_id = p.game_id 
        WHERE g.season_id = @year 
        GROUP BY t.full_name 
        ORDER BY total_points DESC;`,
    11: `SELECT TOP 5 t1.full_name AS home_team, p.wl_home as home_winlose, t2.full_name AS away_team, p.wl_away as away_winlose, 
            ABS(p.plus_minus_home) AS score_difference, g.matchup, d.[day], d.[month], d.[year] 
        FROM Performance p 
        JOIN Team t1 ON t1.id = p.home_team_id 
        JOIN Team t2 ON t2.id = p.away_team_id 
        JOIN Game g ON g.game_id = p.game_id 
        JOIN [Date] d ON d.date_id = p.date_id 
        ORDER BY score_difference DESC;`,
};

async function fetchQueryResults(queryId, year = null) {
    try {
        await sql.connect(config);
        const request = new sql.Request();

        if (year !== null) {
            request.input("year", sql.Int, year);
        }

        const query = queries[queryId];
        const result = await request.query(query);

        return result.recordset;
    } catch (err) {
        console.error("Error fetching query results:", err);
        return [];
    }
}

const express = require("express");
const app = express();
const cors = require("cors");

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>SQL Query Results</title>
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css">
        </head>
        <body>
            <div class="container">
                <h1 class="text-center">SQL Query Results</h1>
                <div class="mb-4">
                    <label for="querySelector" class="form-label">Select Query:</label>
                    <select id="querySelector" class="form-select">
                        <option value="1">Query 1 - Home Win Streak</option>
                        <option value="2">Query 2 - Away Win Streak</option>
                        <option value="3">Query 3 - Total Scores</option>
                        <option value="4">Query 4 - Avg FG3% (Year > Input)</option>
                        <option value="5">Query 5 - Max Win Streak</option>
                        <option value="6">Query 6 - Total Assists</option>
                        <option value="7">Query 7 - Home Win Percentage</option>
                        <option value="8">Query 8 - Home Lose Streak</option>
                        <option value="9">Query 9 - Away Lose Streak</option>
                        <option value="10">Query 10 - Total Points (Season)</option>
                        <option value="11">Query 11 - Score Differences</option>
                    </select>
                </div>
                <div id="yearInputContainer" class="mb-4" style="display: none;">
                    <label for="yearInput" class="form-label">Enter Year:</label>
                    <input type="number" id="yearInput" class="form-control" placeholder="e.g., 2020">
                </div>
                <button id="fetchButton" class="btn btn-primary mb-4">Fetch Results</button>
                <div id="resultsContainer"></div>
            </div>

            <script>
                document.addEventListener("DOMContentLoaded", () => {
                    const querySelector = document.getElementById("querySelector");
                    const yearInputContainer = document.getElementById("yearInputContainer");
                    const yearInput = document.getElementById("yearInput");
                    const fetchButton = document.getElementById("fetchButton");
                    const resultsContainer = document.getElementById("resultsContainer");

                    querySelector.addEventListener("change", () => {
                        if (querySelector.value === "4" || querySelector.value === "10") {
                            yearInputContainer.style.display = "block";
                        } else {
                            yearInputContainer.style.display = "none";
                        }
                    });

                    fetchButton.addEventListener("click", async () => {
                        const queryId = querySelector.value;
                        const year = yearInputContainer.style.display === "block" ? yearInput.value : null;

                        const response = await fetch("/query", {
                            method: "POST",
                            headers: {
                                "Content-Type": "application/json",
                            },
                            body: JSON.stringify({ queryId, year }),
                        });

                        const data = await response.json();
                        renderResults(data);
                    });

                    function renderResults(data) {
                        if (!data.length) {
                            resultsContainer.innerHTML = "<p>No results found.</p>";
                            return;
                        }

                        const table = document.createElement("table");
                        table.className = "table table-striped";

                        const thead = document.createElement("thead");
                        const headerRow = document.createElement("tr");

                        Object.keys(data[0]).forEach((key) => {
                            const th = document.createElement("th");
                            th.textContent = key;
                            headerRow.appendChild(th);
                        });

                        thead.appendChild(headerRow);
                        table.appendChild(thead);

                        const tbody = document.createElement("tbody");

                        data.forEach((row) => {
                            const tr = document.createElement("tr");
                            Object.values(row).forEach((value) => {
                                const td = document.createElement("td");
                                td.textContent = value;
                                tr.appendChild(td);
                            });
                            tbody.appendChild(tr);
                        });

                        table.appendChild(tbody);
                        resultsContainer.innerHTML = "";
                        resultsContainer.appendChild(table);
                    }
                });
            </script>
        </body>
        </html>
    `);
});

// Query sonuçlarını döndüren API
app.post("/query", async (req, res) => {
    const { queryId, year } = req.body;
    const results = await fetchQueryResults(queryId, year);
    res.json(results);
});

// Sunucuyu başlat
app.listen(3000, () => {
    console.log("Server running on http://localhost:3000");
});

