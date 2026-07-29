@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Confirm Flag - VH'
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_CONFIRM_VH_T35
  as select from    DDCDS_CUSTOMER_DOMAIN_VALUE(
                      p_domain_name : 'ZD_CONFIRM_T35' ) as Values
    left outer join DDCDS_CUSTOMER_DOMAIN_VALUE_T(
                      p_domain_name : 'ZD_CONFIRM_T35' ) as Texts on  Texts.domain_name    = Values.domain_name
                                                                   and Texts.value_position = Values.value_position
                                                                   and Texts.language       = $session.system_language
{
      @ObjectModel.text.element: [ 'Description' ]
      @UI.textArrangement: #TEXT_LAST
  key Values.value_low as ConfirmFlag,

      Texts.text       as Description
}
