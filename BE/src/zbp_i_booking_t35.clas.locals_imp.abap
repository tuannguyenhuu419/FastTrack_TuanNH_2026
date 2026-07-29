CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Booking RESULT result.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Booking.

    METHODS acceptBooking FOR MODIFY
      IMPORTING keys FOR ACTION Booking~acceptBooking RESULT result.

    METHODS cancelBooking FOR MODIFY
      IMPORTING keys FOR ACTION Booking~cancelBooking RESULT result.

ENDCLASS.

CLASS lhc_Booking IMPLEMENTATION.

  METHOD get_global_authorizations.
    result-%create = if_abap_behv=>auth-allowed.
    result-%update = if_abap_behv=>auth-allowed.
    result-%delete = if_abap_behv=>auth-allowed.
  ENDMETHOD.

  METHOD earlynumbering_create.
    SELECT SINGLE FROM zbooking_T35 FIELDS MAX( booking_id ) INTO @DATA(lv_max_id).
    DATA(lv_num) = COND i( WHEN lv_max_id IS INITIAL THEN 0 ELSE CONV i( lv_max_id+2 ) ).

    LOOP AT entities INTO DATA(entity).
      DATA(lv_id) = entity-BookingId.
      IF lv_id IS INITIAL.
        lv_num += 1.
        lv_id = |BK{ lv_num ALIGN = RIGHT PAD = '0' WIDTH = 4 }|.
      ENDIF.
      APPEND VALUE #( %cid           = entity-%cid
                      %is_draft      = entity-%is_draft
                      %key-BookingId = lv_id ) TO mapped-booking.
    ENDLOOP.
  ENDMETHOD.

  METHOD acceptBooking.
    MODIFY ENTITIES OF zi_booking_t35 IN LOCAL MODE
        ENTITY Booking
          UPDATE FIELDS ( OverallStatus )
          WITH VALUE #( FOR key IN keys ( %tky = key-%tky  OverallStatus = 'A' ) )
        FAILED   failed
        REPORTED reported.

    READ ENTITIES OF zi_booking_t35 IN LOCAL MODE
      ENTITY Booking ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_booking).
    result = VALUE #( FOR b IN lt_booking ( %tky = b-%tky  %param = b ) ).
  ENDMETHOD.

  METHOD cancelBooking.
    MODIFY ENTITIES OF zi_booking_t35 IN LOCAL MODE
       ENTITY Booking
         UPDATE FIELDS ( OverallStatus )
         WITH VALUE #( FOR key IN keys ( %tky = key-%tky  OverallStatus = 'X' ) )
       FAILED failed REPORTED reported.

    READ ENTITIES OF zi_booking_t35 IN LOCAL MODE
      ENTITY Booking ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_booking).
    result = VALUE #( FOR b IN lt_booking ( %tky = b-%tky  %param = b ) ).
  ENDMETHOD.

ENDCLASS.
