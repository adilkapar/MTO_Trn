@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'MTO - SO Item VC Configuration Pivot'
@ObjectModel.usageType: {
  serviceQuality: #X,
  sizeCategory:   #L,
  dataClass:      #MIXED
}

define view entity ZR_MTO_SoItemCharcVals
  as select from vbap       as p
    inner join   ibin       as i1 on i1.instance = p.cuobj
    inner join   ibinvalues as i2 on i2.in_recno = i1.in_recno
    inner join   ibsymbol   as i3 on i3.symbol_id = i2.symbol_id
    inner join   cabn       as c4 on c4.atinn = i3.atinn

{
  key p.vbeln                                                                  as SalesOrder,
  key cast( p.posnr as posnr_va preserving type )                              as SalesOrderItem,
      // ====================================================================
      // CHARACTER TYPE CHARACTERISTICS (Uses ATWRT)
      // ====================================================================
      // --- Common / General ---
      max( case c4.atnam when 'Z_PALLETTYPE'      then i3.atwrt else '' end )  as PalletType,
      max( case c4.atnam when 'ZMATTEXT'          then i3.atwrt else '' end )  as MaterialText,
      max( case c4.atnam when 'ZMATERIAL'         then i3.atwrt else '' end )  as MaterialNumber,
      max( case c4.atnam when 'ZMATERIAL1'        then i3.atwrt else '' end )  as MaterialNumber1,
      max( case c4.atnam when 'ZEXP_LOC_F'        then i3.atwrt else '' end )  as ChannelExpLoc,
      max( case c4.atnam when 'ZPROCESS'          then i3.atwrt else '' end )  as Process,
      max( case c4.atnam when 'ZMICRON'           then i3.atwrt else '' end )  as Micron,
      max( case c4.atnam when 'ZWIDTH'            then i3.atwrt else '' end )  as Width,
      max( case c4.atnam when 'ZBOXTYPE'          then i3.atwrt else '' end )  as BoxType,
      // --- Rigid Specific ---
      max( case c4.atnam when 'ZCATEGORY_R'       then i3.atwrt else '' end )  as CategoryRigid,
      max( case c4.atnam when 'ZGRAM_R'           then i3.atwrt else '' end )  as GramRigid,
      max( case c4.atnam when 'ZVERSION_R'        then i3.atwrt else '' end )  as VersionRigid,
      max( case c4.atnam when 'ZCOLOR_R'          then i3.atwrt else '' end )  as ColorRigid,
      max( case c4.atnam when 'ZNECKRING_R'       then i3.atwrt else '' end )  as NeckringRigid,
      max( case c4.atnam when 'ZLOGO_R'           then i3.atwrt else '' end )  as LogoRigid,
      max( case c4.atnam when 'ZADDITIVIES_R'     then i3.atwrt else '' end )  as AdditivesRigid,
      max( case c4.atnam when 'ZINNER_QTY'        then i3.atwrt else '' end )  as InnerQtyRigid,
      max( case c4.atnam when 'ZCOLOR_LDR_R'      then i3.atwrt else '' end )  as ColorLdrRigid,
      // --- Flexible Specific ---
      max( case c4.atnam when 'ZCATEGORY_F'       then i3.atwrt else '' end )  as CategoryFlex,
      max( case c4.atnam when 'ZSCATEGORY_F'      then i3.atwrt else '' end )  as SubCategoryFlex,
      max( case c4.atnam when 'ZRECIPE_F'         then i3.atwrt else '' end )  as RecipeFlex,
      max( case c4.atnam when 'ZCORE_F'           then i3.atwrt else '' end )  as CoreFlex,
      max( case c4.atnam when 'ZDESIGN_NUMBER_F'  then i3.atwrt else '' end )  as DesignNumberFlex,
      max( case c4.atnam when 'ZPRICE_COMB_F'     then i3.atwrt else '' end )  as PriceCombFlex,
      max( case c4.atnam when 'Z_F_WIDTH'         then i3.atwrt else '' end )  as FlexWidth,
      max( case c4.atnam when 'Z_F_ALLOY'         then i3.atwrt else '' end )  as FlexAlloy,
      max( case c4.atnam when 'Z_F_CORE_MATERIAL' then i3.atwrt else '' end )  as FlexCoreMaterial,
      max( case c4.atnam when 'Z_F_UNWIND_DIR'    then i3.atwrt else '' end )  as FlexUnwindDir,
      // ====================================================================
      // NUMERIC TYPE CHARACTERISTICS (Uses ATFLV)
      // ====================================================================
      // --- Common & Rigid Weights ---
      max( case c4.atnam when 'ZPALWEIGHT10'      then i3.atflv else 0.0 end ) as PalletWeight10,
      max( case c4.atnam when 'ZBOXWEIGHT'        then i3.atflv else 0.0 end ) as BoxWeight,
      max( case c4.atnam when 'ZNETWEIGHT'        then i3.atflv else 0.0 end ) as NetWeight,
      max( case c4.atnam when 'ZNETWEIGHTSO'      then i3.atflv else 0.0 end ) as NetWeightSO,
      max( case c4.atnam when 'ZGRWEIGHT'         then i3.atflv else 0.0 end ) as GrossWeight,
      // --- Flexible Specific Numerics ---
      max( case c4.atnam when 'ZPALWEIGHT1_F'     then i3.atflv else 0.0 end ) as PalletWeight1Flex,
      max( case c4.atnam when 'ZBOXWEIGHT_F'      then i3.atflv else 0.0 end ) as BoxWeightFlex,
      max( case c4.atnam when 'Z_F_AL_THICKNESS'  then i3.atflv else 0.0 end ) as FlexAlThickness,
      max( case c4.atnam when 'Z_F_FOIL_THICK'    then i3.atflv else 0.0 end ) as FlexFoilThickness,
      max( case c4.atnam when 'Z_F_PAPER_THICK'   then i3.atflv else 0.0 end ) as FlexPaperThickness

}
where
  p.posnr > '000000'
group by
  p.vbeln,
  p.posnr