"! <p class="shorttext synchronized" lang="en">RAP Behavior Handler: MTO Excess Stock Transfer</p>
CLASS zbp_r_mto_excess_stock DEFINITION
  PUBLIC
  ABSTRACT
  FINAL
  FOR BEHAVIOR OF ZR_MTO_ExcessStock.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_transfer_request,
        material    TYPE matnr,
        plant       TYPE werks_d,
        sloc        TYPE lgort_d,
        batch       TYPE charg_d,
        quantity    TYPE menge_d,
        unit        TYPE meins,
        source_so   TYPE vbeln_va,
        source_item TYPE posnv,
        dest_so     TYPE vbeln_va,
        dest_item   TYPE posnv,
        post_date   TYPE budat,
        doc_date    TYPE bldat,
      END OF ty_transfer_request.

    CLASS-DATA gt_transfer_buffer
                 TYPE TABLE OF ty_transfer_request WITH EMPTY KEY.

ENDCLASS.

CLASS zbp_r_mto_excess_stock IMPLEMENTATION.
ENDCLASS.

CLASS lhc_excessstock DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations
                FOR ExcessStock RESULT result.

    METHODS transferstock FOR MODIFY
      IMPORTING keys FOR ACTION ExcessStock~transferStock RESULT result.

ENDCLASS.


