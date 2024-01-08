
Select * from RaysPitching.Dbo.RaysPitchingStats

Select * from RaysPitching.Dbo.LastPitchRays

--Question 1 AVG Pitches Per at Bat Analysis

--1a AVG Pitches Per At Bat (LastPitchRays)

SELECT AVG(1.00*Pitch_number) Avg_Num_of_Pitches_Per_At_Bat
FROM RaysPitching.Dbo.LastPitchRays

--1b AVG Pitches Per At Bat Home Vs Away
SELECT 
	'Home' TypeofGame,
	AVG(1.00 * Pitch_number) Avg_Num_of_Pitches_Per_At_Bat
FROM RaysPitching.Dbo.LastPitchRays
Where home_team = 'TB'
UNION
SELECT 
	'Away' TypeofGame,
	AVG(1.00 * Pitch_number) Avg_Num_of_Pitches_Per_At_Bat
FROM RaysPitching.Dbo.LastPitchRays
Where away_team = 'TB'      

--1c AVG Pitches Per At Bat Lefty Vs Righty

SELECT
      AVG(Case when batter_position='L' Then 1.00*Pitch_number end) LeftyatBat,
	  AVG(Case when batter_position='R' Then 1.00*Pitch_number end) RightyatBat
FROM RaysPitching.Dbo.LastPitchRays

--1d AVG Pitches Per At Bat Lefty Vs Righty Pitcher | Each Away Team

SELECT DISTINCT 
       home_team,
	   Pitcher_Position,
	   AVG(1.00*Pitch_number) OVER(Partition By home_team, Pitcher_Position) Avg_num_of_pitches
FROM RaysPitching.Dbo.LastPitchRays
WHERE away_team='TB'

--1e Top 3 Most Common Pitch for at bat 1 through 10, and total amounts

With totalpitchsequence as(
           SELECT DISTINCT
		          Pitch_name,
				  Pitch_number,
				  Count(Pitch_name) Over(Partition by Pitch_name, Pitch_number) PitchFrequency
		   FROM RaysPitching.Dbo.LastPitchRays
		   WHERE Pitch_number<11
),
pitchfrequencyrankquery as(
           SELECT
		        Pitch_name,
				Pitch_number,
				Pitchfrequency,
				Rank() Over(Partition by Pitch_number Order by Pitchfrequency DESC) PitchFrequencyranking
           FROM totalpitchsequence
)
SELECT * FROM pitchfrequencyrankquery
WHERE PitchFrequencyranking<4


--1f AVG Pitches Per at Bat Per Pitcher with 20+ Innings

SELECT 
     RPS.Name,
	 AVG(1.00*Pitch_number) AVGPitches
 FROM RaysPitching.Dbo.LastPitchRays LPR
 JOIN RaysPitching.Dbo.RaysPitchingStats RPS ON RPS.pitcher_id=LPR.pitcher
 WHERE IP>=20
 GROUP BY RPS.Name
 ORDER BY AVG(1.00*Pitch_number) DESC

 --2a Count of the Last Pitches Thrown in Desc Order

 SELECT pitch_name, COUNT(*) timesthrown
 FROM RaysPitching.Dbo.LastPitchRays
 GROUP BY pitch_name
 ORDER BY COUNT(*) DESC

 --2b Count of the different last pitches Fastball or Offspeed

 SELECT
      sum(case when pitch_name in ('4-Seam Fastball','Cutter') then 1 else 0 end) Fastball,
	  sum(case when pitch_name Not in ('4-Seam Fastball','Cutter') then 1 else 0 end) offspeed
 FROM RaysPitching.Dbo.LastPitchRays

--2c Percentage of the different last pitches Fastball or Offspeed

SELECT
     100*sum(case when pitch_name in ('4-Seam Fastball','Cutter') then 1 else 0 end)/count(*) Fastball,
	 100*sum(case when pitch_name Not in ('4-Seam Fastball','Cutter') then 1 else 0 end)/count(*) offspeed
 FROM RaysPitching.Dbo.LastPitchRays


 --2d Top 5 Most common last pitch for a Relief Pitcher vs Starting Pitcher

 SELECT *
 FROM (
	        SELECT 
			      a.POS,
				  a.pitch_name,
				  a.timesthrown,
				  RANK() Over(Partition by a.POS order by a.timesthrown DESC) PitchRank
			FROM (
			     SELECT RPS.POS, LPR.pitch_name, count(*) timesthrown
				 FROM RaysPitching.Dbo.LastPitchRays LPR
				 JOIN RaysPitching.Dbo.RaysPitchingStats RPS on RPS.pitcher_id=LPR.pitcher
				 Group by RPS.POS, LPR.pitch_name
			) a
		) b
 Where b.PitchRank<6
			   

