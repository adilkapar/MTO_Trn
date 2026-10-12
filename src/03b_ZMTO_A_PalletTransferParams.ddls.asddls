@EndUserText.label: 'Transfer by Pallet - Action Parameters'
define abstract entity ZMTO_A_PalletTransferParams
{
  @EndUserText.label        : 'Pallet No'
  PalletNumber              : lgpla;

  @EndUserText.label        : 'Plant'
  @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Plant', element: 'Plant' } }]
  Plant                     : werks_d;

  @EndUserText.label        : 'Destination Sales Order'
  @Consumption.valueHelpDefinition: [{
    entity                  : { name: 'ZVH_MTO_SalesOrder', element: 'SalesOrder' },
    additionalBinding       : [{ localElement: 'DestinationSalesOrderItem', element: 'SalesOrderItem' }]
  }]
  DestinationSalesOrder     : vbeln_va;

  @EndUserText.label        : 'Destination Sales Order Item'
  @Consumption.valueHelpDefinition: [{
    entity                  : { name: 'ZVH_MTO_SalesOrder', element: 'SalesOrderItem' },
    additionalBinding       : [{ localElement: 'DestinationSalesOrder', element: 'SalesOrder' }]
  }]
  DestinationSalesOrderItem : posnv;

  @EndUserText.label        : 'Posting Date'
  PostingDate               : abap.dats;

  @EndUserText.label        : 'Document Date'
  DocumentDate              : abap.dats;
}