CLASS lhc_excessstock IMPLEMENTATION.

  METHOD get_instance_authorizations.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      APPEND VALUE #(
        %key                  = <key>-%key
        %update               = if_abap_behv=>auth-allowed
        %action-transferStock = if_abap_behv=>auth-allowed
      ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD transferstock.

    " -----------------------------------------------------------------------
    " Step 1: Read StockQuantity and BaseUnit for selected entities
    " -----------------------------------------------------------------------
    READ ENTITIES OF ZR_MTO_ExcessStock IN LOCAL MODE
      ENTITY ExcessStock
        FIELDS ( StockQuantity BaseUnit )
        WITH VALUE #( FOR ls IN keys ( %key = ls-%key ) )
      RESULT DATA(lt_entities)
      FAILED DATA(lt_read_failed).

    LOOP AT lt_read_failed-ExcessStock INTO DATA(ls_rfail).
      APPEND VALUE #( %key = ls_rfail-%key ) TO failed-ExcessStock.
    ENDLOOP.

    " -----------------------------------------------------------------------
    " Step 2: Validate destination Sales Order / Item via I_SalesOrderItem
    " -----------------------------------------------------------------------
    TYPES:
      BEGIN OF ty_dest_key,
        so   TYPE vbeln_va,
        item TYPE posnv,
      END OF ty_dest_key.

    DATA lt_dest_keys TYPE SORTED TABLE OF ty_dest_key
                       WITH UNIQUE KEY so item.

    LOOP AT keys INTO DATA(ls_key).
      INSERT VALUE #(
               so   = ls_key-%param-DestinationSalesOrder
               item = ls_key-%param-DestinationSalesOrderItem )
             INTO TABLE lt_dest_keys.
    ENDLOOP.

    DATA lt_valid_dest TYPE SORTED TABLE OF ty_dest_key
                        WITH UNIQUE KEY so item.

    IF lt_dest_keys IS NOT INITIAL.
      SELECT SalesOrder     AS so,
             SalesOrderItem AS item
        FROM I_SalesOrderItem
        FOR ALL ENTRIES IN @lt_dest_keys
        WHERE SalesOrder     = @lt_dest_keys-so
          AND SalesOrderItem = @lt_dest_keys-item
        INTO TABLE @DATA(lt_found_dest).

      LOOP AT lt_found_dest INTO DATA(ls_found).
        INSERT VALUE #( so = ls_found-so item = ls_found-item )
               INTO TABLE lt_valid_dest.
      ENDLOOP.
    ENDIF.

    " -----------------------------------------------------------------------
    " Step 3: Build validated transfer list
    " -----------------------------------------------------------------------
    TYPES:
      BEGIN OF ty_transfer,
        material    TYPE matnr,
        plant       TYPE werks_d,
        sloc        TYPE lgort_d,
        batch       TYPE charg_d,
        quantity    TYPE menge_d,
        unit        TYPE meins,
        source_so   TYPE vbeln_va,
        source_item TYPE posnv,
        dest_so     TYPE vbeln_va,
        dest_item   TYPE posnv,
        post_date   TYPE budat,
        doc_date    TYPE bldat,
      END OF ty_transfer.

    DATA lt_transfers TYPE TABLE OF ty_transfer WITH EMPTY KEY.

    LOOP AT keys INTO ls_key.

      DATA(lv_dest_so)   = ls_key-%param-DestinationSalesOrder.
      DATA(lv_dest_item) = ls_key-%param-DestinationSalesOrderItem.

      " -------------------------------------------------------------------
      " Validation: Source and Destination SO/Item must not be identical
      " -------------------------------------------------------------------
      IF     ls_key-%key-SalesOrder     = lv_dest_so
         AND ls_key-%key-SalesOrderItem = lv_dest_item.
        APPEND VALUE #( %key = ls_key-%key ) TO failed-ExcessStock.
        APPEND VALUE #(
          %key              = ls_key-%key
          %msg              = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Source and destination SO/Item are identical | &&
                       |({ ls_key-%key-SalesOrder } / { lv_dest_item }). | &&
                       |Transfer not allowed.| )
          %element-Material = if_abap_behv=>mk-on
        ) TO reported-ExcessStock.
        CONTINUE.
      ENDIF.

      READ TABLE lt_valid_dest WITH KEY so = lv_dest_so item = lv_dest_item
                               TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        APPEND VALUE #( %key = ls_key-%key ) TO failed-ExcessStock.
        APPEND VALUE #(
          %key              = ls_key-%key
          %msg              = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = |Destination SO { lv_dest_so } / Item { lv_dest_item } not found.| )
          %element-Material = if_abap_behv=>mk-on
        ) TO reported-ExcessStock.
        CONTINUE.
      ENDIF.

      READ TABLE lt_entities INTO DATA(ls_entity)
           WITH KEY %key = ls_key-%key.
      IF sy-subrc <> 0. CONTINUE. ENDIF.

      APPEND VALUE ty_transfer(
               material    = ls_key-%key-Material
               plant       = ls_key-%key-Plant
               sloc        = ls_key-%key-StorageLocation
               batch       = ls_key-%key-Batch
               quantity    = ls_entity-StockQuantity
               unit        = ls_entity-BaseUnit
               source_so   = ls_key-%key-SalesOrder
               source_item = ls_key-%key-SalesOrderItem
               dest_so     = lv_dest_so
               dest_item   = lv_dest_item
               post_date   = ls_key-%param-PostingDate
               doc_date    = ls_key-%param-DocumentDate
      ) TO lt_transfers.

      APPEND VALUE #( %key = ls_key-%key ) TO result.

    ENDLOOP.

    " -----------------------------------------------------------------------
    " Step 4: Post goods movement via BAPI_GOODSMVT_CREATE
    " One material document for all selected lines.
    " NO BAPI_TRANSACTION_COMMIT — RAP framework manages the LUW.
    " -----------------------------------------------------------------------
    CHECK lt_transfers IS NOT INITIAL.

    DATA(ls_first) = lt_transfers[ 1 ].

    DATA(ls_gm_header) = VALUE bapi2017_gm_head_01(
      pstng_date = ls_first-post_date
      doc_date   = ls_first-doc_date
      pr_uname   = sy-uname
    ).

    DATA(ls_gm_code) = VALUE bapi2017_gm_code(
      gm_code = 'MB1B'
    ).

    DATA lt_gm_items TYPE TABLE OF bapi2017_gm_item_create WITH EMPTY KEY.

    LOOP AT lt_transfers INTO DATA(ls_req).

      " Movement 414 E — goods issue from source SO stock
      APPEND VALUE bapi2017_gm_item_create(
        move_type  = '414'
        spec_stock = 'E'
        material   = ls_req-material
        plant      = ls_req-plant
        stge_loc   = ls_req-sloc
        batch      = ls_req-batch
        entry_qnt  = ls_req-quantity
        entry_uom  = ls_req-unit
        sales_ord  = ls_req-source_so
        s_ord_item = ls_req-source_item
        move_plant = ls_req-plant
        move_stloc = ls_req-sloc
      ) TO lt_gm_items.

      " Movement 413 E — goods receipt into destination SO stock
      APPEND VALUE bapi2017_gm_item_create(
        move_type  = '413'
        spec_stock = 'E'
        material   = ls_req-material
        plant      = ls_req-plant
        stge_loc   = ls_req-sloc
        batch      = ls_req-batch
        entry_qnt  = ls_req-quantity
        entry_uom  = ls_req-unit
        sales_ord  = ls_req-dest_so
        s_ord_item = ls_req-dest_item
      ) TO lt_gm_items.

    ENDLOOP.

    DATA ls_gm_matdoc TYPE bapi2017_gm_head_ret.
    DATA lt_return    TYPE TABLE OF bapiret2 WITH EMPTY KEY.

    CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
      EXPORTING
        goodsmvt_header  = ls_gm_header
        goodsmvt_code    = ls_gm_code
      IMPORTING
        goodsmvt_headret = ls_gm_matdoc
      TABLES
        goodsmvt_item    = lt_gm_items
        return           = lt_return.

    " Report BAPI errors back to the UI
    LOOP AT lt_return INTO DATA(ls_ret) WHERE type CA 'EA'.
      LOOP AT keys INTO ls_key.
        APPEND VALUE #(
          %key = ls_key-%key
          %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = ls_ret-message )
        ) TO reported-ExcessStock.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.