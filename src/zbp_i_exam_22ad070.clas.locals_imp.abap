" 1. THE BUFFER CLASS: Temporarily holds data until the user clicks 'Save'
CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA:
      mt_exam_create TYPE TABLE OF zexm_h_22ad070,
      mt_exam_update TYPE TABLE OF zexm_h_22ad070,
      mt_exam_delete TYPE TABLE OF zexm_h_22ad070,
      mt_ques_create TYPE TABLE OF zexm_q_22ad070,
      mt_ques_update TYPE TABLE OF zexm_q_22ad070,
      mt_ques_delete TYPE TABLE OF zexm_q_22ad070,
      mt_res_create  TYPE TABLE OF zexm_r_22ad070. " Buffer for results
ENDCLASS.

CLASS lhc_Z_I_EXAM_22AD070 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR z_i_exam_22ad070 RESULT result.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR z_i_exam_22ad070 RESULT result.
    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE z_i_exam_22ad070.
    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE z_i_exam_22ad070.
    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE z_i_exam_22ad070.
    METHODS read FOR READ
      IMPORTING keys FOR READ z_i_exam_22ad070 RESULT result.
    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK z_i_exam_22ad070.
    METHODS rba_Questions FOR READ
      IMPORTING keys_rba FOR READ z_i_exam_22ad070\_Questions FULL result_requested RESULT result LINK association_links.
    METHODS cba_Questions FOR MODIFY
      IMPORTING entities_cba FOR CREATE z_i_exam_22ad070\_Questions.

    " NEW ACTION: Submit Exam Logic
    METHODS submitExam FOR MODIFY
      IMPORTING keys FOR ACTION z_i_exam_22ad070~submitExam RESULT result.

ENDCLASS.

