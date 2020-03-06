/* ---------------------------------------------------------------------------------------------------------------
** Copyright DATASUL S.A. (1997)                                                                                **
** Todos os Direitos Reservados.                                                                                **
**                                                                                                              **
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao                                             **
** parcial ou total por qualquer meio, so podera ser feita mediante                                             **
** autorizacao expressa.                                                                                        **
----------------------------------------------------------------------------------------------------------------*/
{include/i-prgvrs.i CPC/CPC-FP0711B-1.P 2.00.00.001}  /*** 010001 ***/
{fpp/log.i}
/****************************************************************************************************************
*   Programa .....: cpc-fp0711b-1.p                                                                             *
*   Data .........: 04/04/2008                                                                                  *
*   Sistema ......: CPC                                                                                         *
*   Empresa ......: DZSET SOLUCOES E SISTEMAS                                                                   *
*   Cliente ......: Cooperativas Medicas                                                                        *
*   Programador ..: Ezequiel Gandolfi                                                                           *
*   Objetivo .....: CPC desenvolvida para atender a Johnson & Johnson - Regras espeicificas da JnJ.             *
*                   PROCESSO PARA CRIACAO DO EVENTO 432 JOHNSON                                                 *
*                   CRIA O EVENTO 427 PARA ZERAR O TOTAL DO TERMO                                               *
*   --------------------------------------------------------------------------------------------------------    *
*   VERSAO      DATA        RESPONSAVEL         DESCRICAO                                                       *
*   2.00.00.000 04/04/2008  Ezequiel Gandolfi   Desenvolvimento                                                 *
*   2.00.00.001 26/03/2018  Denis Kazuo         Ch.48132 - NÆo cobrar a taxa de 20% sobre o insumo 60033487,    *
*                                               independente do c¢digo do tipo de insumo                        *
****************************************************************************************************************/

/* ----------------------------------------------------------------------------------- TABELAS TEMPORARIAS ----*/
{cpc/cpc-fp0711b-1.i}


define stream s-out.
output STREAM s-out TO "c:\gps\spool\cpc-fp-0711b-1.txt" .


define temp-table wk-evento
    field cd-evento         like evenfatu.cd-evento
    field lg-cred-deb       like evenfatu.lg-cred-deb
    field qt-evento         like fatueven.qt-evento
    field vl-evento         like fatueven.vl-evento
    field lg-destacado      like evenfatu.lg-destacado
    field lg-modulo         like evenfatu.lg-modulo
    field ct-codigo         like fatueven.ct-codigo
    field sc-codigo         like fatueven.sc-codigo.

define temp-table w-fateveco    no-undo     like fateveco.
define temp-table w-fateve      no-undo     like fatueven.
/* ------------------------------------------------------------------------------------------------------------*/


/* --------------------------------------------------------------------------------- VARIAVEIS AUXILIARES ---- */
define variable c-versao                        as character                                        no-undo.
define variable vl-total-notaserv               as decimal                                          no-undo.
define variable vl-adimplentes-aux              as decimal                                          no-undo.
define variable lg-simula-aux                   as logical                                          no-undo.
define variable vl-desc-mes-aux                 as decimal                                          no-undo.
define variable lg-erro-aux                     as logical                                          no-undo.

define variable lg-ct-contabil-aux              as logical                                          no-undo.
define variable ct-codigo-aux                   like tipleven-ct.ct-codigo                          no-undo.
define variable sc-codigo-aux                   like tipleven-ct.sc-codigo                          no-undo.
define variable ct-codigo-dif-aux               like tipleven-ct.ct-codigo-diferenca                no-undo.
define variable sc-codigo-dif-aux               like tipleven-ct.sc-codigo-diferenca                no-undo.
define variable ct-codigo-dif-neg-aux           like tipleven-ct.ct-codigo-diferenca                no-undo.
define variable sc-codigo-dif-neg-aux           like tipleven-ct.sc-codigo-diferenca                no-undo.
define variable ct-codigo-glosa-aux             like fatura.ct-codigo                               no-undo.
define variable sc-codigo-glosa-aux             like fatura.sc-codigo                               no-undo.
define variable lg-evencontde-aux               as logical                                          no-undo.
define variable vl-evento-aux                   like fatueven.vl-evento                             no-undo.
define variable vl-evento-ant-aux               like fatueven.vl-evento                             no-undo.
define variable r-propost                       as rowid                                            no-undo.
define variable lg-possui-regra                 as logical                                          no-undo.
/* ------------------------------------------------------------------------------------------------------------*/

