@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking - Interface View'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_BOOKING_T35
  as select from zbooking_t35
  composition [0..*] of ZI_ITEM_T35              as _BookingItem
  association [0..1] to ZI_CUSTOMER_t35          as _Customer on $projection.CustomerId = _Customer.CustomerId
  association [0..1] to ZI_BOOKING_STATUS_VH_T35 as _Status   on $projection.OverallStatus = _Status.OverallStatus
{
  key booking_id            as BookingId,
      customer_id           as CustomerId,
      booking_date          as BookingDate,
      description           as Description,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_price           as TotalPrice,
      currency_code         as CurrencyCode,
      overall_status        as OverallStatus,
      confirm_flag          as ConfirmFlag,
      priority              as Priority,
      customer_rating       as CustomerRating,
      completion_pct        as CompletionPct,
      case overall_status
        when 'N' then 2        -- New       -> Yellow
        when 'A' then 3        -- Accepted  -> Green
        when 'X' then 1        -- Cancelled -> Red
        else 0
      end                   as StatusCriticality,

      case priority
        when '3' then 1        -- High   -> Red
        when '2' then 2        -- Medium -> Yellow
        when '1' then 3        -- Low    -> Green
        else 0
      end                   as PriorityCriticality,

      created_by            as CreatedBy,
      created_at            as CreatedAt,
      last_changed_by       as LastChangedBy,
      last_changed_at       as LastChangedAt,
      local_last_changed_at as LocalLastChangedAt,

      _BookingItem,
      _Customer,
      _Status
}
