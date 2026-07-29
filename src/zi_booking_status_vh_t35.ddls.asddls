@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Status - Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_BOOKING_STATUS_VH_T35
  as select from zstatus_t35
{
  key status      as OverallStatus,

      @Semantics.text: true
      status_text as StatusText
}