/* ---------------------------------------------------------------------------------------------- BUFFERS ---- */
define buffer b-w-fateve    for w-fateve.
define buffer b-propost     for propost.
define buffer b2-propost    for propost.
/* ------------------------------------------------------------------------------------------------------------*/


/* ----------------------------------------------------------------------------------- INICIO DO PROCESSO ---- */
assign  c-versao    =   c_prg_vrs.

{hdp/hdlog.i}  /* INCLUDE NECESSARIA PARA LOGS DO SISTEMA - NAO RETIRAR */

find first paramecp no-lock no-error.
find first parafatu no-lock no-error.

define input  parameter TABLE for tmp-cpc-fp0711b-1-entrada.
define output parameter TABLE for tmp-cpc-fp0711b-1-saida.

define input-output parameter TABLE for w-fateve.
define input-output parameter TABLE for w-fateveco.

find first tmp-cpc-fp0711b-1-entrada no-lock no-error.
if not available tmp-cpc-fp0711b-1-entrada then return.

/* ----------------------------------------------- TRATA PERDA DEDUTIVEL --- */
if tmp-cpc-fp0711b-1-entrada.nm-ponto-chamada-cpc = "ANTES-GERA-NOTA" then
do:
    if tmp-cpc-fp0711b-1-entrada.in-evento-programa = "CONSULTA" then
    do:
        find first w-fateve no-lock no-error.
        if not available w-fateve then return.
        
        log-manager:write-message (substitute ('casali -> cpc-fp0711b-1 -> w-fateves' ),'DEBUG') no-error.
        LogWriteAllTableLine(temp-table w-fateve:handle).
        
        if index(program-name(7),"fp0610a") > 0 then        assign  lg-simula-aux = yes.
        else                                                assign  lg-simula-aux = no.

        run evento-432. /* PROCESSO PARA CRIACAO DO EVENTO 432 JOHNSON */
        
        find propost where propost.cd-modalidade = w-fateve.cd-modalidade
                       and propost.nr-ter-adesao = w-fateve.nr-ter-adesao no-lock no-error.
        if not available propost then next.

        if propost.cd-modalidade <> 30 and propost.cd-modalidade <> 31 then return.

        find contrat where contrat.nr-insc-contratante = propost.nr-insc-contratante no-lock no-error.
        if not available contrat then return.

        assign  vl-total-notaserv = 0.
                                                                                                                     
        for each b-w-fateve where b-w-fateve.cd-modalidade         = w-fateve.cd-modalidade
                              and b-w-fateve.cd-contratante        = w-fateve.cd-contratante
                              and b-w-fateve.cd-contratante-origem = w-fateve.cd-contratante-origem
                              and b-w-fateve.nr-ter-adesao         = w-fateve.nr-ter-adesao
                              and b-w-fateve.aa-referencia         = w-fateve.aa-referencia
                              and b-w-fateve.mm-referencia         = w-fateve.mm-referencia     exclusive-lock:   
                                                  

            if b-w-fateve.lg-cred-deb then  assign vl-total-notaserv = vl-total-notaserv + b-w-fateve.vl-evento.
            else                            assign vl-total-notaserv = vl-total-notaserv - b-w-fateve.vl-evento.
        end.

        run localiza-total-adimplentes (output vl-adimplentes-aux).
        
        /* CASO O VALOR DE ADIMPLENTES */
        if vl-adimplentes-aux >= vl-total-notaserv then  
        do:
            /* CRIA O EVENTO 427 PARA ZERAR O TOTAL DO TERMO */
            assign vl-desc-mes-aux = vl-total-notaserv.

            if vl-desc-mes-aux <> 0 then
            do:
                /* ---- cria evento mensalidade ---- */  
                run grava-evento (input vl-desc-mes-aux,
                                  input 0,
                                  input 0,
                                  output lg-erro-aux).

                if lg-erro-aux then
                    undo, return.
            end.
            else
                return.


            run atualiza-tabela (input vl-desc-mes-aux,
                                 input yes).            

            create  tmp-cpc-fp0711b-1-saida.
                    tmp-cpc-fp0711b-1-saida.vl-evento = 0.
        end.
        else
        do:
            assign vl-desc-mes-aux = vl-adimplentes-aux.                        
                                                                                               
            /* ---- cria evento mensalidade ---- */                            
            run grava-evento (input vl-desc-mes-aux,
                              input 0,
                              input 0,
                              output lg-erro-aux).
            if lg-erro-aux then
                undo, return.

            assign vl-desc-mes-aux = 0.
                                                                            
            run atualiza-tabela (input vl-desc-mes-aux,
                                 input yes).

            create  tmp-cpc-fp0711b-1-saida.                   
            assign  tmp-cpc-fp0711b-1-saida.lg-undo-retry   =   no
                    tmp-cpc-fp0711b-1-saida.vl-evento       =   vl-total-notaserv - vl-adimplentes-aux. 
        end.
    end. /* EVENTO = SALDO */
