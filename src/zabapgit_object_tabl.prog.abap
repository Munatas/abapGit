*&---------------------------------------------------------------------*
*&  Include           ZABAPGIT_OBJECT_TABL
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
*       CLASS lcl_object_tabl DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_object_tabl DEFINITION INHERITING FROM lcl_objects_super FINAL.

  PUBLIC SECTION.
    INTERFACES lif_object.
    ALIASES mo_files FOR lif_object~mo_files.

ENDCLASS.                    "lcl_object_dtel DEFINITION

*----------------------------------------------------------------------*
*       CLASS lcl_object_tabl IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_object_tabl IMPLEMENTATION.

  METHOD lif_object~changed_by.

    SELECT SINGLE as4user FROM dd02l INTO rv_user
      WHERE tabname = ms_item-obj_name
      AND as4local = 'A'
      AND as4vers = '0000'.
    IF sy-subrc <> 0.
      rv_user = c_user_unknown.
    ENDIF.

  ENDMETHOD.

  METHOD lif_object~get_metadata.
    rs_metadata = get_metadata( ).
  ENDMETHOD.                    "lif_object~get_metadata

  METHOD lif_object~exists.

    DATA: lv_tabname TYPE dd02l-tabname.


    SELECT SINGLE tabname FROM dd02l INTO lv_tabname
      WHERE tabname = ms_item-obj_name
      AND as4local = 'A'
      AND as4vers = '0000'.
    rv_bool = boolc( sy-subrc = 0 ).

  ENDMETHOD.                    "lif_object~exists

  METHOD lif_object~jump.

    jump_se11( iv_radio = 'RSRD1-DDTYPE'
               iv_field = 'RSRD1-DDTYPE_VAL' ).

  ENDMETHOD.                    "jump

  METHOD lif_object~delete.

    DATA: lv_objname TYPE rsedd0-ddobjname.


    lv_objname = ms_item-obj_name.

    CALL FUNCTION 'RS_DD_DELETE_OBJ'
      EXPORTING
        no_ask               = abap_false
        objname              = lv_objname
        objtype              = 'T'
      EXCEPTIONS
        not_executed         = 1
        object_not_found     = 2
        object_not_specified = 3
        permission_failure   = 4.
    IF sy-subrc <> 0.
      _raise 'error from RS_DD_DELETE_OBJ, TABL'.
    ENDIF.

  ENDMETHOD.                    "delete

  METHOD lif_object~serialize.

    DATA: lv_name  TYPE ddobjname,
          ls_dd02v TYPE dd02v,
          ls_dd09l TYPE dd09l,
          lt_dd03p TYPE TABLE OF dd03p,
          lt_dd05m TYPE TABLE OF dd05m,
          lt_dd08v TYPE TABLE OF dd08v,
          lt_dd12v TYPE dd12vtab,
          lt_dd17v TYPE dd17vtab,
          lt_dd35v TYPE TABLE OF dd35v,
          lt_dd36m TYPE dd36mttyp.

    FIELD-SYMBOLS: <ls_dd12v> LIKE LINE OF lt_dd12v,
                   <ls_dd03p> LIKE LINE OF lt_dd03p.


    lv_name = ms_item-obj_name.

    CALL FUNCTION 'DDIF_TABL_GET'
      EXPORTING
        name          = lv_name
        langu         = mv_language
      IMPORTING
        dd02v_wa      = ls_dd02v
        dd09l_wa      = ls_dd09l
      TABLES
        dd03p_tab     = lt_dd03p
        dd05m_tab     = lt_dd05m
        dd08v_tab     = lt_dd08v
        dd12v_tab     = lt_dd12v
        dd17v_tab     = lt_dd17v
        dd35v_tab     = lt_dd35v
        dd36m_tab     = lt_dd36m
      EXCEPTIONS
        illegal_input = 1
        OTHERS        = 2.
    IF sy-subrc <> 0.
      _raise 'error from DDIF_TABL_GET'.
    ENDIF.
    IF ls_dd02v IS INITIAL.
      RETURN. " object does not exits
    ENDIF.

    CLEAR: ls_dd02v-as4user,
           ls_dd02v-as4date,
           ls_dd02v-as4time.

    CLEAR: ls_dd09l-as4user,
           ls_dd09l-as4date,
           ls_dd09l-as4time.

    LOOP AT lt_dd12v ASSIGNING <ls_dd12v>.
      CLEAR: <ls_dd12v>-as4user,
             <ls_dd12v>-as4date,
             <ls_dd12v>-as4time.
    ENDLOOP.

    LOOP AT lt_dd03p ASSIGNING <ls_dd03p> WHERE NOT rollname IS INITIAL.
      CLEAR: <ls_dd03p>-ddlanguage,
        <ls_dd03p>-dtelmaster,
        <ls_dd03p>-ddtext,
        <ls_dd03p>-reptext,
        <ls_dd03p>-scrtext_s,
        <ls_dd03p>-scrtext_m,
        <ls_dd03p>-scrtext_l.

      IF <ls_dd03p>-comptype = 'E'.
* type specified via data element
        CLEAR: <ls_dd03p>-domname,
          <ls_dd03p>-inttype,
          <ls_dd03p>-intlen,
          <ls_dd03p>-mask,
          <ls_dd03p>-memoryid,
          <ls_dd03p>-headlen,
          <ls_dd03p>-scrlen1,
          <ls_dd03p>-scrlen2,
          <ls_dd03p>-scrlen3,
          <ls_dd03p>-datatype,
          <ls_dd03p>-leng,
          <ls_dd03p>-outputlen,
          <ls_dd03p>-entitytab,
          <ls_dd03p>-dommaster,
          <ls_dd03p>-domname3l.
      ENDIF.

      IF <ls_dd03p>-shlporigin = 'D'.
