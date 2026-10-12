@AbapCatalog.sqlViewName: 'ZVHMTOMAT'
@EndUserText.label: 'MTO Material Value Help'
@Search.searchable: true
define view ZVH_MTO_Material
  as select from I_Product
  association [0..1] to I_ProductText as _Text
    on  _Text.Product  = I_Product.Product
    and _Text.Language  = $session.system_language
{
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
  key Product,
      _Text.ProductName as ProductDescription,
      ProductType
}
where
     ProductType = 'ZFG'
  or ProductType = 'ZSF'