end. /* PONTO */

/* --------------------------------------------------------------------------------- */
procedure grava-evento:

    define input  parameter vl-evento-mes-par   like fatueven.vl-evento     no-undo.
    define input  parameter vl-evento-cop-par   like fatueven.vl-evento     no-undo.
    define input  parameter vl-evento-res-par   like fatueven.vl-evento     no-undo.
    define output parameter lg-erro-par         as logical                  no-undo.

    if vl-evento-mes-par <> 0 then
    do:
        run busca-evento (input 427,
                          output lg-erro-par).

        if lg-erro-par then
            return.

        run grava-fatueven (input  vl-evento-mes-par,
                            output lg-erro-par).

        if lg-erro-par then
            return.
    end.
end procedure.
/* --------------------------------------------------------------------------------- */

/* --------------------------------------------------------------------------------- */
procedure busca-evento:

    define input  parameter cd-evento-par like evenfatu.cd-evento no-undo.
    define output parameter lg-erro-par   as log                  no-undo.

    find evenfatu where evenfatu.in-entidade = "FT"
                    and evenfatu.cd-evento   = cd-evento-par    no-lock no-error. 

    if not avail evenfatu then 
    do:
        create  tmp-cpc-fp0711b-1-saida.
        assign  tmp-cpc-fp0711b-1-saida.lg-undo-retry   =   yes                
                tmp-cpc-fp0711b-1-saida.ds-mensagem     =   "Evento nao cadastrado-Entid.:FT Eve.: "  + STRING(cd-evento-par).
                lg-erro-par                             =   yes.
    end.
    else 
        assign lg-erro-par = no.
end procedure.
/* --------------------------------------------------------------------------------- */

