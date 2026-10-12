@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'MTO Excess Stock - Root View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: {
  serviceQuality: #X,
  sizeCategory:   #M,
  dataClass:      #MIXED
}

define root view entity ZR_MTO_ExcessStock
  as select from ZR_MTO_BatchSoStock as Stock

  association [0..1] to ZR_MTO_SoCustomer      as _SoCustomer  on  _SoCustomer.SalesOrder = Stock.SalesOrder
  association [0..1] to I_Product              as _Product     on  _Product.Product       = Stock.Material
  association [0..1] to I_ProductText          as _ProductText on  _ProductText.Product   = Stock.Material
                                                               and _ProductText.Language  = $session.system_language
  association [0..1] to I_Batch                as _Batch       on  _Batch.Material = Stock.Material
                                                               and _Batch.Plant    = Stock.Plant
                                                               and _Batch.Batch    = Stock.Batch
  association [0..1] to ZR_MTO_SoItemCharcVals as _SoItemCharcs on  _SoItemCharcs.SalesOrder     = Stock.SalesOrder
                                                                and _SoItemCharcs.SalesOrderItem = Stock.SalesOrderItem

{
  key Stock.Material                     as Material,
  key Stock.Plant                        as Plant,
  key Stock.StorageLocation              as StorageLocation,
  key Stock.Batch                        as Batch,
  key Stock.SalesOrder                   as SalesOrder,
  key Stock.SalesOrderItem               as SalesOrderItem,

      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      Stock.StockQuantity                as StockQuantity,
      Stock.BaseUnit                     as BaseUnit,
      Stock.pallet                       as pallet,

      _ProductText.ProductName           as MaterialDescription,
      _Batch.CreationDateTime            as BatchCreatedDateTime,

      // --- Common / General ---
      _SoItemCharcs.PalletType           as PalletType,
      _SoItemCharcs.MaterialText         as MaterialText,
      _SoItemCharcs.MaterialNumber       as MaterialNumber,
      _SoItemCharcs.MaterialNumber1      as MaterialNumber1,
      _SoItemCharcs.ChannelExpLoc        as ChannelExpLoc,
      _SoItemCharcs.Process              as Process,
      _SoItemCharcs.Micron               as Micron,
      _SoItemCharcs.Width                as Width,
      _SoItemCharcs.BoxType              as BoxType,
      // --- Rigid Specific ---
      _SoItemCharcs.CategoryRigid        as CategoryRigid,
      _SoItemCharcs.GramRigid            as GramRigid,
      _SoItemCharcs.VersionRigid         as VersionRigid,
      _SoItemCharcs.ColorRigid           as ColorRigid,
      _SoItemCharcs.NeckringRigid        as NeckringRigid,
      _SoItemCharcs.LogoRigid            as LogoRigid,
      _SoItemCharcs.AdditivesRigid       as AdditivesRigid,
      _SoItemCharcs.InnerQtyRigid        as InnerQtyRigid,
      _SoItemCharcs.ColorLdrRigid        as ColorLdrRigid,
      // --- Flexible Specific ---
      _SoItemCharcs.CategoryFlex         as CategoryFlex,
      _SoItemCharcs.SubCategoryFlex      as SubCategoryFlex,
      _SoItemCharcs.RecipeFlex           as RecipeFlex,
      _SoItemCharcs.CoreFlex             as CoreFlex,
      _SoItemCharcs.DesignNumberFlex     as DesignNumberFlex,
      _SoItemCharcs.PriceCombFlex        as PriceCombFlex,
      _SoItemCharcs.FlexWidth            as FlexWidth,
      _SoItemCharcs.FlexAlloy            as FlexAlloy,
      _SoItemCharcs.FlexCoreMaterial     as FlexCoreMaterial,
      _SoItemCharcs.FlexUnwindDir        as FlexUnwindDir,
      // --- Numeric Characteristics ---
      _SoItemCharcs.PalletWeight10       as PalletWeight10,
      _SoItemCharcs.BoxWeight            as BoxWeight,
      _SoItemCharcs.NetWeight            as NetWeight,
      _SoItemCharcs.NetWeightSO          as NetWeightSO,
      _SoItemCharcs.GrossWeight          as GrossWeight,
      _SoItemCharcs.PalletWeight1Flex    as PalletWeight1Flex,
      _SoItemCharcs.BoxWeightFlex        as BoxWeightFlex,
      _SoItemCharcs.FlexAlThickness      as FlexAlThickness,
      _SoItemCharcs.FlexFoilThickness    as FlexFoilThickness,
      _SoItemCharcs.FlexPaperThickness   as FlexPaperThickness,

      _SoCustomer.Customer               as Customer,
      _SoCustomer.CustomerName           as CustomerName,

      /* Associations published for projection */
      _Product,
      _ProductText,
      _Batch,
      _SoItemCharcs
}
