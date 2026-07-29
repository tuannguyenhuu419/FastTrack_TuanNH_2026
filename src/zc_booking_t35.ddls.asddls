@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection Booking'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['BookingId']
@Search.searchable: true
define root view entity ZC_BOOKING_T35
  provider contract transactional_query
  as projection on ZI_BOOKING_T35
{
  key BookingId,

      @ObjectModel.text.element: ['CustomerName']
      CustomerId,

      BookingDate,
      Description,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalPrice,
      CurrencyCode,

      -- ===== NEW FIELDS =====
      @ObjectModel.text.element: ['StatusText']
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_BOOKING_STATUS_VH_T35',
                                                     element: 'OverallStatus' },
                                           useForValidation: true }]
      OverallStatus,
      Priority,
      -- ======================

      ConfirmFlag,
      CustomerRating,
      CompletionPct,
      StatusCriticality,
      PriorityCriticality,

      -- denormalized customer attributes for field groups & contact demo
      _Customer.CustomerName as CustomerName,
      _Status.StatusText     as StatusText,
      @Semantics.eMail.address: true
      _Customer.Email        as CustomerEmail,
      _Customer.City         as CustomerCity,

      /* Associations */
      _BookingItem : redirected to composition child ZC_ITEM_T35,
      _Customer,
      _Status
}
