*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

" =========================================================================
" 1. KHAI BÁO BỘ ĐỆM (BẮT BUỘC NẰM TRÊN CÙNG)
" =========================================================================
CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA: mt_filter_log  TYPE TABLE OF zfilter_log_t35,
                mt_process_log TYPE TABLE OF zprocess_his_t35.
ENDCLASS.

" =========================================================================
" 2. CLASS HANDLER CHO BOOKING ITEM
" =========================================================================
CLASS lhc_bookingitem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR BookingItem~calculateTotalPrice.
ENDCLASS.

CLASS lhc_bookingitem IMPLEMENTATION.
  METHOD calculateTotalPrice.
    READ ENTITIES OF zi_booking_t35 IN LOCAL MODE
      ENTITY BookingItem
        FIELDS ( BookingID Quantity ItemPrice )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    CHECK lt_items IS NOT INITIAL.

    DATA: lt_booking_keys TYPE TABLE FOR READ IMPORT zi_booking_t35\_BookingItem.

    LOOP AT lt_items INTO DATA(ls_item).
      APPEND VALUE #(
        %tky-BookingID = ls_item-BookingID
        %tky-%is_draft = ls_item-%tky-%is_draft
      ) TO lt_booking_keys.
    ENDLOOP.

    SORT lt_booking_keys BY %tky-BookingID %tky-%is_draft.
    DELETE ADJACENT DUPLICATES FROM lt_booking_keys COMPARING %tky-BookingID %tky-%is_draft.

    READ ENTITIES OF zi_booking_t35 IN LOCAL MODE
      ENTITY Booking BY \_BookingItem
        FIELDS ( Quantity ItemPrice )
        WITH lt_booking_keys
      RESULT DATA(lt_all_items).

    DATA: lt_booking_update TYPE TABLE FOR UPDATE zi_booking_t35.

    LOOP AT lt_booking_keys INTO DATA(ls_bkey).
      DATA(lv_total) = CONV zbooking_t35-total_price( 0 ).

      LOOP AT lt_all_items INTO DATA(ls_all_item)
           WHERE %tky-BookingID = ls_bkey-%tky-BookingID
             AND %tky-%is_draft = ls_bkey-%tky-%is_draft.
        lv_total = lv_total + ( ls_all_item-Quantity * ls_all_item-ItemPrice ).
      ENDLOOP.

      APPEND VALUE #(
        %tky                = ls_bkey-%tky
        TotalPrice          = lv_total
        %control-TotalPrice = if_abap_behv=>mk-on
      ) TO lt_booking_update.
    ENDLOOP.

    MODIFY ENTITIES OF zi_booking_t35 IN LOCAL MODE
      ENTITY Booking
        UPDATE FIELDS ( TotalPrice )
        WITH lt_booking_update.
  ENDMETHOD.
ENDCLASS.

" =========================================================================
" 3. CLASS HANDLER CHO BOOKING HEADER
" =========================================================================
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
    METHODS applyDiscount FOR MODIFY
      IMPORTING keys FOR ACTION Booking~applyDiscount RESULT result.
    METHODS GetFilter FOR MODIFY
      IMPORTING keys FOR ACTION Booking~GetFilter RESULT result.
    METHODS ProcessData FOR MODIFY
      IMPORTING keys FOR ACTION Booking~ProcessData RESULT result.
ENDCLASS.

