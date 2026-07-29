@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Item - Interface View'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_ITEM_T35
  as select from zbkitem_t35
  association to parent ZI_BOOKING_T35 as _BookingHeader 
                on $projection.BookingId = _BookingHeader.BookingId
{
  key booking_id            as BookingId,
  key item_id               as ItemId,
      product_id            as ProductId,
      @Semantics.quantity.unitOfMeasure: 'QuantityUnit'
      quantity              as Quantity,
      quantity_unit         as QuantityUnit,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      item_price            as ItemPrice,
      currency_code         as CurrencyCode,
      last_changed_at       as LastChangedAt,
      local_last_changed_at as LocalLastChangedAt,
      
      _BookingHeader
}
