@EndUserText.label: 'Transfer Stock - Action Parameters'
define abstract entity ZMTO_A_TransferParams
{
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