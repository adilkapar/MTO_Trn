@AbapCatalog.sqlViewName: 'ZRMTOSOCUST'
@EndUserText.label: 'SO Customer Helper'
define view ZR_MTO_SoCustomer
  as select from I_SalesOrder as SO
  left outer join I_Customer  as C on C.Customer = SO.SoldToParty
{
  key SO.SalesOrder,
      SO.SoldToParty       as Customer,
      C.BPCustomerFullName as CustomerName
}