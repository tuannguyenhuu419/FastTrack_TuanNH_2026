@EndUserText.label: 'Parameter cho Dialog Get Filter'
define abstract entity ZA_FILTER_PARAM_T35
{

  customer_id    : abap.char(10);
  booking_date_l : dats;
  booking_date_h : dats;
  status         : abap.char(40);
  city           : abap.char(40);
  confirm_flag   : ze_confirm_t35;
  priority       : ze_priority_t35;
}
