@AbapCatalog.sqlViewName: 'ZVHMTOSO'
@EndUserText.label: 'MTO Sales Order Value Help'
@Search.searchable: true
define view ZVH_MTO_SalesOrder
  as select distinct from I_SalesOrder     as SO
    inner join            I_SalesOrderItem as Item on Item.SalesOrder = SO.SalesOrder
    inner join            I_Product        as P    on P.Product       = Item.Material
{
      @Search.defaultSearchElement: true
  key SO.SalesOrder,
  key Item.SalesOrderItem,
      Item.SalesOrderItemText,
      P.Product,
      SO.SoldToParty,
      SO.CreationDate
}
where
     P.ProductType = 'ZFG'
  or P.ProductType = 'ZSF'