*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type definitions

*----------------------------------------------------------------------*
* Local exception — cx_no_check subclass, no RAISING clause needed
*----------------------------------------------------------------------*
CLASS lcx_bapi_error DEFINITION INHERITING FROM cx_no_check FINAL.
  PUBLIC SECTION.
    DATA mv_text    TYPE string.
    DATA mv_msgid   TYPE symsgid.
    DATA mv_msgno   TYPE symsgno.
    DATA mv_msgv1   TYPE symsgv.
    DATA mv_msgv2   TYPE symsgv.
    DATA mv_msgv3   TYPE symsgv.
    DATA mv_msgv4   TYPE symsgv.
    METHODS constructor
      IMPORTING
        iv_msgid TYPE symsgid
        iv_msgno TYPE symsgno
        iv_msgv1 TYPE symsgv OPTIONAL
        iv_msgv2 TYPE symsgv OPTIONAL
        iv_msgv3 TYPE symsgv OPTIONAL
        iv_msgv4 TYPE symsgv OPTIONAL.
ENDCLASS.

CLASS lcx_bapi_error IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    mv_msgid = iv_msgid.
    mv_msgno = iv_msgno.
    mv_msgv1 = iv_msgv1.
    mv_msgv2 = iv_msgv2.
    mv_msgv3 = iv_msgv3.
    mv_msgv4 = iv_msgv4.
    MESSAGE ID iv_msgid TYPE 'S' NUMBER iv_msgno
      WITH iv_msgv1 iv_msgv2 iv_msgv3 iv_msgv4
      INTO mv_text.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_excessstock DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations
                FOR ExcessStock RESULT result.

    METHODS transferstock FOR MODIFY
      IMPORTING keys FOR ACTION ExcessStock~transferStock.

    METHODS transferbypallet FOR MODIFY
      IMPORTING keys FOR ACTION ExcessStock~transferByPallet.

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
    " Step 1: Read StockQuantity and BaseUnit from ZR_MTO_BatchSoStock
    " (intermediate CDS on nsdm_e_mska + mara, pre-filtered sobkz='E', kalab>0)
    " -----------------------------------------------------------------------
    TYPES:
      BEGIN OF ty_stock,
        material           TYPE matnr,
        plant              TYPE werks_d,
        storagelocation    TYPE lgort_d,
        batch              TYPE charg_d,
        pallet             TYPE lgpla,
        salesorder         TYPE vbeln_va,
        salesorderitem     TYPE posnv,
        stockquantity      TYPE menge_d,
        baseunit           TYPE meins,
      END OF ty_stock.

    DATA lt_stock TYPE TABLE OF ty_stock WITH EMPTY KEY.

    IF keys IS NOT INITIAL.
      SELECT Material        AS material,
             Plant           AS plant,
             StorageLocation AS storagelocation,
             Batch           AS batch,
             pallet,
             SalesOrder      AS salesorder,
             SalesOrderItem  AS salesorderitem,
             StockQuantity   AS stockquantity,
             BaseUnit        AS baseunit
        FROM ZR_MTO_BatchSoStock
        FOR ALL ENTRIES IN @keys
        WHERE Material        = @keys-%key-Material
          AND Plant           = @keys-%key-Plant
          AND StorageLocation = @keys-%key-StorageLocation
          AND Batch           = @keys-%key-Batch
          AND SalesOrder      = @keys-%key-SalesOrder
          AND SalesOrderItem  = @keys-%key-SalesOrderItem
        INTO CORRESPONDING FIELDS OF TABLE @lt_stock.
    ENDIF.

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
    " Step 3: Read active characteristic checks from config table (per plant)
    " -----------------------------------------------------------------------
    TYPES:
      BEGIN OF ty_charc_cfg,
        werks          TYPE werks_d,
        charc_name     TYPE c LENGTH 30,
        cds_field_name TYPE c LENGTH 30,
      END OF ty_charc_cfg.

    DATA lt_charc_config TYPE TABLE OF ty_charc_cfg WITH EMPTY KEY.

    SELECT werks, charc_name, cds_field_name
      FROM zmto_charc_chk
      WHERE active = @abap_true
      INTO CORRESPONDING FIELDS OF TABLE @lt_charc_config.

    " -----------------------------------------------------------------------
    " Step 4: If checks are configured, read characteristics for all relevant
    "         source + destination SO/Items from ZR_MTO_SoItemCharcVals
    " -----------------------------------------------------------------------
    TYPES: BEGIN OF ty_so_item_key,
             salesorder     TYPE vbeln_va,
             salesorderitem TYPE posnv,
           END OF ty_so_item_key.

    DATA lt_so_item_keys TYPE TABLE OF ty_so_item_key WITH EMPTY KEY.
    DATA lt_charc_vals   TYPE STANDARD TABLE OF zr_mto_soitemcharcvals WITH EMPTY KEY.

    IF lt_charc_config IS NOT INITIAL.
      " Collect all unique SO/Item keys (source + destination)
      LOOP AT keys INTO DATA(ls_tmp).
        APPEND VALUE #( salesorder     = ls_tmp-%key-SalesOrder
                        salesorderitem = ls_tmp-%key-SalesOrderItem ) TO lt_so_item_keys.
        APPEND VALUE #( salesorder     = ls_tmp-%param-DestinationSalesOrder
                        salesorderitem = ls_tmp-%param-DestinationSalesOrderItem ) TO lt_so_item_keys.
      ENDLOOP.
      SORT lt_so_item_keys BY salesorder salesorderitem.
      DELETE ADJACENT DUPLICATES FROM lt_so_item_keys COMPARING salesorder salesorderitem.

      IF lt_so_item_keys IS NOT INITIAL.
        SELECT *
          FROM zr_mto_soitemcharcvals
          FOR ALL ENTRIES IN @lt_so_item_keys
          WHERE SalesOrder     = @lt_so_item_keys-salesorder
            AND SalesOrderItem = @lt_so_item_keys-salesorderitem
          INTO TABLE @lt_charc_vals.
      ENDIF.
    ENDIF.

    " -----------------------------------------------------------------------
    " Step 5: Build validated transfer list — fill buffer for save_modified
    " -----------------------------------------------------------------------
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

      " Validate destination SO/Item exists
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

      " -------------------------------------------------------------------
      " Validation: Characteristic values must match (config-driven)
      " Skip entirely if no config entries exist for this plant
      " -------------------------------------------------------------------
      DATA lv_plant_has_config TYPE abap_bool.
      CLEAR lv_plant_has_config.
      LOOP AT lt_charc_config TRANSPORTING NO FIELDS
           WHERE werks = ls_key-%key-Plant.
        lv_plant_has_config = abap_true.
        EXIT.
      ENDLOOP.

      IF lv_plant_has_config = abap_true.
        " Find source characteristics
        READ TABLE lt_charc_vals ASSIGNING FIELD-SYMBOL(<src_chars>)
             WITH KEY salesorder     = ls_key-%key-SalesOrder
                      salesorderitem = ls_key-%key-SalesOrderItem.
        " Find destination characteristics
        READ TABLE lt_charc_vals ASSIGNING FIELD-SYMBOL(<dst_chars>)
             WITH KEY salesorder     = lv_dest_so
                      salesorderitem = lv_dest_item.

        IF <src_chars> IS ASSIGNED AND <dst_chars> IS ASSIGNED.
          DATA lv_mismatch_text TYPE string.
          DATA lv_has_mismatch  TYPE abap_bool.
          CLEAR: lv_mismatch_text, lv_has_mismatch.

          " Only check characteristics configured for this plant
          LOOP AT lt_charc_config ASSIGNING FIELD-SYMBOL(<cfg>)
               WHERE werks = ls_key-%key-Plant.
            DATA lv_src_val TYPE string.
            DATA lv_dst_val TYPE string.
            CLEAR: lv_src_val, lv_dst_val.

            " Dynamic field access using CDS field name
            ASSIGN COMPONENT <cfg>-cds_field_name OF STRUCTURE <src_chars> TO FIELD-SYMBOL(<src_fld>).
            ASSIGN COMPONENT <cfg>-cds_field_name OF STRUCTURE <dst_chars> TO FIELD-SYMBOL(<dst_fld>).

            IF <src_fld> IS ASSIGNED AND <dst_fld> IS ASSIGNED.
              lv_src_val = <src_fld>.
              lv_dst_val = <dst_fld>.
              CONDENSE: lv_src_val, lv_dst_val.

              IF lv_src_val <> lv_dst_val.
                lv_has_mismatch = abap_true.
                IF lv_mismatch_text IS NOT INITIAL.
                  lv_mismatch_text = lv_mismatch_text && |; |.
                ENDIF.
                lv_mismatch_text = lv_mismatch_text &&
                  |{ <cfg>-charc_name }: '{ lv_src_val }' vs '{ lv_dst_val }'|.
              ENDIF.
            ENDIF.

            UNASSIGN: <src_fld>, <dst_fld>.
          ENDLOOP.

          IF lv_has_mismatch = abap_true.
            APPEND VALUE #( %key = ls_key-%key ) TO failed-ExcessStock.
            APPEND VALUE #(
              %key              = ls_key-%key
              %msg              = new_message_with_text(
              severity = if_abap_behv_message=>severity-error
              text     = |Characteristic mismatch between source | &&
                         |{ ls_key-%key-SalesOrder }/{ ls_key-%key-SalesOrderItem } | &&
                         |and destination { lv_dest_so }/{ lv_dest_item }: | &&
                         lv_mismatch_text )
              %element-Material = if_abap_behv=>mk-on
            ) TO reported-ExcessStock.
            UNASSIGN: <src_chars>, <dst_chars>.
            CONTINUE.
          ENDIF.
        ENDIF.

        UNASSIGN: <src_chars>, <dst_chars>.
      ENDIF.

      " Find stock quantity for this key
      READ TABLE lt_stock INTO DATA(ls_stock)
           WITH KEY material        = ls_key-%key-Material
                    plant           = ls_key-%key-Plant
                    storagelocation = ls_key-%key-StorageLocation
                    batch           = ls_key-%key-Batch
                    salesorder      = ls_key-%key-SalesOrder
                    salesorderitem  = ls_key-%key-SalesOrderItem.
      IF sy-subrc <> 0. CONTINUE. ENDIF.

      " Add to transfer buffer — BAPI will be called in save_modified
      APPEND VALUE zbp_r_mto_excess_stock=>ty_transfer_request(
               material    = ls_key-%key-Material
               plant       = ls_key-%key-Plant
               sloc        = ls_key-%key-StorageLocation
               batch       = ls_key-%key-Batch
               pallet      = ls_stock-pallet
               quantity    = ls_stock-stockquantity
               unit        = ls_stock-baseunit
               source_so   = ls_key-%key-SalesOrder
               source_item = ls_key-%key-SalesOrderItem
               dest_so     = lv_dest_so
               dest_item   = lv_dest_item
               post_date   = ls_key-%param-PostingDate
               doc_date    = ls_key-%param-DocumentDate
      ) TO zbp_r_mto_excess_stock=>gt_transfer_buffer.

    ENDLOOP.

  ENDMETHOD.

  METHOD transferbypallet.

    " -----------------------------------------------------------------------
    " Static action — no row selection needed.
    " User provides: PalletNumber, Plant, DestSO, DestSOItem, PostingDate, DocumentDate
    " We find ALL stock lines for that pallet+plant and transfer them.
    " -----------------------------------------------------------------------

    TYPES:
      BEGIN OF ty_stock,
        material        TYPE matnr,
        plant           TYPE werks_d,
        storagelocation TYPE lgort_d,
        batch           TYPE charg_d,
        pallet          TYPE lgpla,
        salesorder      TYPE vbeln_va,
        salesorderitem  TYPE posnv,
        stockquantity   TYPE menge_d,
        baseunit        TYPE meins,
      END OF ty_stock.

    " Static actions: keys is a table with %param but no instance %key.
    " Each entry in keys is one invocation (typically just one).
    LOOP AT keys INTO DATA(ls_key).

      DATA(lv_pallet)    = ls_key-%param-PalletNumber.
      DATA(lv_plant)     = ls_key-%param-Plant.
      DATA(lv_dest_so)   = ls_key-%param-DestinationSalesOrder.
      DATA(lv_dest_item) = ls_key-%param-DestinationSalesOrderItem.
      DATA(lv_post_date) = ls_key-%param-PostingDate.
      DATA(lv_doc_date)  = ls_key-%param-DocumentDate.

      " -------------------------------------------------------------------
      " Validation: mandatory parameters
      " -------------------------------------------------------------------
      IF lv_pallet IS INITIAL OR lv_plant IS INITIAL.
        APPEND VALUE #(
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Pallet No and Plant are mandatory for Transfer by Pallet.| )
        ) TO reported-ExcessStock.
        RETURN.
      ENDIF.

      IF lv_dest_so IS INITIAL OR lv_dest_item IS INITIAL.
        APPEND VALUE #(
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Destination Sales Order and Item are mandatory.| )
        ) TO reported-ExcessStock.
        RETURN.
      ENDIF.

      " -------------------------------------------------------------------
      " Step 1: Find all stock lines for the given pallet + plant
      " -------------------------------------------------------------------
      DATA lt_stock TYPE TABLE OF ty_stock WITH EMPTY KEY.

      SELECT Material        AS material,
             Plant           AS plant,
             StorageLocation AS storagelocation,
             Batch           AS batch,
             pallet,
             SalesOrder      AS salesorder,
             SalesOrderItem  AS salesorderitem,
             StockQuantity   AS stockquantity,
             BaseUnit        AS baseunit
        FROM ZR_MTO_BatchSoStock
        WHERE pallet = @lv_pallet
          AND Plant  = @lv_plant
        INTO CORRESPONDING FIELDS OF TABLE @lt_stock.

      IF lt_stock IS INITIAL.
        APPEND VALUE #(
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |No stock found for Pallet { lv_pallet } in Plant { lv_plant }.| )
        ) TO reported-ExcessStock.
        RETURN.
      ENDIF.

      " -------------------------------------------------------------------
      " Step 2: Validate destination SO/Item exists
      " -------------------------------------------------------------------
      SELECT SINGLE SalesOrder, SalesOrderItem
        FROM I_SalesOrderItem
        WHERE SalesOrder     = @lv_dest_so
          AND SalesOrderItem = @lv_dest_item
        INTO @DATA(ls_dest_check).

      IF sy-subrc <> 0.
        APPEND VALUE #(
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Destination SO { lv_dest_so } / Item { lv_dest_item } not found.| )
        ) TO reported-ExcessStock.
        RETURN.
      ENDIF.

      " -------------------------------------------------------------------
      " Step 3: Characteristic checks (config-driven, per plant)
      " -------------------------------------------------------------------
      TYPES:
        BEGIN OF ty_charc_cfg,
          werks          TYPE werks_d,
          charc_name     TYPE c LENGTH 30,
          cds_field_name TYPE c LENGTH 30,
        END OF ty_charc_cfg.

      DATA lt_charc_config TYPE TABLE OF ty_charc_cfg WITH EMPTY KEY.

      SELECT werks, charc_name, cds_field_name
        FROM zmto_charc_chk
        WHERE active = @abap_true
          AND werks  = @lv_plant
        INTO CORRESPONDING FIELDS OF TABLE @lt_charc_config.

      IF lt_charc_config IS NOT INITIAL.
        " Collect all unique source SO/Items + destination
        TYPES: BEGIN OF ty_so_item_key,
                 salesorder     TYPE vbeln_va,
                 salesorderitem TYPE posnv,
               END OF ty_so_item_key.

        DATA lt_so_item_keys TYPE TABLE OF ty_so_item_key WITH EMPTY KEY.
        DATA lt_charc_vals   TYPE STANDARD TABLE OF zr_mto_soitemcharcvals WITH EMPTY KEY.

        LOOP AT lt_stock INTO DATA(ls_stk_tmp).
          APPEND VALUE #( salesorder     = ls_stk_tmp-salesorder
                          salesorderitem = ls_stk_tmp-salesorderitem ) TO lt_so_item_keys.
        ENDLOOP.
        APPEND VALUE #( salesorder     = lv_dest_so
                        salesorderitem = lv_dest_item ) TO lt_so_item_keys.
        SORT lt_so_item_keys BY salesorder salesorderitem.
        DELETE ADJACENT DUPLICATES FROM lt_so_item_keys COMPARING salesorder salesorderitem.

        IF lt_so_item_keys IS NOT INITIAL.
          SELECT *
            FROM zr_mto_soitemcharcvals
            FOR ALL ENTRIES IN @lt_so_item_keys
            WHERE SalesOrder     = @lt_so_item_keys-salesorder
              AND SalesOrderItem = @lt_so_item_keys-salesorderitem
            INTO TABLE @lt_charc_vals.
        ENDIF.

        " Read destination characteristics once
        DATA lr_dst_chars TYPE REF TO zr_mto_soitemcharcvals.
        LOOP AT lt_charc_vals ASSIGNING FIELD-SYMBOL(<dst_ch>)
             WHERE salesorder     = lv_dest_so
               AND salesorderitem = lv_dest_item.
          GET REFERENCE OF <dst_ch> INTO lr_dst_chars.
          EXIT.
        ENDLOOP.
      ENDIF.

      " -------------------------------------------------------------------
      " Step 4: Loop through stock lines — validate + build buffer
      " -------------------------------------------------------------------
      DATA lv_lines_added TYPE i VALUE 0.

      LOOP AT lt_stock INTO DATA(ls_stk).

        " Validate source ≠ destination
        IF ls_stk-salesorder = lv_dest_so AND ls_stk-salesorderitem = lv_dest_item.
          APPEND VALUE #(
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-warning
              text     = |Skipped batch { ls_stk-batch }: source SO/Item equals destination.| )
          ) TO reported-ExcessStock.
          CONTINUE.
        ENDIF.

        " Characteristic check (if configured)
        IF lt_charc_config IS NOT INITIAL AND lr_dst_chars IS BOUND.
          LOOP AT lt_charc_vals ASSIGNING FIELD-SYMBOL(<src_ch>)
               WHERE salesorder     = ls_stk-salesorder
                 AND salesorderitem = ls_stk-salesorderitem.
            EXIT.
          ENDLOOP.

          IF <src_ch> IS ASSIGNED.
            DATA lv_mismatch_text TYPE string.
            DATA lv_has_mismatch  TYPE abap_bool.
            CLEAR: lv_mismatch_text, lv_has_mismatch.

            LOOP AT lt_charc_config ASSIGNING FIELD-SYMBOL(<cfg>).
              DATA lv_src_val TYPE string.
              DATA lv_dst_val TYPE string.
              CLEAR: lv_src_val, lv_dst_val.

              ASSIGN COMPONENT <cfg>-cds_field_name OF STRUCTURE <src_ch> TO FIELD-SYMBOL(<sf>).
              ASSIGN COMPONENT <cfg>-cds_field_name OF STRUCTURE lr_dst_chars->* TO FIELD-SYMBOL(<df>).

              IF <sf> IS ASSIGNED AND <df> IS ASSIGNED.
                lv_src_val = <sf>.
                lv_dst_val = <df>.
                CONDENSE: lv_src_val, lv_dst_val.

                IF lv_src_val <> lv_dst_val.
                  lv_has_mismatch = abap_true.
                  IF lv_mismatch_text IS NOT INITIAL.
                    lv_mismatch_text = lv_mismatch_text && |; |.
                  ENDIF.
                  lv_mismatch_text = lv_mismatch_text &&
                    |{ <cfg>-charc_name }: '{ lv_src_val }' vs '{ lv_dst_val }'|.
                ENDIF.
              ENDIF.

              UNASSIGN: <sf>, <df>.
            ENDLOOP.

            IF lv_has_mismatch = abap_true.
              APPEND VALUE #(
                %msg = new_message_with_text(
                  severity = if_abap_behv_message=>severity-error
                  text     = |Charc mismatch for batch { ls_stk-batch } | &&
                             |(SO { ls_stk-salesorder }/{ ls_stk-salesorderitem }): | &&
                             lv_mismatch_text )
              ) TO reported-ExcessStock.
              UNASSIGN <src_ch>.
              CONTINUE.
            ENDIF.
          ENDIF.

          UNASSIGN <src_ch>.
        ENDIF.

        " Add to transfer buffer
        APPEND VALUE zbp_r_mto_excess_stock=>ty_transfer_request(
                 material    = ls_stk-material
                 plant       = ls_stk-plant
                 sloc        = ls_stk-storagelocation
                 batch       = ls_stk-batch
                 pallet      = ls_stk-pallet
                 quantity    = ls_stk-stockquantity
                 unit        = ls_stk-baseunit
                 source_so   = ls_stk-salesorder
                 source_item = ls_stk-salesorderitem
                 dest_so     = lv_dest_so
                 dest_item   = lv_dest_item
                 post_date   = lv_post_date
                 doc_date    = lv_doc_date
        ) TO zbp_r_mto_excess_stock=>gt_transfer_buffer.

        lv_lines_added = lv_lines_added + 1.

      ENDLOOP.

      " Info message: how many lines queued
      IF lv_lines_added > 0.
        APPEND VALUE #(
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-success
            text     = |{ lv_lines_added } stock line(s) for pallet { lv_pallet } queued for transfer.| )
        ) TO reported-ExcessStock.
      ELSE.
        APPEND VALUE #(
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-warning
            text     = |No valid stock lines found for pallet { lv_pallet } after validation.| )
        ) TO reported-ExcessStock.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.