--3a What pitches have given up the most HRs 

SELECT pitch_name, Count(*) HRs
 From RaysPitching.Dbo.LastPitchRays
 Where events='home_run'
 Group by pitch_name
 Order by Count(*) desc


 --3b Show HRs given up by zone and pitch, show top 5 most common

 SELECT Top 5 zone, pitch_name, count(*) HRs
 From RaysPitching.Dbo.LastPitchRays
 Where events='home_run'
 Group by zone, pitch_name
 Order by Count(*) desc


 --3c Show HRs for each count type -> Balls/Strikes + Type of Pitcher


  SELECT RPS.POS, LPR.balls, LPR.strikes, Count(*) HRs
  FROM RaysPitching.Dbo.LastPitchRays LPR
  JOIN RaysPitching.Dbo.RaysPitchingStats RPS on RPS.pitcher_id=LPR.pitcher
  Where events='home_run'
  Group by RPS.POS, LPR.balls, LPR.strikes
  Order by Count(*) Desc


 --3d Show Each Pitchers Most Common count to give up a HR (Min 30 IP)
  

 with hrcountpitchers as (
  SELECT RPS.Name, LPR.balls, LPR.strikes, Count(*) HRs
  FROM RaysPitching.Dbo.LastPitchRays LPR
  JOIN RaysPitching.Dbo.RaysPitchingStats RPS on RPS.pitcher_id=LPR.pitcher
  Where events='home_run' and IP>=30
  Group by RPS.Name, LPR.balls, LPR.strikes
  ),
  hrcountranks as (
       SELECT 
		hcp.Name,
		hcp.balls,
		hcp.strikes,
		hcp.HRs,
		rank() Over(Partition by Name order by HRs desc) hrrank
		From hrcountpitchers hcp
)
  SELECT ht.Name, ht.balls, ht.strikes, ht.HRs
  From hrcountranks ht
  Where hrrank=1


  --Question 4 Shane McClanahan

  --4a AVG Release speed, spin rate,  strikeouts, most popular zone

  SELECT
       AVG(Release_speed) avgreleasespeed,
	   Avg(release_spin_rate) avgspinrate,
	   Sum(Case when events='strikeout' then 1 else 0 end) strikeouts,
	   Max(Zones.zone) as zone
  FROM RaysPitching.Dbo.LastPitchRays LPR
  JOIN (

        SELECT Top 1 pitcher, zone, count(*) zonenum
		FROM RaysPitching.Dbo.LastPitchRays LPR
		where player_name='McClanahan, Shane'
		Group by pitcher, zone
		Order by count(*) desc
	) zones on zones.pitcher=LPR.pitcher
    where player_name = 'McClanahan, Shane'
 
        

--4b top pitches for each infield position where total pitches are over 5

 SELECT *
 FROM (
      SELECT pitch_name, count(*) timeshit, 'Third' Position
	  FROM RaysPitching.Dbo.LastPitchRays
	  Where hit_location= 5 and player_name= 'McClanahan, Shane'
	  Group by pitch_name
	  Union
	  SELECT pitch_name, count(*) timeshit, 'Short' Position
	  FROM RaysPitching.Dbo.LastPitchRays
	  Where hit_location= 6 and player_name= 'McClanahan, Shane'
	  Group by pitch_name
	  Union 
	  SELECT pitch_name, count(*) timeshit, 'Second' Position
	  FROM RaysPitching.Dbo.LastPitchRays
	  Where hit_location= 4 and player_name= 'McClanahan, Shane'
	  Group by pitch_name
	  Union
	  SELECT pitch_name, count(*) timeshit, 'First' Position
	  FROM RaysPitching.Dbo.LastPitchRays
	  Where hit_location= 3 and player_name= 'McClanahan, Shane'
	  Group by pitch_name
	  ) a
	Where timeshit>4
	Order by timeshit desc


--4c Show different balls/strikes as well as frequency when someone is on base


 SELECT balls, strikes, count(*) frequency
 FROM RaysPitching.Dbo.LastPitchRays
 Where (on_3b is NOT NULL or on_2b is NOT NULL or on_1b is NOT NULL) and
 player_name='McClanahan, Shane'
 Group by balls, strikes
 Order by count(*) desc


 --4d What pitch causes the lowest launch speed


  SELECT pitch_name, ROUND(avg(1.00*launch_speed),2) LaunchSpeed
  FROM RaysPitching.Dbo.LastPitchRays
  Where player_name='McClanahan, Shane'
  Group by pitch_name
  Order by AVG(launch_speed)