/* --------------------------------------------------------------------------------- */
procedure grava-fatueven:
    
    define input  parameter vl-evento-par      like fatueven.vl-evento no-undo.
    define output parameter lg-erro-par        as logical              no-undo.

    /* --- ACESSA TIPLEVEN --- */
    find tipleven where tipleven.cd-modalidade  = propost.cd-modalidade 
                    and tipleven.cd-plano       = propost.cd-plano
                    and tipleven.cd-tipo-plano  = propost.cd-tipo-plano
                    and tipleven.cd-FORma-pagto = propost.cd-FORma-pagto
                    and tipleven.in-entidade    = "FT"
                    and tipleven.cd-evento      = evenfatu.cd-evento
                    and tipleven.lg-ativo       = yes   no-lock no-error.

    if not available tipleven then
    do:
        create  tmp-cpc-fp0711b-1-saida.
        assign  tmp-cpc-fp0711b-1-saida.lg-undo-retry = yes                
                tmp-cpc-fp0711b-1-saida.ds-mensagem   = "Evento nao cadastrado na estrutura-Entid.:FT Eve.: " 
                                                          + STRING(evenfatu.cd-evento)   
                                                          + " Mod: "
                                                          + STRING(propost.cd-modalidade, "99")
                                                          + " Pl: "
                                                          + STRING(propost.cd-plano, "99")  
                                                          + " Tp.Pl: "
                                                          + STRING(propost.cd-tipo-plano, "99")  
                                                          + " F.Pag: "
                                                          + STRING(propost.cd-FORma-pagto)
                lg-erro-par                           = yes.

    end.
    else
    do:
        assign lg-erro-par = no.

        /* --- CRIA EVENTO NA FATUEVEN --- */
        find b-w-fateve where b-w-fateve.cd-modalidade            = w-fateve.cd-modalidade
                          and b-w-fateve.cd-contratante           = w-fateve.cd-contratante
                          and b-w-fateve.cd-contratante-origem    = w-fateve.cd-contratante-origem
                          and b-w-fateve.nr-ter-adesao            = w-fateve.nr-ter-adesao
                          and b-w-fateve.aa-referencia            = w-fateve.aa-referencia
                          and b-w-fateve.mm-referencia            = w-fateve.mm-referencia
                          and b-w-fateve.nr-sequencia             = w-fateve.nr-sequencia
                          and b-w-fateve.cd-evento                = evenfatu.cd-evento      exclusive-lock no-error.

        if not available b-w-fateve then
        do:

            create  b-w-fateve.
            assign  b-w-fateve.cd-modalidade         = w-fateve.cd-modalidade
                    b-w-fateve.nr-ter-adesao         = w-fateve.nr-ter-adesao
                    b-w-fateve.aa-referencia         = w-fateve.aa-referencia
                    b-w-fateve.mm-referencia         = w-fateve.mm-referencia
                    b-w-fateve.nr-sequencia          = w-fateve.nr-sequencia
                    b-w-fateve.cd-evento             = evenfatu.cd-evento
                    b-w-fateve.qt-evento             = 1
                    b-w-fateve.lg-cred-deb           = evenfatu.lg-cred-deb
                    b-w-fateve.lg-destacado          = evenfatu.lg-destacado
                    b-w-fateve.lg-modulo             = evenfatu.lg-modulo
                    b-w-fateve.ct-codigo             = tipleven.ct-codigo
                    b-w-fateve.sc-codigo             = tipleven.sc-codigo
                    b-w-fateve.cd-userid             = w-fateve.cd-userid
                    b-w-fateve.dt-atualizacao        = w-fateve.dt-atualizacao
                    b-w-fateve.cd-contratante        = w-fateve.cd-contratante
                    b-w-fateve.cd-contratante-origem = w-fateve.cd-contratante-origem
                    b-w-fateve.vl-evento             = vl-evento-par.
        end.
    end.
end procedure.

/* --------------------------------------------------------------------------------- */
procedure atualiza-tabela:

    define input parameter vl-residuo-par       like fatueven.vl-evento   no-undo.
    define input parameter lg-desconto-par      as logical                no-undo.

    define buffer b-exced-fat-co for exced-fat-co.

    if lg-desconto-par then 
    do:
        if propost.cd-modalidade = 31 then
        do:
            find first exced-fat-co where exced-fat-co.cd-contrat-origem    =   propost.nr-insc-contratante
                                      and exced-fat-co.competencia          =   STRING(w-fateve.mm-referencia, "99") + "/" + STRING(w-fateve.aa-referencia, "9999") 
                exclusive-lock no-error.
    
            if available exced-fat-co then 
            do:
                /* Program name - simula*/
                if vl-residuo-par = 0 then 
                do:
                    if lg-simula-aux then assign exced-fat-co.vl-excedente = 0.
                    else assign exced-fat-co.vl-saldo     = 0.
                end.
                else 
                do:
                    if lg-simula-aux then assign exced-fat-co.vl-excedente = exced-fat-co.vl-excedente - vl-residuo-par.
                    else assign exced-fat-co.vl-saldo     = exced-fat-co.vl-saldo     - vl-residuo-par.
                end.

