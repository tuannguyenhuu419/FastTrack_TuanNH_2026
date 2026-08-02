@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Item - Projection'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZC_ITEM_T35
  as projection on ZI_ITEM_T35
{
  key BookingId,
  key ItemId,
      ProductId,
      @Semantics.quantity.unitOfMeasure: 'QuantityUnit'
      Quantity,
      QuantityUnit,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      ItemPrice,
      CurrencyCode,
      LastChangedAt,
      LocalLastChangedAt,
      
      /* Associations */
      _BookingHeader : redirected to parent ZC_BOOKING_T35
}