*----------------------------------------------------------------------*
* Local Saver Class — BAPI_GOODSMVT_CREATE called here (Clean Core RAP)
*----------------------------------------------------------------------*
CLASS lsc_excessstock DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
ENDCLASS.


CLASS lsc_excessstock IMPLEMENTATION.

  METHOD save_modified.

    DATA lt_buffer TYPE TABLE OF zbp_r_mto_excess_stock=>ty_transfer_request
                   WITH EMPTY KEY.

    lt_buffer = zbp_r_mto_excess_stock=>gt_transfer_buffer.
    CLEAR zbp_r_mto_excess_stock=>gt_transfer_buffer.

    CHECK lt_buffer IS NOT INITIAL.

    " Build BAPI header — use posting/doc date from first item
    DATA(ls_first) = lt_buffer[ 1 ].

    DATA(ls_gm_header) = VALUE bapi2017_gm_head_01(
      pstng_date = ls_first-post_date
      doc_date   = ls_first-doc_date
      pr_uname   = sy-uname
    ).

    DATA(ls_gm_code) = VALUE bapi2017_gm_code(
   gm_code = '04'   " Transfer posting — correct for MT 413 E
    ).

    " Build BAPI item table — movement type 413 E for each selected line
    DATA lt_gm_items TYPE TABLE OF bapi2017_gm_item_create WITH EMPTY KEY.

    LOOP AT lt_buffer INTO DATA(ls_req).
      APPEND VALUE bapi2017_gm_item_create(
        move_type      = '413'           " Transfer posting: SO stock → SO stock
        spec_stock     = 'E'             " Special stock: Sales order stock (both source & dest)
        material       = ls_req-material
        plant          = ls_req-plant    " Source plant
        stge_loc       = ls_req-sloc     " Source storage location
        batch          = ls_req-batch
        entry_qnt      = ls_req-quantity
        entry_uom      = ls_req-unit
        sales_ord      = ls_req-dest_so    " Destination sales order
        s_ord_item     = ls_req-dest_item  " Destination sales order item
        move_plant     = ls_req-plant        " Destination plant (same)
        move_stloc     = ls_req-sloc         " Destination storage location (same)
        val_sales_ord  = ls_req-source_so      " Source sales order
        val_s_ord_item = ls_req-source_item    " Source sales order item
        stck_type      = 'F'
      ) TO lt_gm_items.
    ENDLOOP.

    DATA ls_gm_matdoc TYPE bapi2017_gm_head_ret.
    DATA lt_return    TYPE bapiret2_t.

    " Call released goods movement API — commit handled by RAP framework
    CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
      EXPORTING
        goodsmvt_header  = ls_gm_header
        goodsmvt_code    = ls_gm_code
      IMPORTING
        goodsmvt_headret = ls_gm_matdoc
      TABLES
        goodsmvt_item    = lt_gm_items
        return           = lt_return.

    " Surface BAPI messages (errors and success) to the Fiori message strip.
    DATA lv_has_error TYPE abap_bool VALUE abap_false.

    LOOP AT lt_return INTO DATA(ls_ret) WHERE type CA 'ESAW'.
      DATA(lv_severity) = SWITCH #( ls_ret-type
        WHEN 'E' OR 'A' THEN if_abap_behv_message=>severity-error
        WHEN 'W'        THEN if_abap_behv_message=>severity-warning
        WHEN 'S'        THEN if_abap_behv_message=>severity-success
        ELSE                 if_abap_behv_message=>severity-information ).

      IF ls_ret-type CA 'EA'.
        lv_has_error = abap_true.
      ENDIF.

      APPEND VALUE #(
        %msg = new_message(
        id       = ls_ret-id
        number   = ls_ret-number
        severity = lv_severity
        v1       = ls_ret-message_v1
        v2       = ls_ret-message_v2
        v3       = ls_ret-message_v3
        v4       = ls_ret-message_v4
        )
      ) TO reported-ExcessStock.
    ENDLOOP.

    " Explicit success toast when BAPI returns no errors
    IF lv_has_error = abap_false AND ls_gm_matdoc-mat_doc IS NOT INITIAL.
      DATA ls_001 TYPE zmm_t001.
      LOOP AT lt_buffer INTO ls_req WHERE pallet IS NOT INITIAL.
        ls_001-mblnr = ls_gm_matdoc-mat_doc.
        ls_001-mjahr = ls_gm_matdoc-doc_year.
        ls_001-pallet = ls_req-pallet.
        MODIFY zmm_t001 FROM ls_req.
      ENDLOOP.


      APPEND VALUE #(
    %msg = new_message_with_text(
    severity = if_abap_behv_message=>severity-success
    text     = |Mat.doc { ls_gm_matdoc-mat_doc }/{ ls_gm_matdoc-doc_year } posted.|
    )
      ) TO reported-ExcessStock.
    ENDIF.

  ENDMETHOD.

ENDCLASS.