/*                 /* MSG KAZUO */                                                          */
/*                 IF propost.nr-ter-adesao = 981 OR propost.nr-ter-adesao = 982 THEN       */
/*                 DO:                                                                      */
/*                     MESSAGE "MANUTEN€ÇO RESIDUOS-01" SKIP                                */
/*                         "TERMO                  "       propost.nr-ter-adesao       SKIP */
/*                         "Residuos SALDO         "       exced-fat-co.vl-saldo       SKIP */
/*                         "Residuos SIMULA        "       exced-fat-co.vl-excedente   SKIP */
/*                         VIEW-AS ALERT-BOX INFO BUTTONS OK.                               */
/*                 END.                                                                     */
            end.
        end.
        else
        do:
            find first exced-fat-co where exced-fat-co.cd-contrat-origem    =   propost.nr-insc-contrat-orig
                                      and exced-fat-co.competencia          =   STRING(w-fateve.mm-referencia, "99") + "/" + STRING(w-fateve.aa-referencia, "9999") 
                exclusive-lock no-error.
    
            if available exced-fat-co then 
            do:
                /* Program name - simula*/
                if vl-residuo-par = 0 then 
                do:
                    if lg-simula-aux then assign exced-fat-co.vl-excedente = 0.
                    else assign exced-fat-co.vl-saldo     = 0.
                end.
                else 
                do:
                    if lg-simula-aux then assign exced-fat-co.vl-excedente = exced-fat-co.vl-excedente - vl-residuo-par.
                    else assign exced-fat-co.vl-saldo     = exced-fat-co.vl-saldo     - vl-residuo-par.
                end.
/*                 /* MSG KAZUO */                                                          */
/*                 IF propost.nr-ter-adesao = 981 OR propost.nr-ter-adesao = 982 THEN       */
/*                 DO:                                                                      */
/*                     MESSAGE "MANUTEN€ÇO RESIDUOS-02" SKIP                                */
/*                         "TERMO                  "       propost.nr-ter-adesao       SKIP */
/*                         "Residuos SALDO         "       exced-fat-co.vl-saldo       SKIP */
/*                         "Residuos SIMULA        "       exced-fat-co.vl-excedente   SKIP */
/*                         VIEW-AS ALERT-BOX INFO BUTTONS OK.                               */
/*                 END.                                                                     */
            end.
        end.
    end.
end procedure.
/* --------------------------------------------------------------------------------- */

/* --------------------------------------------------------------------------------- */
procedure localiza-total-adimplentes:

    def output parameter vl-adimplentes-par as dec no-undo.

    if propost.cd-modalidade = 31 then
    do:
        for each exced-fat-co where exced-fat-co.cd-contrat-origem =  propost.nr-insc-contratante                                                      
                                and exced-fat-co.competencia       = STRING(w-fateve.mm-referencia, "99") + "/" + STRING(w-fateve.aa-referencia, "9999")    no-lock:

            if lg-simula-aux  then 
                assign vl-adimplentes-par = vl-adimplentes-par + exced-fat-co.vl-excedente.
            else 
                assign vl-adimplentes-par = vl-adimplentes-par + exced-fat-co.vl-saldo.
        end.
    end.
    else
    do:
        for each exced-fat-co where exced-fat-co.cd-contrat-origem =  propost.nr-insc-contrat-orig                                                      
                                and exced-fat-co.competencia       = STRING(w-fateve.mm-referencia, "99") + "/" + STRING(w-fateve.aa-referencia, "9999")    no-lock:

            if lg-simula-aux  then 
                assign vl-adimplentes-par = vl-adimplentes-par + exced-fat-co.vl-excedente.
            else 
                assign vl-adimplentes-par = vl-adimplentes-par + exced-fat-co.vl-saldo.
        end.
    end.