CLASS lhc_Z_I_EXAM_22AD070 IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD create.
    DATA lt_exam_db TYPE TABLE OF zexm_h_22ad070.
    DATA ls_exam_db TYPE zexm_h_22ad070.

    LOOP AT entities INTO DATA(ls_entity).
      ls_exam_db-client      = sy-mandt.
      TRY.
          ls_exam_db-exam_uuid = cl_system_uuid=>create_uuid_x16_static( ).
        CATCH cx_uuid_error.
      ENDTRY.
      ls_exam_db-exam_id     = ls_entity-exam_id.
      ls_exam_db-title       = ls_entity-title.
      ls_exam_db-duration    = ls_entity-duration.
      ls_exam_db-status      = ls_entity-status.
      ls_exam_db-created_by  = sy-uname.
      GET TIME STAMP FIELD ls_exam_db-created_at.
      ls_exam_db-last_changed_at = ls_exam_db-created_at.

      APPEND ls_exam_db TO lt_exam_db.

      INSERT VALUE #( %cid = ls_entity-%cid
                      exam_uuid = ls_exam_db-exam_uuid ) INTO TABLE mapped-z_i_exam_22ad070.
    ENDLOOP.

    IF lt_exam_db IS NOT INITIAL.
      APPEND LINES OF lt_exam_db TO lcl_buffer=>mt_exam_create.
    ENDIF.
  ENDMETHOD.

  METHOD update.
    DATA lt_exam_db TYPE TABLE OF zexm_h_22ad070.
    SELECT * FROM zexm_h_22ad070 FOR ALL ENTRIES IN @entities
             WHERE exam_uuid = @entities-exam_uuid INTO TABLE @lt_exam_db.

    LOOP AT entities INTO DATA(ls_entity).
      READ TABLE lt_exam_db ASSIGNING FIELD-SYMBOL(<fs_exam>) WITH KEY exam_uuid = ls_entity-exam_uuid.
      IF sy-subrc = 0.
        IF ls_entity-%control-title = if_abap_behv=>mk-on. <fs_exam>-title = ls_entity-title. ENDIF.
        IF ls_entity-%control-duration = if_abap_behv=>mk-on. <fs_exam>-duration = ls_entity-duration. ENDIF.
        IF ls_entity-%control-status = if_abap_behv=>mk-on. <fs_exam>-status = ls_entity-status. ENDIF.
        GET TIME STAMP FIELD <fs_exam>-last_changed_at.
        APPEND <fs_exam> TO lcl_buffer=>mt_exam_update.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys INTO DATA(ls_key).
      APPEND VALUE #( exam_uuid = ls_key-exam_uuid ) TO lcl_buffer=>mt_exam_delete.
    ENDLOOP.
  ENDMETHOD.

  METHOD submitExam.
    " 1. Read the entities
    READ ENTITIES OF z_i_exam_22ad070 IN LOCAL MODE
      ENTITY z_i_exam_22ad070
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exams).

    " 2. Loop through the results (creates ls_exam)
    LOOP AT lt_exams INTO DATA(ls_exam).
      DATA(ls_res) = VALUE zexm_r_22ad070( ).

      ls_res-client       = sy-mandt.

      TRY.
          ls_res-res_uuid = cl_system_uuid=>create_uuid_x16_static( ).
        CATCH cx_uuid_error.
      ENDTRY.

      " Link to the exam and capture secure student identity
      ls_res-exam_uuid    = ls_exam-exam_uuid.
      ls_res-student_id   = sy-uname.
      ls_res-total_marks  = 100. " Simulated 100% Score
      ls_res-percentage   = '100.00'.
      ls_res-status       = 'PASSED'.

      GET TIME STAMP FIELD ls_res-attempted_at.

      " Buffer the result for the Save phase
      APPEND ls_res TO lcl_buffer=>mt_res_create.
    ENDLOOP.

    " 3. Fill the result parameter to update the UI
    " FIX: We use 'ls_exam_out' here so it doesn't clash with 'ls_exam' above
    result = VALUE #( FOR ls_exam_out IN lt_exams (
                         %tky   = ls_exam_out-%tky
                         %param = CORRESPONDING #( ls_exam_out ) ) ).
  ENDMETHOD.

  METHOD read. ENDMETHOD.
  METHOD lock. ENDMETHOD.
  METHOD rba_Questions. ENDMETHOD.

  METHOD cba_Questions.
    DATA lt_ques_db TYPE TABLE OF zexm_q_22ad070.
    DATA ls_ques_db TYPE zexm_q_22ad070.

    LOOP AT entities_cba INTO DATA(ls_cba).
      LOOP AT ls_cba-%target INTO DATA(ls_target).
        ls_ques_db-client      = sy-mandt.
        ls_ques_db-parent_uuid = ls_cba-exam_uuid.
        TRY.
            ls_ques_db-ques_uuid = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
        ENDTRY.
        ls_ques_db-question_text  = ls_target-question_text.
        ls_ques_db-option_a       = ls_target-option_a.
        ls_ques_db-option_b       = ls_target-option_b.
        ls_ques_db-option_c       = ls_target-option_c.
        ls_ques_db-option_d       = ls_target-option_d.
        ls_ques_db-correct_answer = ls_target-correct_answer.

        APPEND ls_ques_db TO lt_ques_db.
        INSERT VALUE #( %cid = ls_target-%cid ques_uuid = ls_ques_db-ques_uuid ) INTO TABLE mapped-z_i_ques_22ad070.
      ENDLOOP.
    ENDLOOP.

    IF lt_ques_db IS NOT INITIAL.
      APPEND LINES OF lt_ques_db TO lcl_buffer=>mt_ques_create.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_Z_I_QUES_22AD070 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE z_i_ques_22ad070.
    METHODS delete FOR MODIFY IMPORTING keys FOR DELETE z_i_ques_22ad070.
    METHODS read FOR READ IMPORTING keys FOR READ z_i_ques_22ad070 RESULT result.
    METHODS rba_Exam FOR READ IMPORTING keys_rba FOR READ z_i_ques_22ad070\_Exam FULL result_requested RESULT result LINK association_links.
ENDCLASS.

