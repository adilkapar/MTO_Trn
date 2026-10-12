@EndUserText.label: 'MTO Excess Stock - Projection View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define root view entity ZC_MTO_ExcessStock
  provider contract transactional_query
  as projection on ZR_MTO_ExcessStock

{
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZVH_MTO_Material', element: 'Product' } }]
  key Material,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Plant', element: 'Plant' } }]
      @Consumption.filter: { mandatory: true, selectionType: #SINGLE }
  key Plant,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_StorageLocation', element: 'StorageLocation' },
        additionalBinding: [{ localElement: 'Plant', element: 'Plant' }] }]
  key StorageLocation,
  key Batch,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZVH_MTO_SalesOrder', element: 'SalesOrder' } }]
  key SalesOrder,
  key SalesOrderItem,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_BusinessPartner', element: 'BusinessPartner' } }]
      Customer,
      CustomerName,

      StockQuantity,
      BaseUnit,
      MaterialDescription,
      BatchCreatedDateTime,

      @EndUserText.label: 'Pallet No'
      pallet,

      // --- Common / General ---
      PalletType,
      MaterialText,
      MaterialNumber,
      MaterialNumber1,
      ChannelExpLoc,
      Process,
      Micron,
      Width,
      BoxType,

      // --- Rigid Specific ---
      CategoryRigid,
      GramRigid,
      VersionRigid,
      ColorRigid,
      NeckringRigid,
      LogoRigid,
      AdditivesRigid,
      InnerQtyRigid,
      ColorLdrRigid,

      // --- Flexible Specific ---
      CategoryFlex,
      SubCategoryFlex,
      RecipeFlex,
      CoreFlex,
      DesignNumberFlex,
      PriceCombFlex,
      FlexWidth,
      FlexAlloy,
      FlexCoreMaterial,
      FlexUnwindDir,

      // --- Numeric Characteristics ---
      PalletWeight10,
      BoxWeight,
      NetWeight,
      NetWeightSO,
      GrossWeight,
      PalletWeight1Flex,
      BoxWeightFlex,
      FlexAlThickness,
      FlexFoilThickness,
      FlexPaperThickness
}