end procedure.

procedure evento-432:

    /* Leitura da temporaria da tabela Fateveco */
    for each w-fateveco no-lock:


        log-manager:write-message (substitute ('casali -> cpc-fp0711b-1 -> cd-evento: &1', w-fateveco.cd-evento ), 'DEBUG') no-error.
        if w-fateveco.cd-evento = 430 then next.

        /* Leitura Proposta */
        find first propost where propost.cd-modalidade     = w-fateveco.cd-modalidade 
                             and propost.nr-ter-adesao     = w-fateveco.nr-ter-adesao no-lock no-error.

        if avail propost then
        do:
            assign r-propost = rowid(propost). /* Grava rowid propost para posterior utilizacao */

            if propost.cd-modalidade = 45 and propost.cd-plano = 15 and (propost.cd-tipo-plano = 1 or propost.cd-tipo-plano = 2) /* Estruturas Johnson*/  then
            do:
                log-manager:write-message (substitute ('casali -> cpc-fp0711b-1 -> leitura mov-insu' ),'DEBUG') no-error.
                /* LEITURA mov-insu */
                find first mov-insu where  mov-insu.cd-unidade              =  w-fateveco.cd-unidade
                                      and  mov-insu.cd-unidade-prestadora   =  w-fateveco.cd-unidade-prestad
                                      and  mov-insu.cd-transacao            =  w-fateveco.cd-transacao
                                      and  mov-insu.nr-serie-doc-original   =  w-fateveco.nr-serie-doc-original
                                      and  mov-insu.nr-doc-original         =  w-fateveco.nr-doc-original
                                      and  mov-insu.nr-doc-sistema          =  w-fateveco.nr-doc-sistema
                                      and  mov-insu.nr-processo             =  w-fateveco.nr-processo
                                      and  mov-insu.nr-seq-digitacao        =  w-fateveco.nr-seq-digitacao no-lock no-error.

                if avail mov-insu then
                do:
                    /* Desconsidera Insumo Tipo 60 quando unidade prestadora = 4 */
                    if mov-insu.cd-tipo-insumo = 60   and mov-insu.cd-unidade-prestadora = paramecp.cd-unimed then next.
                    if mov-insu.cd-insumo = 60033487  then next. /* 26/03/2018 - GLPI 48132 - NÇO cobrar a taxa de 20% sobre o insumo 60033487, INDEPENDENTE do tipo de insumo. */

                    /*Considera Insumos realizados a partir de 01/07/2015*/
                    if mov-insu.dt-realizacao < 07/01/2015 then next.

                end. /* MOV-INSU */
log-manager:write-message (substitute ('casali -> cpc-fp0711b-1 -> leitura moviproc' ),'DEBUG') no-error.
                /* Leitura moviproc */
                find first moviproc where moviproc.cd-unidade              =  w-fateveco.cd-unidade
                                      and moviproc.cd-unidade-prestadora   =  w-fateveco.cd-unidade-prestad
                                      and moviproc.cd-transacao            =  w-fateveco.cd-transacao
                                      and moviproc.nr-serie-doc-original   =  w-fateveco.nr-serie-doc-original
                                      and moviproc.nr-doc-original         =  w-fateveco.nr-doc-original
                                      and moviproc.nr-doc-sistema          =  w-fateveco.nr-doc-sistema
                                      and moviproc.nr-processo             =  w-fateveco.nr-processo
                                      and moviproc.nr-seq-digitacao        =  w-fateveco.nr-seq-digitacao no-lock no-error.

                if avail moviproc then 
                do:
                    /* Desconsidera consulta quando unidade prestadora = 4 */
                    if  moviproc.cd-esp-amb         = 10  and moviproc.cd-grupo-proc-amb = 10  and 
                        moviproc.cd-procedimento    = 101 and moviproc.dv-procedimento   = 2   and 
                        moviproc.cd-unidade-prestadora = paramecp.cd-unimed then next.

                    /* Desconsidera consulta de emergencia quando unidade prestadora = 4 e prestadores executantes 300026,300043,300057 e 600174 */                  
                    if  moviproc.cd-esp-amb            = 10     and moviproc.cd-grupo-proc-amb     = 10 and 
                        moviproc.cd-procedimento       = 103    and moviproc.dv-procedimento       = 9  and 
                        moviproc.cd-unidade-prestadora = paramecp.cd-unimed and 
                        (moviproc.cd-prestador  = 300026 or moviproc.cd-prestador   = 300043    or 
                         moviproc.cd-prestador  = 300057 or moviproc.cd-prestador   = 600174)   then next.
                                                                                                                                                                        
                    /*Considera Procedimentos realizados a partir de 01/07/2015*/
                    if moviproc.dt-realizacao < 07/01/2015 then next.
                end. /* MOVIPROC */

