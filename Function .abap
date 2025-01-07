FUNCTION z_get_flights.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(CITYFROM) TYPE  SPFLI-CITYFROM
*"     REFERENCE(CITYTO) TYPE  SPFLI-CITYTO
*"     REFERENCE(DATEFROM) TYPE  SFLIGHT-FLDATE
*"     REFERENCE(CLASS_TYPE) TYPE  CHAR1 DEFAULT 'E'
*"     REFERENCE(NO_OF_PASS) TYPE  ZAD_D_NO_OF_PASS DEFAULT 1
*"  TABLES
*"      ET_FLIGHTS STRUCTURE  ZAD_S_FLIGHTS01
*"----------------------------------------------------------------------


  IF class_type = 'E'.
    SELECT sf~connid,
           sp~cityfrom,
           sp~cityto,
           sf~carrid ,
           sc~carrname,
           sf~fldate,
           sp~fltime,
           sp~distance,
           sp~distid,
          ( sf~seatsmax - sf~seatsocc ) AS Seat_AV,

           sf~price,
           sf~currency,
           sf~seatsmax AS SEATSMAX_e,
           sf~seatsocc AS SEATSOCC_e,
         ( sf~seatsmax - sf~seatsocc ) AS Seat_AV_ECO

    FROM sflight AS sf INNER JOIN spfli AS sp
                       ON sf~carrid = sp~carrid AND
                          sf~connid = sp~connid
                       INNER JOIN scarr AS sc
                       ON sf~carrid = sc~carrid
                       WHERE sp~cityfrom = @cityfrom AND
                             sp~cityto =   @cityto   AND
                             sf~fldate =   @datefrom AND
                            ( sf~seatsmax - sf~seatsocc ) >= @no_of_pass
                       INTO CORRESPONDING FIELDS OF TABLE @et_flights.

  ELSEIF class_type  = 'F'.
    SELECT sf~connid,
              sp~cityfrom,
              sp~cityto,
              sf~carrid ,
              sc~carrname,
              sf~fldate,
              sp~fltime,
              sp~distance,
              sp~distid,

              sf~price,
              sf~currency,
              sf~seatsmax_f AS seatsmax_f,
              sf~seatsocc_f AS seatsocc_f,
             ( sf~seatsmax_f - sf~seatsocc_f  ) AS seat_av
       FROM sflight AS sf INNER JOIN spfli AS sp
                          ON sf~carrid = sp~carrid AND
                             sf~connid = sp~connid
                          INNER JOIN scarr AS sc
                          ON sf~carrid = sc~carrid
                          WHERE sp~cityfrom = @cityfrom AND
                                sp~cityto =   @cityto   AND
                                sf~fldate =   @datefrom AND
                               ( sf~seatsmax_f - sf~seatsocc_f ) >= @no_of_pass
                          INTO CORRESPONDING FIELDS OF TABLE @et_flights.
  ELSEIF class_type  = 'B'.
    SELECT sf~connid,
               sp~cityfrom,
               sp~cityto,
               sf~carrid ,
               sc~carrname,
               sf~fldate,
               sp~fltime,
               sp~distance,
               sp~distid,
              ( sf~seatsmax_B - sf~seatsocc_B  ) AS Seat_AV,

               sf~price,
               sf~currency,
               sf~seatsmax_b,
               sf~seatsocc_b
        FROM sflight AS sf INNER JOIN spfli AS sp
                           ON sf~carrid = sp~carrid AND
                              sf~connid = sp~connid
                           INNER JOIN scarr AS sc
                           ON sf~carrid = sc~carrid
                           WHERE sp~cityfrom = @cityfrom AND
                                 sp~cityto =   @cityto   AND
                                 sf~fldate =   @datefrom AND
                                  ( sf~seatsmax_b - sf~seatsocc_b ) >= @no_of_pass
                           INTO CORRESPONDING FIELDS OF TABLE @et_flights.
  ELSE.
  ENDIF.


  LOOP AT et_flights INTO DATA(ls_flights) .
    ls_flights-no_of_pass = no_of_pass.
    ls_flights-total_price = no_of_pass * ls_flights-price.
    MODIFY et_flights FROM ls_flights.
  ENDLOOP.


  "SPFLI SCARR SFLIGHT


ENDFUNCTION.