@EndUserText.label: 'Question Projection 22AD070'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define view entity Z_C_QUES_22AD070
  as projection on Z_I_QUES_22AD070
{
    key ques_uuid,
    parent_uuid,
    question_text,
    option_a,
    option_b,
    option_c,
    option_d,
    
    /* Hidden from UI but available for logic */

    correct_answer,
    
    /* Redirected to Parent Projection */
    _Exam : redirected to parent Z_C_EXAM_22AD070
}