/*                 IF w-fateveco.nr-doc-original = 2863116 THEN                 */
/*                 DO:                                                          */
/*                     MESSAGE                                                  */
/*                         vl-evento-ant-aux                               SKIP */
/*                         w-fateveco.vl-evento                            SKIP */
/*                         vl-evento-aux                                   SKIP */
/*                         lg-possui-regra                                      */
/*                         VIEW-AS ALERT-BOX INFO BUTTONS OK.                   */
/*                 END.                                                         */

                /* Acumula Valores para Tabelas Fatueven e Fateveco*/
                log-manager:write-message (substitute ('casali -> cpc-fp0711b-1 -> vl-evento: &1',  w-fateveco.vl-evento),'DEBUG') no-error.                                                                                               
                assign  vl-evento-ant-aux     = w-fateveco.vl-evento                                                                                                 
                        w-fateveco.vl-evento  = w-fateveco.vl-evento + (w-fateveco.vl-evento - ((w-fateveco.vl-evento * 80) / 100)) /* cria valor da taxa 20% tabela */
                        vl-evento-aux         = vl-evento-aux + (w-fateveco.vl-evento - vl-evento-ant-aux). /* cria valor da taxa 20% tabela fatueven*/              
                        lg-possui-regra       = yes.  

                export stream s-out delimiter ";"
                    propost.cd-modalidade
                    propost.nr-ter-adesao
                    vl-evento-ant-aux   
                    w-fateveco.vl-evento
                    vl-evento-aux       
                    lg-possui-regra   
                    w-fateveco.cd-evento
                    w-fateveco.vl-evento
                    w-fateveco.cd-contratante
                    w-fateveco.cd-contratante-origem
                    w-fateveco.cd-unidade           
                    w-fateveco.cd-unidade-prestador 
                    w-fateveco.cd-transacao         
                    w-fateveco.nr-serie-doc-original
                    w-fateveco.nr-doc-original      
                    w-fateveco.nr-doc-sistema       
                    w-fateveco.nr-processo          
                    w-fateveco.nr-seq-digitacao.  



            end. /* ESTRUTURA JHONSON */
            else next. /* Desconsidera registros que nao pertencem a ESTRUTURA JHONSON*/                                                                               
        end. /* PROPOST*/
    end. /* W-FATEVECO*/
    if lg-possui-regra then run cria-saida. /* Se possui regra cria saida com valores*/
end.