CLASS lhc_Z_I_QUES_22AD070 IMPLEMENTATION.
  METHOD update.
    DATA lt_ques_db TYPE TABLE OF zexm_q_22ad070.
    SELECT * FROM zexm_q_22ad070 FOR ALL ENTRIES IN @entities WHERE ques_uuid = @entities-ques_uuid INTO TABLE @lt_ques_db.
    LOOP AT entities INTO DATA(ls_entity).
      READ TABLE lt_ques_db ASSIGNING FIELD-SYMBOL(<fs_ques>) WITH KEY ques_uuid = ls_entity-ques_uuid.
      IF sy-subrc = 0.
        IF ls_entity-%control-question_text = if_abap_behv=>mk-on. <fs_ques>-question_text = ls_entity-question_text. ENDIF.
        IF ls_entity-%control-option_a = if_abap_behv=>mk-on. <fs_ques>-option_a = ls_entity-option_a. ENDIF.
        IF ls_entity-%control-option_b = if_abap_behv=>mk-on. <fs_ques>-option_b = ls_entity-option_b. ENDIF.
        IF ls_entity-%control-option_c = if_abap_behv=>mk-on. <fs_ques>-option_c = ls_entity-option_c. ENDIF.
        IF ls_entity-%control-option_d = if_abap_behv=>mk-on. <fs_ques>-option_d = ls_entity-option_d. ENDIF.
        IF ls_entity-%control-correct_answer = if_abap_behv=>mk-on. <fs_ques>-correct_answer = ls_entity-correct_answer. ENDIF.
        APPEND <fs_ques> TO lcl_buffer=>mt_ques_update.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys INTO DATA(ls_key).
      APPEND VALUE #( ques_uuid = ls_key-ques_uuid ) TO lcl_buffer=>mt_ques_delete.
    ENDLOOP.
  ENDMETHOD.
  METHOD read. ENDMETHOD.
  METHOD rba_Exam. ENDMETHOD.
ENDCLASS.

CLASS lsc_Z_I_EXAM_22AD070 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS finalize REDEFINITION.
    METHODS check_before_save REDEFINITION.
    METHODS save REDEFINITION.
    METHODS cleanup REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.
ENDCLASS.

CLASS lsc_Z_I_EXAM_22AD070 IMPLEMENTATION.
  METHOD finalize. ENDMETHOD.
  METHOD check_before_save. ENDMETHOD.

  METHOD save.
    " HEADER
    IF lcl_buffer=>mt_exam_create IS NOT INITIAL. INSERT zexm_h_22ad070 FROM TABLE @lcl_buffer=>mt_exam_create. ENDIF.
    IF lcl_buffer=>mt_exam_update IS NOT INITIAL. UPDATE zexm_h_22ad070 FROM TABLE @lcl_buffer=>mt_exam_update. ENDIF.
    IF lcl_buffer=>mt_exam_delete IS NOT INITIAL.
       LOOP AT lcl_buffer=>mt_exam_delete INTO DATA(ls_del).
         DELETE FROM zexm_q_22ad070 WHERE parent_uuid = @ls_del-exam_uuid.
       ENDLOOP.
       DELETE zexm_h_22ad070 FROM TABLE @lcl_buffer=>mt_exam_delete.
    ENDIF.

    " QUESTIONS
    IF lcl_buffer=>mt_ques_create IS NOT INITIAL. INSERT zexm_q_22ad070 FROM TABLE @lcl_buffer=>mt_ques_create. ENDIF.
    IF lcl_buffer=>mt_ques_update IS NOT INITIAL. UPDATE zexm_q_22ad070 FROM TABLE @lcl_buffer=>mt_ques_update. ENDIF.
    IF lcl_buffer=>mt_ques_delete IS NOT INITIAL. DELETE zexm_q_22ad070 FROM TABLE @lcl_buffer=>mt_ques_delete. ENDIF.

    " RESULTS (SECURE STORAGE)
    IF lcl_buffer=>mt_res_create IS NOT INITIAL. INSERT zexm_r_22ad070 FROM TABLE @lcl_buffer=>mt_res_create. ENDIF.
  ENDMETHOD.

  METHOD cleanup.
    CLEAR: lcl_buffer=>mt_exam_create, lcl_buffer=>mt_exam_update, lcl_buffer=>mt_exam_delete,
           lcl_buffer=>mt_ques_create, lcl_buffer=>mt_ques_update, lcl_buffer=>mt_ques_delete,
           lcl_buffer=>mt_res_create.
  ENDMETHOD.
  METHOD cleanup_finalize. ENDMETHOD.
ENDCLASS.
