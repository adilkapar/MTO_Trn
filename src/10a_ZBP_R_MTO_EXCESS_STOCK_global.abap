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
        pallet      TYPE lgpla,
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