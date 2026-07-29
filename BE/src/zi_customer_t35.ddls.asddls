@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Customer - Interface View'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_CUSTOMER_t35
  as select from zcustomer_t35
{
  key customer_id   as CustomerId,
  
      @Semantics.name.fullName: true
      customer_name as CustomerName,

      @Semantics.eMail.address: true
      @Semantics.eMail.type: [#WORK]
      email         as Email,

      @Semantics.telephone.type: [#WORK]
      phone         as Phone,

      @Semantics.address.city: true
      city          as City
}