CLASS lhc_Booking IMPLEMENTATION.
  METHOD get_global_authorizations.
    result-%create = if_abap_behv=>auth-allowed.
    result-%update = if_abap_behv=>auth-allowed.
    result-%delete = if_abap_behv=>auth-allowed.
  ENDMETHOD.

  METHOD earlynumbering_create.
    SELECT SINGLE FROM zbooking_t35 FIELDS MAX( booking_id ) INTO @DATA(lv_max_active).
    SELECT SINGLE FROM zbooking_t35_d FIELDS MAX( bookingid ) INTO @DATA(lv_max_draft).

    DATA(lv_max_id) = lv_max_active.
    IF lv_max_draft > lv_max_active.
      lv_max_id = lv_max_draft.
    ENDIF.

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

  METHOD applyDiscount.
    READ ENTITIES OF zi_booking_t35 IN LOCAL MODE
      ENTITY Booking FIELDS ( TotalPrice ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_booking).

    LOOP AT lt_booking ASSIGNING FIELD-SYMBOL(<ls_booking>).
      READ TABLE keys WITH KEY %tky = <ls_booking>-%tky INTO DATA(ls_key).
      IF sy-subrc = 0 AND ls_key-%param-DiscountPct IS NOT INITIAL.
        <ls_booking>-TotalPrice = <ls_booking>-TotalPrice - ( <ls_booking>-TotalPrice * ls_key-%param-DiscountPct / 100 ).
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF zi_booking_t35 IN LOCAL MODE
      ENTITY Booking
        UPDATE FIELDS ( TotalPrice )
        WITH VALUE #( FOR b IN lt_booking ( %tky = b-%tky TotalPrice = b-TotalPrice ) )
      FAILED failed REPORTED reported.

    READ ENTITIES OF zi_booking_t35 IN LOCAL MODE
      ENTITY Booking ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_booking_updated).
    result = VALUE #( FOR b IN lt_booking_updated ( %tky = b-%tky %param = b ) ).
  ENDMETHOD.

  METHOD GetFilter.
    DATA: lt_filter_log TYPE TABLE OF zfilter_log_t35.
    DATA: lv_timestamp TYPE tzntstmpl.

    GET TIME STAMP FIELD lv_timestamp.

    LOOP AT keys INTO DATA(ls_key).
      APPEND VALUE #(
        timestamp      = lv_timestamp
        username       = sy-uname
        customer_id    = ls_key-%param-customer_id
        booking_date_l = ls_key-%param-booking_date_l
        booking_date_h = ls_key-%param-booking_date_h
        status         = ls_key-%param-status
        city           = ls_key-%param-city
        confirm_flag   = ls_key-%param-confirm_flag
        priority       = ls_key-%param-priority
      ) TO lt_filter_log.
    ENDLOOP.

    " Đẩy vào bộ đệm
    IF lt_filter_log IS NOT INITIAL.
      APPEND LINES OF lt_filter_log TO lcl_buffer=>mt_filter_log.
    ENDIF.
  ENDMETHOD.

METHOD ProcessData.
    DATA: lt_process_log TYPE TABLE OF zprocess_his_t35.

    " 1. Lấy bản ghi Get Filter gần nhất của user hiện tại
    SELECT * FROM zfilter_log_t35
      WHERE username = @sy-uname
      ORDER BY timestamp DESCENDING
      INTO TABLE @DATA(lt_filter)
      UP TO 1 ROWS.

    DATA(ls_filter) = VALUE zfilter_log_t35( ).
    IF lt_filter IS NOT INITIAL.
      READ TABLE lt_filter INTO ls_filter INDEX 1.
    ENDIF.

    " Phòng hờ trường hợp dữ liệu log chưa có
    IF sy-subrc <> 0 OR lt_filter IS INITIAL.
      LOOP AT keys INTO DATA(ls_err_key).
        INSERT VALUE #( %tky = ls_err_key-%tky ) INTO TABLE failed-booking.
        INSERT VALUE #(
          %tky        = ls_err_key-%tky
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'Bạn phải nhấn nút "Get Filter" trước khi Process!'
                        )
        ) INTO TABLE reported-booking.
      ENDLOOP.
      RETURN.
    ENDIF.

    " --- YÊU CẦU 2: CHUYỂN ĐỔI TOÀN BỘ DATA FILTER THÀNH JSON VÀ LƯU VÀO CỘT VALUE ---
    DATA(lv_json_value) = /ui2/cl_json=>serialize(
      data     = ls_filter
      compress = abap_true
    ).

    " 2. Duyệt qua các dòng user tích chọn để Process
    LOOP AT keys INTO DATA(ls_key).
      APPEND VALUE #(
        booking_id   = ls_key-BookingId
        process_date = sy-datum
        process_time = sy-uzeit
        processed_by = sy-uname
        value        = lv_json_value  " Đưa chuỗi JSON vào đây
      ) TO lt_process_log.
    ENDLOOP.

    " Đẩy vào bộ đệm (Buffer) để Save Phase ghi xuống DB
    IF lt_process_log IS NOT INITIAL.
      APPEND LINES OF lt_process_log TO lcl_buffer=>mt_process_log.
    ENDIF.

    " 3. Trả dữ liệu về UI
    READ ENTITIES OF zi_booking_t35 IN LOCAL MODE
      ENTITY Booking ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_booking).

    result = VALUE #( FOR b IN lt_booking ( %tky = b-%tky %param = b ) ).
  ENDMETHOD.
