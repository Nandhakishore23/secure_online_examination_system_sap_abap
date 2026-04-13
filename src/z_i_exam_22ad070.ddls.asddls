@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Exam Header Interface 22AD070'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity Z_I_EXAM_22AD070
  as select from zexm_h_22ad070
  composition [0..*] of Z_I_QUES_22AD070 as _Questions
{
  key exam_uuid,
      exam_id,
      title,
      duration,
      status,
      created_by,
      created_at,
      last_changed_at,
      
      /* Adhoc Association for Results */
      _Questions
}
