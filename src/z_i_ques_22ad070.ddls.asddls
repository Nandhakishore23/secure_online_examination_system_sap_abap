@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Question Interface 22AD070'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z_I_QUES_22AD070
  as select from zexm_q_22ad070
  association to parent Z_I_EXAM_22AD070 as _Exam on $projection.parent_uuid = _Exam.exam_uuid
{
  key ques_uuid,
      parent_uuid,
      question_text,
      option_a,
      option_b,
      option_c,
      option_d,
      /* We do NOT expose correct_answer here for security if this were a public view */
      correct_answer, 
      
      _Exam
}
