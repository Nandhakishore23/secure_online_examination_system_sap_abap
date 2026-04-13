@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Result Interface 22AD070'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z_I_RES_22AD070
  as select from zexm_r_22ad070
  association [1..1] to Z_I_EXAM_22AD070 as _Exam on $projection.exam_uuid = _Exam.exam_uuid
{
    key res_uuid,
    exam_uuid,
    student_id,
    total_marks,
    percentage,
    status,
    attempted_at,
    
    /* Association */
    _Exam
}