procedure cria-saida:

    /*Leitura Proposta*/
    find b-propost where rowid(b-propost) = r-propost no-lock no-error.
    if avail b-propost then 
    do:   
        /*Leitura Evento X Plano para o Evento 432*/
        find first tipleven where tipleven.cd-modalidade      = propost.cd-modalidade
                              and tipleven.cd-plano           = propost.cd-plano
                              and tipleven.cd-tipo-plano      = propost.cd-tipo-plano
                              and tipleven.cd-FORma-pagto     = propost.cd-forma-pagto
                              and tipleven.in-entidade        = "FT"
                              and tipleven.cd-evento          = 432
                              and tipleven.lg-ativo           = yes     no-lock no-error.

        if available tipleven then 
        do:
            /* -----Busca da CONTA CONTABIL --- */
            run rtp/rtct-contabeis.p(input  tipleven.cd-modalidade,
                                     input  tipleven.cd-plano,
                                     input  tipleven.cd-tipo-plano,
                                     input  tipleven.cd-FORma-pagto,
                                     input  "FT",
                                     input  tipleven.cd-evento,
                                     input  tipleven.cd-modulo,
                                     input  year(today),
                                     input  month(today),
                                     input  0,
                                     input  "",
                                     input  ?,
                                     input  b-propost.in-tipo-contratacao,
                                     input  0,
                                     output lg-ct-contabil-aux, 
                                     output ct-codigo-aux,
                                     output sc-codigo-aux,
                                     output ct-codigo-dif-aux,
                                     output sc-codigo-dif-aux,
                                     output ct-codigo-dif-neg-aux,
                                     output sc-codigo-dif-neg-aux,
                                     output ct-codigo-glosa-aux,
                                     output sc-codigo-glosa-aux,
                                     output lg-evencontde-aux).

            if not lg-ct-contabil-aux then 
            do:
                /* Se nao achar conta gera erro*/
                create  tmp-cpc-fp0711b-1-saida.                                                                           
                assign  tmp-cpc-fp0711b-1-saida.lg-undo-retry   =   yes                               
                    tmp-cpc-fp0711b-1-saida.ds-mensagem         =   "Conta Contabil nao cadastrada para o Evento"  + STRING(tipleven.cd-evento). 
                return.
            end.
            else 
            do:
                find first w-fateve where w-fateve.cd-modalidade          = propost.cd-modalidade
                                      and w-fateve.nr-ter-adesao          = propost.nr-ter-adesao   no-lock no-error.

                if avail w-fateve then 
                do:
                    /* Cria registro da tabela fatueven com o evento 432 e valor de saida da tabela notaserv*/
                    create  b-w-fateve.
                    buffer-copy w-fateve except w-fateve.cd-evento
                                                w-fateve.vl-evento
                                                w-fateve.qt-evento
                                                w-fateve.qt-evento-ref
                                                w-fateve.vl-evento-ref
                                                w-fateve.ct-codigo
                                                w-fateve.sc-codigo 
                                                w-fateve.ct-codigo-diferenca
                                                w-fateve.sc-codigo-diferenca
                                                w-fateve.char-1             
                                                w-fateve.char-2 to b-w-fateve.

                    assign  b-w-fateve.cd-evento     = 432
                            b-w-fateve.vl-evento     = vl-evento-aux
                            b-w-fateve.qt-evento     = 0
                            b-w-fateve.qt-evento-ref = 0
                            b-w-fateve.vl-evento-ref = 0
                            b-w-fateve.ct-codigo     = ct-codigo-aux  
                            b-w-fateve.sc-codigo     = sc-codigo-aux.
                             
                    if parafatu.lg-contabiliza-diferenca then 
                        assign  b-w-fateve.ct-codigo-diferenca   = ct-codigo-dif-aux
                                b-w-fateve.sc-codigo-diferenca   = sc-codigo-dif-aux
                                b-w-fateve.char-1                = ct-codigo-dif-neg-aux
                                b-w-fateve.char-2                = sc-codigo-dif-neg-aux.

                    create  tmp-cpc-fp0711b-1-saida.
                    assign  tmp-cpc-fp0711b-1-saida.vl-evento     = tmp-cpc-fp0711b-1-entrada.vl-evento + vl-evento-aux
                            tmp-cpc-fp0711b-1-saida.lg-undo-retry = no.
                end. /*w-fateve*/  
            end. /* else lg-ct-contabil-aux*/
        end. /* tipleven*/
    end. /*b-propost*/
end procedure. /* Final da procedure cria saida*/

/* --------------------------------------------------------------------------EOF --- */

