*&---------------------------------------------------------------------*
*& Report Z_FLIGHT_SEARCH_ADEM
*&---------------------------------------------------------------------*
REPORT z_flight_search_adem.

*&---------------------------------------------------------------------*
*& Veri Tipleri ve Sabitler
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_flight,
         carrid     TYPE sflight-carrid,
         carrname   TYPE scarr-carrname,
         fldate     TYPE sflight-fldate,
         distance   TYPE zsdist-distance,
         seats      TYPE i,
         price      TYPE sflight-price,
         total_fare TYPE p DECIMALS 2,
       END OF ty_flight.

DATA: lt_flights TYPE TABLE OF sflight,
      ls_flight  TYPE sflight,
      lt_display TYPE TABLE OF ty_flight,
      ls_display TYPE ty_flight,
      gr_alv     TYPE REF TO cl_salv_table.

*&---------------------------------------------------------------------*
*& Ekran Seçim Alanları
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_city1 TYPE spfli-cityfrom OBLIGATORY,
              p_city2 TYPE spfli-cityto OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  PARAMETERS: p_1w    RADIOBUTTON GROUP gr1,
              p_r     RADIOBUTTON GROUP  gr1,

              p_date  TYPE sflight-fldate OBLIGATORY,
              p_retdt TYPE sflight-fldate.
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-003.
  PARAMETERS:

    p_pass  TYPE sflight-seatsocc DEFAULT 1,

    p_eco   RADIOBUTTON GROUP gr2,
    p_first RADIOBUTTON GROUP gr2,
    p_buss  RADIOBUTTON GROUP gr2.

SELECTION-SCREEN END OF BLOCK b3.

SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME TITLE TEXT-004.
  PARAMETERS:

    p_totf TYPE xfeld,
    p_disc TYPE xfeld.

SELECTION-SCREEN END OF BLOCK b4.



**&---------------------------------------------------------------------*
**& Başlangıç Seçimi
**&---------------------------------------------------------------------*




START-OF-SELECTION.
  DATA : gt_flights_1 LIKE TABLE OF zad_s_flights01.
  DATA : gt_flights_2 LIKE TABLE OF zad_s_flights01.
  DATA : gt_flights_all LIKE TABLE OF zad_s_flights01.

  IF p_r = 'X' AND p_retdt IS INITIAL.
    MESSAGE 'Please fill return date.' TYPE 'E'.
  ENDIF.
  IF p_eco = 'X'.
    DATA(class_type) = 'E'.
  ELSEIF p_first = 'X'.
    class_type = 'F'.
  ELSEIF p_buss = 'X'.
    class_type = 'B'.
  ENDIF.

  CALL FUNCTION 'Z_GET_FLIGHTS'
    EXPORTING
      cityfrom   = p_city1
      cityto     = p_city2
      datefrom   = p_date
      class_type = class_type
      no_of_pass = p_pass
    TABLES
      et_flights = gt_flights_1.
  IF gt_flights_1[] IS INITIAL.
    MESSAGE 'There is no one way flight.' TYPE 'E'.
  ENDIF.

  IF  p_r = 'X' AND gt_flights_1[] IS NOT INITIAL.
    CALL FUNCTION 'Z_GET_FLIGHTS'
      EXPORTING
        cityfrom   = p_city2
        cityto     = p_city1
        datefrom   = p_retdt
        class_type = class_type
        no_of_pass = p_pass
      TABLES
        et_flights = gt_flights_2.
    IF gt_flights_2[] IS INITIAL.
      MESSAGE 'There is no return flight.' TYPE 'E'.
    ENDIF.

  ENDIF.

  gt_flights_all[] = gt_flights_1[].
  IF gt_flights_2[] IS NOT INITIAL.
    LOOP AT gt_flights_2[] INTO DATA(ls_flights).
      APPEND ls_flights TO gt_flights_all.
    ENDLOOP.
  ENDIF.
  IF p_disc = 'X'.
    SELECT * FROM zsdist INTO TABLE @DATA(lt_zsdist)
      WHERE ( ( city1 = @p_city1 AND city2 = @p_city2 ) OR
            ( city1 = @p_city2 AND city2 = @p_city1 ) ) AND
            inter_atlantic = 'X'.
    LOOP AT gt_flights_all INTO ls_flights.
      READ TABLE lt_zsdist INTO DATA(ls_zsdist) WITH KEY city1 = ls_flights-cityfrom
                                                         city2 = ls_flights-cityto.
      IF sy-subrc = 0.
        ls_flights-inter_atlantic = 'X'.
        ls_flights-price = ls_flights-price * '0.9'.
        ls_flights-total_price = ls_flights-total_price * '0.9'.
        MODIFY gt_flights_all FROM ls_flights.

      ENDIF.
    ENDLOOP.
  ENDIF.

