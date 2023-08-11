create or replace view V_CIVIL_CALENDAR_V10(
	CALNDR_DT,
	DAY_NBR_OF_MONTH,
	DAY_NBR_OF_YEAR,
	MONTH_NBR,
	YEAR_NBR,
	DAY_EN_NAME,
	DAY_FR_NAME,
	MONTH_EN_NAME,
	MONTH_FR_NAME,
	MONTH_LAST_CALNDR_DT,
	MONTH_LAST_BUSNS_DT,
	PREVS_MONTH_LAST_BUSNS_DT,
	CURNT_BUSNS_DT,
	MONTH_FIRST_BUSNS_DT,
	IS_WK_FLAG,
	IS_WKND_FLAG,
	PERD_COMPTB_ID
) as
(
select  
    calndr_dt
    ,DATE_PART(day,calndr_dt) as day_nbr_of_month
    ,DATE_PART(dayofyear,calndr_dt) as day_nbr_of_year
    ,DATE_PART(month,calndr_dt) as month_nbr
    ,DATE_PART(year,calndr_dt) as year_nbr
    
    ,DECODE(
        DATE_PART(dayofweek_iso,calndr_dt),
        1, 'Monday',
        2, 'Tuesday',
        3, 'Wednesday',
        4, 'Thursday',
        5, 'Friday',
        6, 'Saturday',
        7, 'Sunday') 
     as day_en_name
        
    ,DECODE(
        DATE_PART(dayofweek_iso,calndr_dt),
        1, 'Lundi',
        2, 'Mardi',
        3, 'Mercredi',
        4, 'Jeudi',
        5, 'Vendredi',
        6, 'Samedi',
        7, 'Dimanche') 
     as day_fr_name
        
    ,DECODE(
        DATE_PART(month,calndr_dt),
        1,  'January',
        2,  'February',
        3,  'March',
        4,  'April',
        5,  'May',
        6,  'June',
        7,  'July',
        8,  'August',
        9,  'September',
        10, 'October',
        11, 'November',
        12, 'December')
      as month_en_name 
      
    ,DECODE(
        DATE_PART(month,calndr_dt),
       1,  'janvier',
       2,  'février',
       3,  'mars',
       4,  'avril',
       5,  'mai',
       6,  'juin',
       7,  'juillet',
       8,  'août',
       9,  'septembre',
       10, 'octobre',
       11, 'novembre',
       12, 'décembre')
     as month_fr_name
     
    ,LAST_DAY(calndr_dt) as month_last_calndr_dt
    
    ,CASE
        WHEN DATE_PART(dayofweek_iso,LAST_DAY(calndr_dt)) = 7 THEN DATEADD(DAY,-2,LAST_DAY(calndr_dt))
        WHEN DATE_PART(dayofweek_iso,LAST_DAY(calndr_dt)) = 6 THEN DATEADD(DAY,-1,LAST_DAY(calndr_dt))
        ELSE LAST_DAY (calndr_dt)
    END
     as month_last_busns_dt

    ,CASE
        WHEN DATE_PART(dayofweek_iso,LAST_DAY(DATEADD(MONTHS,-1,calndr_dt))) = 7 THEN DATEADD(DAY,-2,LAST_DAY(DATEADD(MONTHS,-1,calndr_dt)))
        WHEN DATE_PART(dayofweek_iso,LAST_DAY(DATEADD(MONTHS,-1,calndr_dt))) = 6 THEN DATEADD(DAY,-1,LAST_DAY(DATEADD(MONTHS,-1,calndr_dt)))
        ELSE LAST_DAY(DATEADD(MONTHS,-1,calndr_dt))
    END
     as prevs_month_last_busns_dt
     
    -- Le 25 décembre et le 1er janvier sont des exceptions
    -- Ces dates sont considérées au même titre que les samedi et dimanche
    ,CASE
        -- Dimanche
        WHEN DATE_PART(dayofweek_iso,calndr_dt) = 7
         THEN( 
           CASE
             -- Si la date calendrier est un dimanche et qu'on enleve 2 jours et qu'on tombe sur le 25 décembre ou le 1er janvier il faut enlever une journee supplementaire
            WHEN (DATE_PART(month,DATEADD(day,-2,calndr_dt)) = 12 AND DATE_PART(day,DATEADD(day,-2,calndr_dt)) = 25) OR (DATE_PART(month,DATEADD(day,-2,calndr_dt)) = 1 AND DATE_PART(day,DATEADD(day,-2,calndr_dt)) = 1)
                THEN DATEADD(day,-3,calndr_dt)
            ELSE DATEADD(day,-2,calndr_dt)
           END
         )
          
        -- Samedi
        WHEN DATE_PART(dayofweek_iso,calndr_dt) = 6
         THEN(
           CASE
             -- Si la date calendrier est un samedi et qu'on enleve 1 journée et qu'on tombe sur le 25 décembre ou le 1er janvier il faut enlever une journee supplementaire
            WHEN (DATE_PART(month,DATEADD(day,-1,calndr_dt)) = 12 AND DATE_PART(day,DATEADD(day,-1,calndr_dt)) = 25) OR (DATE_PART(month,DATEADD(day,-1,calndr_dt)) = 1 AND DATE_PART(day,DATEADD(day,-1,calndr_dt)) = 1)
                THEN DATEADD(day,-2,calndr_dt)
            ELSE DATEADD(day,-1,calndr_dt)
           END
         )
         
        -- Lundi au Vendredi
        ELSE(
          CASE
            -- Si on est le 25 décembre ou le 1er janvier et que ces journées tombent un lundi, on retourne au vendredi (-3 jours)
            WHEN ((DATE_PART(month,calndr_dt) = 12 AND DATE_PART(day,calndr_dt) = 25) OR (DATE_PART(month,calndr_dt) = 1 AND DATE_PART(day,calndr_dt) = 1)) AND (DATE_PART(dayofweek_iso,calndr_dt) = 1)
                THEN DATEADD(day,-3,calndr_dt)
            WHEN ((DATE_PART(month,calndr_dt) = 12 AND DATE_PART(day,calndr_dt) = 25) OR (DATE_PART(month,calndr_dt) = 1 AND DATE_PART(day,calndr_dt) = 1)) AND (DATE_PART(dayofweek_iso,calndr_dt) != 1)
                THEN DATEADD(day,-1,calndr_dt)
            ELSE calndr_dt
          END
        )
    END
     as curnt_busns_dt
    ,CASE
         -- Lorsque le 1er janvier tombe un vendredi, faire + 3 jours à partir du 1er janvier.
        WHEN (DATE_PART(month,calndr_dt) = 1 AND DATE_PART(dayofweek_iso,DATE_FROM_PARTS(YEAR(calndr_dt),1,1)) = 5) THEN DATEADD(day,3,DATE_FROM_PARTS(YEAR(calndr_dt),1,1))
        -- Lorsque tu es au mois de janvier et c'est un lundi,mardi,mercredi ou jeudi alors +1 jour à partir du 1er janvier.
        WHEN (DATE_PART(month,calndr_dt) = 1 AND DATE_PART(dayofweek_iso,DATE_FROM_PARTS(YEAR(calndr_dt),1,1)) IN (1,2,3,4)) THEN DATEADD(day,1,DATE_FROM_PARTS(YEAR(calndr_dt),1,1))
          -- Lorsque le premier du mois es un dimanche, faire +1 jour
        WHEN (DATE_PART(dayofweek_iso,DATE_FROM_PARTS(YEAR(calndr_dt),DATE_PART(month,calndr_dt),1)) = 7) THEN DATEADD(day,1,DATE_FROM_PARTS(YEAR(calndr_dt),DATE_PART(month,calndr_dt),1))
         -- Lorsque le premier du mois es un samedi, faire +2 jours  
        WHEN (DATE_PART(dayofweek_iso,DATE_FROM_PARTS(YEAR(calndr_dt),DATE_PART(month,calndr_dt),1)) = 6) THEN DATEADD(day,2,DATE_FROM_PARTS(YEAR(calndr_dt),DATE_PART(month,calndr_dt),1))
        -- Lorsque le premier jour du mois tombe un jour de semaine.
        ELSE DATE_FROM_PARTS(YEAR(calndr_dt),DATE_PART(month,calndr_dt),1)
    END
     as month_first_busns_dt

    ,CASE WHEN DATE_PART(dayofweek_iso,calndr_dt) not in (6,7) THEN 1 ELSE 0 END as is_wk_flag
    ,CASE WHEN DATE_PART(dayofweek_iso,calndr_dt) in (6,7) THEN 1 ELSE 0 END as is_wknd_flag
	,year(calndr_dt)*100 + month(calndr_dt) as perd_comptb_id
from
    ml_interne.xrf_civil_calendar);