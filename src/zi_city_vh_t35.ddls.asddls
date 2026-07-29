@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'City - Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_CITY_VH_T35
  as select distinct from zcustomer_t35
{
  key city as City
}