TRY.
  " ALV nesnesini oluştur
  cl_salv_table=>factory(
    IMPORTING r_salv_table = gr_alv
    CHANGING  t_table      = gt_flights_all ).

  " ALV'deki sütunların referansını al
  DATA(lo_columns) = gr_alv->get_columns( ).

  " Gereksiz Sütünlar gizlenir.
  TRY.
    
    DATA(lo_column) = lo_columns->get_column( 'INTER_ATLANTIC' ).
  lo_column->set_visible( ' ' ).  " ' ' sütunu gizler

  DATA(lo_column1) = lo_columns->get_column( 'SFLIGHT_AV_F' ).
  lo_column1->set_visible( ' ' ).  " ' ' sütunu gizler

  DATA(lo_column2) = lo_columns->get_column( 'SEATSOCC_F' ).
  lo_column2->set_visible( ' ' ).  " ' ' sütunu gizler

IF p_totf = 'X'.
  " If user selected 'Show Total Fare', then set visible
  TRY.
    DATA(lo_col_totfare) = lo_columns->get_column( 'TOTAL_PRICE' ).
    lo_col_totfare->set_visible( 'X' ).  " 'X' -> show
  CATCH cx_salv_not_found.
    " If the column does not exist, ignore
  ENDTRY.
ELSE.
  " If user did NOT select the option, hide it
  TRY.
   lo_col_totfare = lo_columns->get_column( 'TOTAL_PRICE' ).
    lo_col_totfare->set_visible( ' ' ).
  CATCH cx_salv_not_found.
  ENDTRY.
ENDIF.


  
  DATA(lo_column4) = lo_columns->get_column( 'CONNID' ).
  lo_column4->set_visible( ' ' ).  " ' ' sütunu gizler

  DATA(lo_column5) = lo_columns->get_column( 'CITYFROM' ).
  lo_column5->set_visible( ' ' ).  " ' ' sütunu gizler

  DATA(lo_column6) = lo_columns->get_column( 'CITYTO' ).
  lo_column6->set_visible( ' ' ).  " ' ' sütunu gizler

  DATA(lo_column7) = lo_columns->get_column( 'CARRID' ).
  lo_column7->set_visible( ' ' ).  " ' ' sütunu gizler

  DATA(lo_column8) = lo_columns->get_column( 'PRICE' ).
  lo_column8->set_visible( ' ' ).  " ' ' sütunu gizler

  DATA(lo_column9) = lo_columns->get_column( 'CURRENCY' ).
  lo_column9->set_visible( ' ' ).  " ' ' sütunu gizler

  DATA(lo_column10) = lo_columns->get_column( 'SEATSMAX_E' ).
  lo_column10->set_visible( ' ' ).  " ' ' sütunu gizler

  DATA(lo_column11) = lo_columns->get_column( 'SEATSOCC_E' ).
  lo_column11->set_visible( ' ' ).  " ' ' sütunu gizler

  DATA(lo_column12) = lo_columns->get_column( 'SEAT_AV_ECO' ).
  lo_column12->set_visible( ' ' ).  " ' ' sütunu gizler

  DATA(lo_column13) = lo_columns->get_column( 'SEATSMAX_B' ).
  lo_column13->set_visible( ' ' ).  " ' ' sütunu gizler

  DATA(lo_column14) = lo_columns->get_column( 'SEATSOCC_B' ).
  lo_column14->set_visible( ' ' ).  " ' ' sütunu gizler

  DATA(lo_column15) = lo_columns->get_column( 'SFLIGHT_AV_B' ).
  lo_column15->set_visible( ' ' ).  " ' ' sütunu gizler

  DATA(lo_column16) = lo_columns->get_column( 'SEATSMAX_F' ).
  lo_column16->set_visible( ' ' ).  " ' ' sütunu gizler
  CATCH cx_salv_not_found.
    " Eğer INTER_ATLANTIC sütunu yoksa buraya düşer
  ENDTRY.

  " ALV'yi göster
  gr_alv->display( ).

CATCH cx_salv_msg.
  MESSAGE 'ALV görüntüleme hatası!' TYPE 'E'.
ENDTRY.