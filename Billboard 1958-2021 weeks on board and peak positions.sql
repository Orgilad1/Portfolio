Select *
From [Billboard Chart info 1958-2021]

--How many songs in total have peaked at no.1?

Select count(distinct song) as Total_songs_at_number_one
From [Billboard Chart info 1958-2021]
where [peak-rank] = '1' 

--Which songs entered the chart straight to no.1?
Select date, artist, song
From [Billboard Chart info 1958-2021]
where [last-week] is NULL and [peak-rank] = '1' and [weeks-on-board] = '1'
Order by 1

--Which artist had the most no.1 songs?
SELECT artist, COUNT(DISTINCT song) as number_of_songs_at_number_one
FROM [Billboard Chart info 1958-2021]
Where [peak-rank] = 1
Group by artist
Order by number_of_songs_at_number_one desc


--Which songs have spent the most weeks on board and what was their peak rank?

SELECT song, artist, MAX([weeks-on-board]) as most_weeks, min([peak-rank]) as peak_rank
FROM [Billboard Chart info 1958-2021]
GROUP BY song, artist
Order by most_weeks desc

--How many songs have spent a year (52 weeks) or more on the chart?

SELECT count(distinct song) as songs_spent_a_year_in_chart
FROM [Billboard Chart info 1958-2021]
Where [weeks-on-board] >= '52'

--How many of them actually picked at no.1?
SELECT count(distinct song) as number_of_songs
FROM [Billboard Chart info 1958-2021]
Where [weeks-on-board] >= '52' and [peak-rank]='1'

--Which ones?

SELECT artist, song, Max([weeks-on-board]) as weeks_on_board
FROM [Billboard Chart info 1958-2021]
Where [weeks-on-board] >= '52' and [peak-rank]='1'
Group by artist, song

--Let us compare the chart ranks of The Beatles vs The Rolling Stones.

--Which Beatles songs have spent the longest on the chart?

SELECT song, artist, MAX([weeks-on-board]) as most_weeks, min([peak-rank]) as peak_rank
FROM [Billboard Chart info 1958-2021]
Where artist = 'The Beatles'
GROUP BY song, artist
Order by most_weeks desc

--Which Rolling Stones songs have spent the longest on the chart?

SELECT song, artist, MAX([weeks-on-board]) as most_weeks, min([peak-rank]) as peak_rank
FROM [Billboard Chart info 1958-2021]
Where artist = 'The Rolling Stones'
GROUP BY song, artist
Order by most_weeks desc

--How many Beatles and Rolling Stones songs have entered the chart all together?

SELECT artist, count(distinct song) as number_of_songs
FROM [Billboard Chart info 1958-2021]
Where artist IN ('The Beatles', 'The Rolling Stones')
Group by artist


--How many Beatles and Rolling Stones songs peaked at No. 1?

SELECT artist, count(distinct song) as songs_at_number_one
FROM [Billboard Chart info 1958-2021]
Where artist IN ('The Beatles', 'The Rolling Stones') and [peak-rank] = 1
Group by artist


-- How many weeks did the songs of each band have spent in total on the chart?
SELECT artist, SUM(highest_weeks_on_board) as total_weeks_on_board
FROM (
    SELECT artist, song, MAX([weeks-on-board]) as highest_weeks_on_board
    FROM [Billboard Chart info 1958-2021]
    WHERE artist IN ('The Beatles', 'The Rolling Stones')
    GROUP BY artist, song
) AS subquery
GROUP BY artist;