ENDCLASS.

" =========================================================================
" 4. DUY NHẤT 1 CLASS SAVER CHO TOÀN BỘ FILE (GỘP LOGIC LƯU LOG + LƯU BOOKING)
" =========================================================================
CLASS lsc_Booking DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.
ENDCLASS.

CLASS lsc_Booking IMPLEMENTATION.
  METHOD save_modified.
    " --- A. LƯU LOG TỪ BỘ ĐỆM XUỐNG DB ---
    IF lcl_buffer=>mt_filter_log IS NOT INITIAL.
      MODIFY zfilter_log_t35 FROM TABLE @lcl_buffer=>mt_filter_log.
    ENDIF.

    IF lcl_buffer=>mt_process_log IS NOT INITIAL.
      MODIFY zprocess_his_t35 FROM TABLE @lcl_buffer=>mt_process_log.
    ENDIF.

    " --- B. XỬ LÝ KHI TẠO MỚI (CREATE) ---
    IF create-booking IS NOT INITIAL.
      DATA: lt_booking TYPE TABLE OF zbooking_t35,
            lt_items   TYPE TABLE OF zbkitem_t35.

      LOOP AT create-booking INTO DATA(ls_new).
        APPEND VALUE #(
          booking_id      = ls_new-bookingid
          customer_id     = ls_new-customerid
          booking_date    = ls_new-bookingdate
          description     = ls_new-description
          total_price     = ls_new-totalprice
          currency_code   = ls_new-currencycode
          overall_status  = ls_new-overallstatus
          confirm_flag    = ls_new-confirmflag
          priority        = ls_new-priority
          customer_rating = ls_new-customerrating
          completion_pct  = ls_new-completionpct
        ) TO lt_booking.
      ENDLOOP.

      SELECT bookingid, itemid, productid, quantity, quantityunit, itemprice, currencycode
              FROM zbkitem_t35_d
              FOR ALL ENTRIES IN @create-booking
              WHERE bookingid = @create-booking-bookingid
              INTO TABLE @DATA(lt_draft_items_c).
      IF sy-subrc = 0.
        LOOP AT lt_draft_items_c INTO DATA(ls_draft_c).
          APPEND VALUE #(
            booking_id    = ls_draft_c-bookingid
            item_id       = ls_draft_c-itemid
            product_id    = ls_draft_c-productid
            quantity      = ls_draft_c-quantity
            quantity_unit = ls_draft_c-quantityunit
            item_price    = ls_draft_c-itemprice
            currency_code = ls_draft_c-currencycode
          ) TO lt_items.
        ENDLOOP.
      ENDIF.

      LOOP AT create-booking INTO DATA(ls_b).
        DATA: ls_travel TYPE /dmo/travel.
        ls_travel-travel_id     = '0000' && ls_b-bookingid.
        ls_travel-agency_id     = '070001'.
        ls_travel-customer_id   = ls_b-customerid.
        ls_travel-begin_date    = ls_b-bookingdate.
        ls_travel-end_date      = ls_b-bookingdate.
        ls_travel-total_price   = ls_b-totalprice.
        ls_travel-currency_code = ls_b-currencycode.
        ls_travel-status        = 'O'.
        ls_travel-description   = |Tạo từ Booking { ls_b-bookingid }|.
        INSERT /dmo/travel FROM @ls_travel.
      ENDLOOP.

      IF lt_booking IS NOT INITIAL.
        MODIFY zbooking_t35 FROM TABLE @lt_booking.
      ENDIF.
      IF lt_items IS NOT INITIAL.
        MODIFY zbkitem_t35 FROM TABLE @lt_items.
      ENDIF.

      LOOP AT create-booking INTO DATA(ls_clean).
        DELETE FROM zbooking_t35_d WHERE bookingid = @ls_clean-bookingid.
        DELETE FROM zbkitem_t35_d WHERE bookingid = @ls_clean-bookingid.
      ENDLOOP.
    ENDIF.

    " --- C. XỬ LÝ KHI CẬP NHẬT (UPDATE) ---
    IF update-booking IS NOT INITIAL.
      DATA: lt_booking_ids TYPE TABLE OF zbooking_t35-booking_id.
      LOOP AT update-booking INTO DATA(ls_upd).
        APPEND ls_upd-bookingid TO lt_booking_ids.
      ENDLOOP.

      SELECT bookingid, customerid, bookingdate, description, totalprice,
             currencycode, overallstatus, confirmflag, priority,
             customerrating, completionpct
        FROM zbooking_t35_d
        FOR ALL ENTRIES IN @lt_booking_ids
        WHERE bookingid = @lt_booking_ids-table_line
        INTO TABLE @DATA(lt_draft_header).

      IF lt_draft_header IS NOT INITIAL.
        LOOP AT lt_draft_header INTO DATA(ls_draft_h).
          UPDATE zbooking_t35 SET
            customer_id     = @ls_draft_h-customerid,
            booking_date    = @ls_draft_h-bookingdate,
            description     = @ls_draft_h-description,
            total_price     = @ls_draft_h-totalprice,
            currency_code   = @ls_draft_h-currencycode,
            overall_status  = @ls_draft_h-overallstatus,
            confirm_flag    = @ls_draft_h-confirmflag,
            priority        = @ls_draft_h-priority,
            customer_rating = @ls_draft_h-customerrating,
            completion_pct  = @ls_draft_h-completionpct
          WHERE booking_id = @ls_draft_h-bookingid.
        ENDLOOP.
      ENDIF.

      SELECT bookingid, itemid, productid, quantity, quantityunit, itemprice, currencycode
        FROM zbkitem_t35_d
        FOR ALL ENTRIES IN @lt_booking_ids
        WHERE bookingid = @lt_booking_ids-table_line
        INTO TABLE @DATA(lt_draft_items).

      IF lt_draft_items IS NOT INITIAL.
        LOOP AT lt_booking_ids INTO DATA(lv_booking_id).
          DELETE FROM zbkitem_t35 WHERE booking_id = @lv_booking_id.
        ENDLOOP.

        DATA: lt_upd_items TYPE TABLE OF zbkitem_t35.
        LOOP AT lt_draft_items INTO DATA(ls_draft_i).
          APPEND VALUE #(
            booking_id    = ls_draft_i-bookingid
            item_id       = ls_draft_i-itemid
            product_id    = ls_draft_i-productid
            quantity      = ls_draft_i-quantity
            quantity_unit = ls_draft_i-quantityunit
            item_price    = ls_draft_i-itemprice
            currency_code = ls_draft_i-currencycode
          ) TO lt_upd_items.
        ENDLOOP.

        IF lt_upd_items IS NOT INITIAL.
          MODIFY zbkitem_t35 FROM TABLE @lt_upd_items.
        ENDIF.
      ENDIF.

      LOOP AT lt_booking_ids INTO lv_booking_id.
        DELETE FROM zbooking_t35_d WHERE bookingid = @lv_booking_id.
        DELETE FROM zbkitem_t35_d WHERE bookingid = @lv_booking_id.
      ENDLOOP.
    ENDIF.

    " --- D. XỬ LÝ KHI XÓA (DELETE) ---
    IF delete-booking IS NOT INITIAL.
      LOOP AT delete-booking INTO DATA(ls_del).
        DELETE FROM zbooking_t35 WHERE booking_id = @ls_del-bookingid.
        DELETE FROM zbkitem_t35 WHERE booking_id = @ls_del-bookingid.
        DELETE FROM zbooking_t35_d WHERE bookingid = @ls_del-bookingid.
        DELETE FROM zbkitem_t35_d WHERE bookingid = @ls_del-bookingid.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.

  METHOD cleanup_finalize.
    " Dọn dẹp túi đồ bộ đệm sau khi lưu xong
    CLEAR: lcl_buffer=>mt_filter_log, lcl_buffer=>mt_process_log.
  ENDMETHOD.
ENDCLASS.
