@EndUserText.label: 'Exam Projection 22AD070'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define root view entity Z_C_EXAM_22AD070
  provider contract transactional_query
  as projection on Z_I_EXAM_22AD070
{
    key exam_uuid,
    exam_id,
    title,
    duration,
    status,
    created_by,
    created_at,
    last_changed_at,
    
    /* Redirected to Projection Child */
    _Questions : redirected to composition child Z_C_QUES_22AD070
}
