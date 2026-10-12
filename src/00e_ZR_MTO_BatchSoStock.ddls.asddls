@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'MTO Batch SO Stock (from MSKA)'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: {
  serviceQuality: #B,
  sizeCategory:   #L,
  dataClass:      #MIXED
}

define view entity ZR_MTO_BatchSoStock
  as select from nsdm_e_mska as mska
  inner join mara on mara.matnr = mska.matnr
  left outer join lqua as l on l.charg = mska.charg and l.werks = mska.werks and l.matnr = mska.matnr   
{
  key mska.matnr  as Material,
  key mska.werks  as Plant,
  key mska.lgort  as StorageLocation,
  key mska.charg  as Batch,
  key mska.vbeln  as SalesOrder,
  key mska.posnr  as SalesOrderItem,

  @Semantics.quantity.unitOfMeasure: 'BaseUnit'
  mska.kalab      as StockQuantity,

  mara.meins      as BaseUnit,
  l.lgpla         as pallet
}
where mska.sobkz = 'E'
  and mska.kalab > 0
  and ( mara.mtart = 'ZFG' or mara.mtart = 'ZSF' )