* search help from domain
        CLEAR: <ls_dd03p>-shlpfield,
          <ls_dd03p>-shlpname.
      ENDIF.

* XML output assumes correct field content
      IF <ls_dd03p>-routputlen = '      '.
        CLEAR <ls_dd03p>-routputlen.
      ENDIF.
    ENDLOOP.

    io_xml->add( iv_name = 'DD02V'
                 ig_data = ls_dd02v ).
    io_xml->add( iv_name = 'DD09L'
                 ig_data = ls_dd09l ).
    io_xml->add( ig_data = lt_dd03p
                 iv_name = 'DD03P_TABLE' ).
    io_xml->add( ig_data = lt_dd05m
                 iv_name = 'DD05M_TABLE' ).
    io_xml->add( ig_data = lt_dd08v
                 iv_name = 'DD08V_TABLE' ).
    io_xml->add( iv_name = 'DD12V'
                 ig_data = lt_dd12v ).
    io_xml->add( iv_name = 'DD17V'
                 ig_data = lt_dd17v ).
    io_xml->add( ig_data = lt_dd35v
                 iv_name = 'DD35V_TALE' ).
    io_xml->add( iv_name = 'DD36M'
                 ig_data = lt_dd36m ).

  ENDMETHOD.                    "serialize

  METHOD lif_object~deserialize.

    DATA: lv_name      TYPE ddobjname,
          lv_tname     TYPE trobj_name,
          ls_dd02v     TYPE dd02v,
          ls_dd09l     TYPE dd09l,
          lt_dd03p     TYPE TABLE OF dd03p,
          lt_dd05m     TYPE TABLE OF dd05m,
          lt_dd08v     TYPE TABLE OF dd08v,
          lt_dd12v     TYPE dd12vtab,
          lt_dd17v     TYPE dd17vtab,
          ls_dd17v     LIKE LINE OF lt_dd17v,
          lt_secondary LIKE lt_dd17v,
          lt_dd35v     TYPE TABLE OF dd35v,
          lt_dd36m     TYPE dd36mttyp,
          ls_dd12v     LIKE LINE OF lt_dd12v.


    io_xml->read( EXPORTING iv_name = 'DD02V'
                  CHANGING cg_data = ls_dd02v ).
    io_xml->read( EXPORTING iv_name = 'DD09L'
                  CHANGING cg_data = ls_dd09l ).
    io_xml->read( EXPORTING iv_name  = 'DD03P_TABLE'
                  CHANGING cg_data = lt_dd03p ).
    io_xml->read( EXPORTING iv_name = 'DD05M_TABLE'
                  CHANGING cg_data = lt_dd05m ).
    io_xml->read( EXPORTING iv_name = 'DD08V_TABLE'
                  CHANGING cg_data = lt_dd08v ).
    io_xml->read( EXPORTING iv_name = 'DD12V'
                  CHANGING cg_data = lt_dd12v ).
    io_xml->read( EXPORTING iv_name = 'DD17V'
                  CHANGING cg_data = lt_dd17v ).
    io_xml->read( EXPORTING iv_name = 'DD35V_TALE'
                  CHANGING cg_data = lt_dd35v ).
    io_xml->read( EXPORTING iv_name = 'DD36M'
                  CHANGING cg_data = lt_dd36m ).

    corr_insert( iv_package ).

    lv_name = ms_item-obj_name. " type conversion

    CALL FUNCTION 'DDIF_TABL_PUT'
      EXPORTING
        name              = lv_name
        dd02v_wa          = ls_dd02v
        dd09l_wa          = ls_dd09l
      TABLES
        dd03p_tab         = lt_dd03p
        dd05m_tab         = lt_dd05m
        dd08v_tab         = lt_dd08v
        dd35v_tab         = lt_dd35v
        dd36m_tab         = lt_dd36m
      EXCEPTIONS
        tabl_not_found    = 1
        name_inconsistent = 2
        tabl_inconsistent = 3
        put_failure       = 4
        put_refused       = 5
        OTHERS            = 6.
    IF sy-subrc <> 0.
      _raise 'error from DDIF_TABL_PUT'.
    ENDIF.

    lcl_objects_activation=>add_item( ms_item ).

* handle indexes
    LOOP AT lt_dd12v INTO ls_dd12v.

* todo, call corr_insert?

      CLEAR lt_secondary.
      LOOP AT lt_dd17v INTO ls_dd17v
          WHERE sqltab = ls_dd12v-sqltab AND indexname = ls_dd12v-indexname.
        APPEND ls_dd17v TO lt_secondary.
      ENDLOOP.

      CALL FUNCTION 'DDIF_INDX_PUT'
        EXPORTING
          name              = ls_dd12v-sqltab
          id                = ls_dd12v-indexname
          dd12v_wa          = ls_dd12v
        TABLES
          dd17v_tab         = lt_secondary
        EXCEPTIONS
          indx_not_found    = 1
          name_inconsistent = 2
          indx_inconsistent = 3
          put_failure       = 4
          put_refused       = 5
          OTHERS            = 6.
      IF sy-subrc <> 0.
        _raise 'error from DDIF_INDX_PUT'.
      ENDIF.

      CALL FUNCTION 'DD_DD_TO_E071'
        EXPORTING
          type     = 'INDX'
          name     = ls_dd12v-sqltab
          id       = ls_dd12v-indexname
        IMPORTING
          obj_name = lv_tname.

      lcl_objects_activation=>add( iv_type = 'INDX'
                                   iv_name = lv_tname ).

    ENDLOOP.

  ENDMETHOD.                    "deserialize

ENDCLASS.                    "lcl_object_TABL IMPLEMENTATION