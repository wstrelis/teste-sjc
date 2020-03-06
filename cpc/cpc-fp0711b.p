/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i CPC/CPC-FP0711B.P 9.00.001}  /*** 010011 ***/


&IF "{&EMSFND_VERSION}" >= "9.00.001" &THEN
{include/i-license-manager.i cpc-fp0711b MCP}
&ENDIF

/****************************************************************************************************************
*   Programa .....: cpc-fp0711b.p                                                                               *
*   Data .........: 20/05/2003                                                                                  *
*   Sistema ......: CPC                                                                                         *
*   Empresa ......: DZSET SOLUCOES E SISTEMAS                                                                   *
*   Cliente ......: Cooperativas Medicas                                                                        *
*   Programador ..: LUCIANO                                                                                     *
*   Objetivo .....: CPC desenvolvida para atender a Johnson & Johnson - Cobrar o mesmo valor do Pagamento.      *
*-----------------------------------------------------------------------------*                                 *
*   VERSAO      DATA         RESPONSAVEL    DESCRICAO                                                           *
*   6.00.000    20/05/2003  Luciano         Desenvolvimento                                                     *
*   7.00.000    01/10/2010  Celso Tabuchi   Atualizacao TUSS                                                    *
*   8.00.000    18/07/2013  Celso Tabuchi   Alterado informacao inserida na saida do fp0711b porque o vlr estava*
                                            vindo com taxa 5%. Erro ?? Unmd 280 FO THOTL8 18/07/2013            *
*   9.00.000    21/08/2013  Celso Tabuchi   Acrescentado regra para pegar valor pago caso movimento seja da JNJ *
                                            de acordo com as condicoes das linhas de comando                    *
                                            Chamado 6486 21/06/2013 Vera                                        *
*   9.00.001    08/11/2013  Andrea Caetano  Ajuste campo aux pois alguns movimentos nao estavam sendo cobrados  *
*   9.00.003    26/11/2013  Celso Tabuchi   Chamado 11905 para forçar o vlr real glosado para os prestadores    *
*                                           300010 e 300011 somente cd-tipo-pagamento = 1 cd-tipo-cob = 0       *
*   9.00.004    13/05/2016  Vanessa Loschi  Alterado devido ao rateio no producao, nao usar o valor Real Pago   *
*                                           para os Recursos Pr¢prios no caso da Johnson.                       *
*   2.00.00.001 26/03/2018  Denis Kazuo     InclusÆo da modalidade 31                                           *
****************************************************************************************************************/

/* --------------------------------------------------------------------------- DEFINICAO DAS TEMPORARIAS ----  */
{cpc/cpc-fp0711b.i}

/* ---------------------------------------------------------------------- API/VARIAVEIS P/ GERAR EM EXCEL ---- */
/* --------------------------------------------------------------------------------- VARIAVEIS AUXILIARES ---- */
define variable c-versao                        as character                                        no-undo.
define variable h-rtapi-excel-aux               as handle                                           no-undo.
define variable nr-linha-aux                    as integer initial 1                                no-undo.
define variable nr-coluna-aux                   as integer initial 0                                no-undo.                 
define variable vl-total-taxa-aux               as decimal format ">>,>>>,>>9.99"                   no-undo.
define variable vl-total-aux                    as decimal format ">>,>>>,>>9.99"                   no-undo.
define variable nr-linhas-aux                   as integer                                          no-undo.
define variable lg-tipo-aplicacao-aux           as logical                                          no-undo.
define variable pc-aplicacao-aux                like acrdespr.pc-aplicacao                          no-undo.
define variable cd-amb-auxiliar                 as integer format "99999999"                        no-undo.
define variable nr-rowid-proposta-aux           as rowid                                            no-undo.
define variable nr-rowid-unicamco-aux           as rowid                                            no-undo.
define variable cd-modalidade0aux               like propost.cd-modalidade                          no-undo.
define variable lg-existe-base-aux              as logical initial yes                              no-undo.
define variable cd-grupo-proc-aux               like moviproc.cd-grupo-proc-amb                     no-undo.
define variable cd-esp-amb-aux                  like ambproce.cd-esp-amb                            no-undo.
define variable cd-grupo-proc-amb-aux           like ambproce.cd-grupo-proc-amb                     no-undo.
define variable cd-procedimento-amb-aux         like ambproce.cd-procedimento                       no-undo.
define variable dv-procedimento-amb-aux         like ambproce.dv-procedimento                       no-undo.
define variable lg-achou-regra-pc-aux           as logical init no                                  no-undo.
define variable cd-proc-aux                     as integer format "99999999"                        no-undo. 
define variable vl-proc-maior-valor-aux         like moviproc.vl-cobrado                            no-undo.
define variable r-proc-maior-valor-aux          as rowid                                            no-undo.

define buffer b-moviproc                        for moviproc.
define buffer b2-moviproc                       for moviproc.

/* ----------------------------------------------------------------------------------- INICIO DO PROCESSO ---- */
assign  c-versao    =   "2.00.00.001".
{hdp/hdlog.i}  /* -.Include necessario para logïs do Sistema nao retirar --- */

/* ---------------------------------------------------------------------------------------------------------- */ 
define input  parameter TABLE for tmp-cpc-fp0711b-entrada.
define input-output parameter table for tmp-cpc-fp0711b-contrat.
define output parameter TABLE for tmp-cpc-fp0711b-saida.

find first tmp-cpc-fp0711b-entrada no-lock no-error.

find first paramecp no-lock no-error.
if not available paramecp then return.

case tmp-cpc-fp0711b-entrada.nm-ponto-chamada-cpc:

    when "APOSVALORIZAPRO" then
    do:
        find moviproc where rowid(moviproc) = tmp-cpc-fp0711b-entrada.nr-rowid-movimento no-lock no-error.
        if not avail moviproc then return.

        assign  cd-proc-aux     =   INT(string(moviproc.cd-esp-amb,"99")        +     
                                        STRING(moviproc.cd-grupo-proc-amb,"99") +     
                                        STRING(moviproc.cd-procedimento,"999")  +     
                                        STRING(moviproc.dv-procedimento,"9")).

        find propost where propost.cd-modalidade = moviproc.cd-modalidade
                       and propost.nr-ter-adesao = moviproc.nr-ter-adesao no-lock no-error.

        if not avail propost then return.

        find docrecon where docrecon.cd-unidade             = moviproc.cd-unidade
                        and docrecon.cd-unidade-prestadora  = moviproc.cd-unidade-prestadora
                        and docrecon.cd-transacao           = moviproc.cd-transacao
                        and docrecon.nr-serie-doc-original  = moviproc.nr-serie-doc-original
                        and docrecon.nr-doc-original        = moviproc.nr-doc-original
                        and docrecon.nr-doc-sistema         = moviproc.nr-doc-sistema           no-lock no-error.

        if not available docrecon then return.

        /* Atualizacao 9.00.001 */
        /* Pega os registros da JNJ com prestadores especificos, cobranca normal e desconsiderar pagamento */
        /* 26/03/2018 - 2.00.00.001 - InclusÆo da modalidade 31 */
        if (propost.cd-modalidade = 30 or propost.cd-modalidade = 45 or propost.cd-modalidade = 31)     and
            propost.cd-plano      = 15                                                                  and
            moviproc.cd-unidade-pagamento   = 4                                                         and 
           (moviproc.cd-prestador-pagamento = 300010    or moviproc.cd-prestador-pagamento = 300011)    and
            moviproc.cd-tipo-pagamento      = 1                                                         and                                                        
            moviproc.cd-tipo-cob            = 0                                                         then
        do:

            create  tmp-cpc-fp0711b-saida.
            assign  tmp-cpc-fp0711b-saida.lg-undo-retry  = no
                    tmp-cpc-fp0711b-saida.vl-calculo-aux = moviproc.vl-cobrado.
            
        end.
        else
        do: 
            find first par-contr where par-contr.cd-modalidade = moviproc.cd-modalidade         
                                   and par-contr.nr-ter-adesao = moviproc.nr-ter-adesao     no-lock no-error.

            if available par-contr and par-contr.lg-fatura then 
            do:  
                if  (moviproc.cd-esp-amb = 00 and moviproc.cd-grupo-proc-amb = 01 and moviproc.cd-procedimento = 001 and moviproc.dv-procedimento = 4 and moviproc.cd-unidade-prestador = 4) or
                    (moviproc.cd-esp-amb = 10 and moviproc.cd-grupo-proc-amb = 10 and moviproc.cd-procedimento = 101 and moviproc.dv-procedimento = 2 and moviproc.cd-unidade-prestador = 4) or      /* Atualizacao E.07.000 */
                    (moviproc.cd-esp-amb = 10 and moviproc.cd-grupo-proc-amb = 10 and moviproc.cd-procedimento = 603 and moviproc.dv-procedimento = 0 and moviproc.cd-unidade-prestador = 4) then    /* Atualizacao E.07.000 */
                do:
                    /*RUN verifica-rateio.*/
                    return.  /* Consulta e unidade 4 desconsidera a regra */  
                end.

                if  (moviproc.cd-esp-amb = 00 and moviproc.cd-grupo-proc-amb = 01 and moviproc.cd-procedimento = 011 and moviproc.dv-procedimento = 1 and moviproc.cd-unidade-prestador = 4) or  
                    (moviproc.cd-esp-amb = 10 and moviproc.cd-grupo-proc-amb = 10 and moviproc.cd-procedimento = 201 and moviproc.dv-procedimento = 9 and moviproc.cd-unidade-prestador = 4) then  /* Atualizacao E.07.000 */
                do:
                    if docrecon.cd-unidade-principal = 4 and (docrecon.cd-prestador-principal = 300026 or docrecon.cd-prestador-principal = 300047) then
                    do:
                        /*RUN verifica-rateio.*/
                        return. /* Desconsidera a regra e segue a parametrizacao do sistema */
                    end.
                end.

                /* Se encontrar algum registro no menu RC/03/P das estruturas 30/15/1 - 30/15/2 - 45/15/1 - 45/15/2,
                   NÇO considerar a regra espec¡fica de pagamento=cobran‡a, mas sim prevalecer o que estiver parametrizado neste menu. */
                /* 26/03/2018 - 2.00.00.001 - InclusÆo da modalidade 31 */
                if  (propost.cd-modalidade = 30 or propost.cd-modalidade = 45 or propost.cd-modalidade = 31) and propost.cd-plano = 15 and 
                    (propost.cd-tipo-plano = 1  or propost.cd-tipo-plano = 2) then 
                do:
                    run p-acha-moeda (output lg-achou-regra-pc-aux).

                    if lg-achou-regra-pc-aux then return.
                end.
                
                /* Rateio nos cooperados e RPs*/
                /* 26/03/2018 - 2.00.00.001 - InclusÆo da modalidade 31 */
                if  (propost.cd-modalidade = 30 or propost.cd-modalidade = 31 or propost.cd-modalidade = 45) and propost.cd-plano = 15 and 
                    (propost.cd-tipo-plano = 1  or propost.cd-tipo-plano = 2)                            and
                     moviproc.vl-rateio    > 0                                                           then
                do:
                  if moviproc.vl-cobrado < (moviproc.vl-principal + moviproc.vl-auxiliar) then 
                  do:
                    create  tmp-cpc-fp0711b-saida.
                    assign  tmp-cpc-fp0711b-saida.lg-undo-retry  = no
                            tmp-cpc-fp0711b-saida.vl-calculo-aux = (moviproc.vl-cobrado - moviproc.vl-taxa-out-uni-auxi - moviproc.vl-taxa-out-uni-prin).
                  end.
                  else
                  do:
                    create  tmp-cpc-fp0711b-saida.
                    assign  tmp-cpc-fp0711b-saida.lg-undo-retry  = no
                            tmp-cpc-fp0711b-saida.vl-calculo-aux = (moviproc.vl-principal + moviproc.vl-auxiliar - moviproc.vl-taxa-out-uni-auxi - moviproc.vl-taxa-out-uni-prin).
                  end.
                end.                
                else
                do:
                   create  tmp-cpc-fp0711b-saida.
                   assign  tmp-cpc-fp0711b-saida.lg-undo-retry  = no
                           tmp-cpc-fp0711b-saida.vl-calculo-aux = (moviproc.vl-real-pago - moviproc.vl-taxa-out-uni-auxi - moviproc.vl-taxa-out-uni-prin).
                end.
                
                run localiza-filme.
                return.
            end.
    
            find first par-contr where par-contr.cd-modalidade = moviproc.cd-modalidade          
                                   and par-contr.cd-plano      = propost.cd-plano                
                                   and par-contr.tp-plano      = propost.cd-tipo-plano  no-lock no-error. 

            if available par-contr and par-contr.lg-fatura then
            do:
                if  (moviproc.cd-esp-amb = 00 and moviproc.cd-grupo-proc-amb = 01 and moviproc.cd-procedimento = 001 and moviproc.dv-procedimento = 4 and moviproc.cd-unidade-prestador = 4) or
                    (moviproc.cd-esp-amb = 10 and moviproc.cd-grupo-proc-amb = 10 and moviproc.cd-procedimento = 101 and moviproc.dv-procedimento = 2 and moviproc.cd-unidade-prestador = 4) or      /* Atualizacao E.07.000 */
                    (moviproc.cd-esp-amb = 10 and moviproc.cd-grupo-proc-amb = 10 and moviproc.cd-procedimento = 603 and moviproc.dv-procedimento = 0 and moviproc.cd-unidade-prestador = 4) then    /* Atualizacao E.07.000 */
                do: 
                    /*RUN verifica-rateio.*/
                    return.  /* Conbsulta e unidade 4 desoncidera a regra */
                end.

                if  (moviproc.cd-esp-amb = 00 and moviproc.cd-grupo-proc-amb = 01 and moviproc.cd-procedimento = 011 and moviproc.dv-procedimento = 1 and moviproc.cd-unidade-prestador = 4) or
                    (moviproc.cd-esp-amb = 10 and moviproc.cd-grupo-proc-amb = 10 and moviproc.cd-procedimento = 201 and moviproc.dv-procedimento = 9 and moviproc.cd-unidade-prestador = 4) then      /* Atualizacao E.07.000 */
                do:
                    if docrecon.cd-unidade-principal   = 4 and (docrecon.cd-prestador-principal = 300026 or docrecon.cd-prestador-principal = 300047) then
                    do:
                        /*RUN verifica-rateio.*/
                        return. /*Desconsidera a regra e segue a parametrizacao do sistema */
                    end.
                end.

                /* Se encontrar algum registro no menu RC/03/P das estruturas 30/15/1 - 30/15/2 - 45/15/1 - 45/15/2,
                   NÇO considerar a regra espec¡fica de pagamento=cobran‡a, mas sim prevalecer o que estiver parametrizado neste menu. */
                /* 26/03/2018 - 2.00.00.001 - InclusÆo da modalidade 31 */
                if  (propost.cd-modalidade = 30 or propost.cd-modalidade = 31 or propost.cd-modalidade = 45) and propost.cd-plano = 15 and 
                    (propost.cd-tipo-plano = 1 or propost.cd-tipo-plano = 2) then
                do:
                    run p-acha-moeda (output lg-achou-regra-pc-aux).

                    
                    if lg-achou-regra-pc-aux then return.


                end.

                /*Rateio nos cooperados e RPs*/
                /* 26/03/2018 - 2.00.00.001 - InclusÆo da modalidade 31 */
                if  (propost.cd-modalidade = 30 or propost.cd-modalidade = 31 or propost.cd-modalidade = 45) and propost.cd-plano = 15 and 
                    (propost.cd-tipo-plano = 1  or propost.cd-tipo-plano = 2)                            and
                     moviproc.vl-rateio    > 0                                                           then
                do:
                  if moviproc.vl-cobrado < (moviproc.vl-principal + moviproc.vl-auxiliar) then 
                  do:
                    create  tmp-cpc-fp0711b-saida.
                    assign  tmp-cpc-fp0711b-saida.lg-undo-retry  = no
                            tmp-cpc-fp0711b-saida.vl-calculo-aux = (moviproc.vl-cobrado).
                  end.
                  else
                  do:
                    create  tmp-cpc-fp0711b-saida.
                    assign  tmp-cpc-fp0711b-saida.lg-undo-retry  = no
                            tmp-cpc-fp0711b-saida.vl-calculo-aux = (moviproc.vl-principal + moviproc.vl-auxiliar).
                  end.
                end.                
                else
                do:
                   create  tmp-cpc-fp0711b-saida.
                   assign  tmp-cpc-fp0711b-saida.lg-undo-retry  = no
                           tmp-cpc-fp0711b-saida.vl-calculo-aux = moviproc.vl-real-pago.
                end.           
/*                         tmp-cpc-fp0711b-saida.vl-calculo-aux = (moviproc.vl-real-pago - moviproc.vl-taxa-out-uni-auxi - moviproc.vl-taxa-out-uni-prin). */
    
                run localiza-filme.
            end.
        end. /* ELSE DO IF PEGA JNJ COM PRESTADORES ESPECIFICOS. */
    end.
    
    when "APOSVALORIZAINS" then 
    do:
        find mov-insu where rowid(mov-insu) = tmp-cpc-fp0711b-entrada.r-mov-insu  no-lock no-error.
        if not available mov-insu then 
        do:
            return.
        end.

        if mov-insu.cd-unidade-carteira <> paramecp.cd-unimed or mov-insu.cd-modalidade = 95 or mov-insu.cd-modalidade = 96 then 
        do:
            create  tmp-cpc-fp0711b-saida.
            assign  tmp-cpc-fp0711b-saida.lg-undo-retry  = no
                    tmp-cpc-fp0711b-saida.vl-calculo-aux = tmp-cpc-fp0711b-entrada.vl-calculo-aux. /* Atualizacao 8.00.000  ANTES: tmp-cpc-fp0711b-saida.vl-calculo-aux = (mov-insu.vl-real-pago - mov-insu.vl-taxa-out-insumo - mov-insu.vl-taxa-out-uni-cobrado). */
            return.
        end.

        find propost where propost.cd-modalidade = mov-insu.cd-modalidade
                       and propost.nr-ter-adesao = mov-insu.nr-ter-adesao   no-lock no-error.
        if not available propost then return.

        find docrecon where docrecon.cd-unidade = mov-insu.cd-unidade            
                        and docrecon.cd-unidade-prestadora     = mov-insu.cd-unidade-prestadora
                        and docrecon.cd-transacao              = mov-insu.cd-transacao
                        and docrecon.nr-serie-doc-original     = mov-insu.nr-serie-doc-original
                        and docrecon.nr-doc-original           = mov-insu.nr-doc-original
                        and docrecon.nr-doc-sistema            = mov-insu.nr-doc-sistema            no-lock no-error.

        if not available docrecon then return.         

        /* Daqui Atualizacao 9.00.003 */
        /* Pega os registros da JNJ com prestadores especificos, cobranca normal e desconsiderar pagamento */
        /* 26/03/2018 - 2.00.00.001 - InclusÆo da modalidade 31 */
        if (propost.cd-modalidade = 30 or propost.cd-modalidade = 31 or propost.cd-modalidade = 45)     and
            propost.cd-plano      = 15                                                                  and
            mov-insu.cd-unidade-pagamento   = 4                                                         and 
           (mov-insu.cd-prestador-pagamento = 300010    or mov-insu.cd-prestador-pagamento = 300011)    and
            mov-insu.cd-tipo-pagamento      = 1                                                         and                                                        
            mov-insu.cd-tipo-cob            = 0                                                         then
        do:
            create  tmp-cpc-fp0711b-saida.                                                
            assign  tmp-cpc-fp0711b-saida.lg-undo-retry  = no                             
                    tmp-cpc-fp0711b-saida.vl-calculo-aux = mov-insu.vl-real-glosado.
            return.
        end.
        /* Ate aqui Atualizacao 9.00.003 */

        find first par-contr where par-contr.cd-modalidade = mov-insu.cd-modalidade
                               and par-contr.cd-plano      = propost.cd-plano
                               and par-contr.tp-plano      = propost.cd-tipo-plano      no-lock no-error.

        if available par-contr and par-contr.lg-fatura then 
        do:  
            /* 26/03/2018 - 2.00.00.001 - InclusÆo da modalidade 31 */
            if (propost.cd-modalidade = 30 or  propost.cd-modalidade = 31 or  propost.cd-modalidade = 45)  and  
                propost.cd-plano      = 15  then 
            do:
                if mov-insu.cd-tipo-insumo = 53 and mov-insu.cd-insumo = 1 then 
                do: 
                    run localiza-maior-valor.

                    find b2-moviproc where rowid(b2-moviproc) = r-proc-maior-valor-aux no-lock no-error.
                    if available b2-moviproc then
                    do:
                        find first taprampr where taprampr.cd-tab-preco-proc = "USJ01"
                                              and taprampr.cd-esp-amb        = b2-moviproc.cd-esp-amb
                                              and taprampr.cd-grupo-proc-amb = b2-moviproc.cd-grupo-proc-amb
                                              and taprampr.cd-procedimento   = b2-moviproc.cd-procedimento
                                              and taprampr.dv-procedimento   = b2-moviproc.dv-procedimento
                                              and taprampr.dt-limite        >= b2-moviproc.dt-realizacao        no-lock no-error.

                        if available taprampr then 
                        do:
                            /* PR/02/D na tabela USJ/01 e multiplicoa este procedimento por 40% e o resultado disso multiplico por 0,26.*/
                            create  tmp-cpc-fp0711b-saida.                                                
                            assign  tmp-cpc-fp0711b-saida.lg-undo-retry  = no                             
                                    tmp-cpc-fp0711b-saida.vl-calculo-aux = (((taprampr.qt-moeda-honorarios + taprampr.qt-moeda-operacional + taprampr.qt-moeda-filme) * 40) / 100) * .26.
                            return.
                        end. /* fim - IF AVAILABLE taprampr THEN */
                    end. /* fim - IF AVAILABLE b2-moviproc THEN */
                end. /* fim - IF mov-insu.cd-tipo-insumo = 53 AND mov-insu.cd-insumo = 1 THEN  */

                if mov-insu.cd-unidade-prestador <> 4 then
                do:
                    create  tmp-cpc-fp0711b-saida.
                    assign  tmp-cpc-fp0711b-saida.lg-undo-retry  = no
                            tmp-cpc-fp0711b-saida.vl-calculo-aux = mov-insu.vl-real-pago / 1.05 /* - ((mov-insu.vl-real-pago * 5) / 100) */.
                    /* tmp-cpc-fp0711b-saida.vl-calculo-aux = (mov-insu.vl-real-pago - mov-insu.vl-taxa-out-insumo - mov-insu.vl-taxa-out-uni-cobrado) / mov-insu.qt-insumo. */ /* Linha Original Celso 11/10/2012 */
                end.
                else
                do:
                    /* 26/03/2018 - 2.00.00.001 - InclusÆo da modalidade 31 */
                    if mov-insu.vl-rateio > 0 then 
                    do:
                       run verifica-rateio-insumo.
                       return.
                    end.

                    create  tmp-cpc-fp0711b-saida.
                    assign  tmp-cpc-fp0711b-saida.lg-undo-retry  = no
                            tmp-cpc-fp0711b-saida.vl-calculo-aux = mov-insu.vl-real-pago /* - ((mov-insu.vl-real-pago * 5) / 100) */.
                    /* tmp-cpc-fp0711b-saida.vl-calculo-aux = (mov-insu.vl-real-pago - mov-insu.vl-taxa-out-insumo - mov-insu.vl-taxa-out-uni-cobrado) / mov-insu.qt-insumo. */ /* Linha Original Celso 11/10/2012 */
                end.
            end.
        end.
    end.
end case.

procedure p-acha-moeda:

    define output parameter lg-achou-regra-par  as logical                      no-undo.
    define variable cd-tab-preco-cotacao-aux    like precproc.cd-tab-preco      no-undo.

    assign lg-achou-regra-par = no.

    find first comcopre where comcopre.cd-local-atendimento = docrecon.cd-local-atendimento                                 
                          and comcopre.cd-unidade           = moviproc.cd-unidade-prestador                                 
                          and comcopre.cd-prestador         = moviproc.cd-prestador 
                          and comcopre.in-tipo-combinacao   = 1
                          and comcopre.cd-modalidade        = moviproc.cd-modalidade                                            
                          and comcopre.nr-proposta          = propost.nr-proposta                                              
                          and comcopre.cd-plano             = 0                                                            
                          and comcopre.cd-tipo-plano        = 0                                                            
                          and comcopre.cd-modulo            = moviproc.cd-modulo                                            
                          and comcopre.cd-amb               = cd-proc-aux
                          and comcopre.dt-limite           >= moviproc.dt-realizacao           
                          use-index comcopre1 no-lock no-error.  
    
    if avail comcopre then 
        assign  cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco              /*1*/
                lg-achou-regra-par = yes.       

    if not lg-achou-regra-par then
    do: 
        find first comcopre where comcopre.cd-local-atendimento = docrecon.cd-local-atendimento            
                              and comcopre.cd-unidade           = moviproc.cd-unidade-prestador     
                              and comcopre.cd-prestador         = moviproc.cd-prestador             
                              and comcopre.cd-modalidade        = moviproc.cd-modalidade            
                              and comcopre.in-tipo-combinacao   = 1
                              and comcopre.nr-proposta          = propost.nr-proposta              
                              and comcopre.cd-plano             = 0                            
                              and comcopre.cd-tipo-plano        = 0                            
                              and comcopre.cd-modulo            = moviproc.cd-modulo                
                              and comcopre.cd-amb               = 0             
                              and comcopre.dt-limite           >= moviproc.dt-realizacao
                              use-index comcopre1 no-lock no-error.

        if avail comcopre then 
            assign  cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco          /*2*/ 
                    lg-achou-regra-par = yes.
    end.
    
    if not lg-achou-regra-par then
    do:
        find first comcopre where comcopre.cd-local-atendimento = docrecon.cd-local-atendimento            
                              and comcopre.cd-unidade           = moviproc.cd-unidade-prestador     
                              and comcopre.cd-prestador         = moviproc.cd-prestador             
                              and comcopre.in-tipo-combinacao   = 1
                              and comcopre.cd-modalidade        = moviproc.cd-modalidade            
                              and comcopre.nr-proposta          = propost.nr-proposta              
                              and comcopre.cd-plano             = 0                            
                              and comcopre.cd-tipo-plano        = 0                            
                              and comcopre.cd-modulo            = 0                
                              and comcopre.cd-amb               = 0                            
                              and comcopre.dt-limite           >= moviproc.dt-realizacao
                              use-index comcopre1 no-lock no-error.

        if avail comcopre then
            assign  cd-tab-preco-cotacao-aux    =   comcopre.cd-tab-preco           /*3*/
                    lg-achou-regra-par          =   yes.       
    end.
                                                
         
    if   not lg-achou-regra-par                                                       
    then do:    
           find first comcopre where                                                  
                      comcopre.cd-local-atendimento = docrecon.cd-local-atendimento               
                  and comcopre.cd-unidade           = moviproc.cd-unidade-prestador        
                  and comcopre.cd-prestador         = moviproc.cd-prestador                
                  and comcopre.in-tipo-combinacao   = 2
                  and comcopre.cd-modalidade        = moviproc.cd-modalidade               
                  and comcopre.nr-proposta          = 0                               
                  and comcopre.cd-plano             = propost.cd-plano                    
                  and comcopre.cd-tipo-plano        = propost.cd-tipo-plano               
                  and comcopre.cd-modulo            = moviproc.cd-modulo                   
                  and comcopre.cd-amb               = cd-proc-aux                
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error.   
                                                                                      
           if avail comcopre                                                          
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco             
                       lg-achou-regra-par = yes.                                      

         end.                                                                   /*4*/          
                                                                                      
                                                                                      
                                                                                      
    if   not lg-achou-regra-par                                                       
    then do:                                                                          
           find first comcopre where                                                  
                      comcopre.cd-local-atendimento = docrecon.cd-local-atendimento               
                  and comcopre.cd-unidade           = moviproc.cd-unidade-prestador        
                  and comcopre.cd-prestador         = moviproc.cd-prestador                
                  and comcopre.in-tipo-combinacao   = 2
                  and comcopre.cd-modalidade        = moviproc.cd-modalidade               
                  and comcopre.nr-proposta          = 0                               
                  and comcopre.cd-plano             = propost.cd-plano                    
                  and comcopre.cd-tipo-plano        = propost.cd-tipo-plano               
                  and comcopre.cd-modulo            = moviproc.cd-modulo                   
                  and comcopre.cd-amb               = 0                               
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error.   
                                                                                      
           if avail comcopre                                                          
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco             
                       lg-achou-regra-par = yes.                     
                                                                                /*5*/      
         end.           
    
    
         
    if   not lg-achou-regra-par                                                       
    then do:                                                                          
           find first comcopre where                                                  
                      comcopre.cd-local-atendimento = docrecon.cd-local-atendimento               
                  and comcopre.cd-unidade           = moviproc.cd-unidade-prestador        
                  and comcopre.cd-prestador         = moviproc.cd-prestador  
                  and comcopre.in-tipo-combinacao   = 2
                  and comcopre.cd-modalidade        = moviproc.cd-modalidade               
                  and comcopre.nr-proposta          = 0                               
                  and comcopre.cd-plano             = propost.cd-plano                    
                  and comcopre.cd-tipo-plano        = propost.cd-tipo-plano               
                  and comcopre.cd-modulo            = 0                               
                  and comcopre.cd-amb               = 0                               
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error.   
                                                                                      
           if avail comcopre                                                          
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco             
                       lg-achou-regra-par = yes.                         
                                                                            /*6*/          
         end.                                                                         
    
    
    /**/
    
    if   not lg-achou-regra-par                                                           
    then do:                                                                             
           find first comcopre where                                                     
                      comcopre.cd-local-atendimento = docrecon.cd-local-atendimento                  
                  and comcopre.cd-unidade           = moviproc.cd-unidade-prestador           
                  and comcopre.cd-prestador         = moviproc.cd-prestador                   
                  and comcopre.in-tipo-combinacao   = 3
                  and comcopre.cd-modalidade        = 0                                  
                  and comcopre.nr-proposta          = 0                                  
                  and comcopre.cd-plano             = 0                                  
                  and comcopre.cd-tipo-plano        = 0                                  
                  and comcopre.cd-modulo            = moviproc.cd-modulo                      
                  and comcopre.cd-amb               = cd-proc-aux                   
                  and comcopre.dt-limite           >= moviproc.dt-realizacao 
                  use-index comcopre1 no-lock no-error.      
                                                                                         
           if avail comcopre                                                             
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco                
                       lg-achou-regra-par = yes.                                         
                                                                                         
         end.                                                               /*7*/             
                                                                                         
                                                                                         
                                                                                         
    if   not lg-achou-regra-par                                                          
    then do:                                                                             
           find first comcopre where                                                     
                      comcopre.cd-local-atendimento = docrecon.cd-local-atendimento                  
                  and comcopre.cd-unidade           = moviproc.cd-unidade-prestador           
                  and comcopre.cd-prestador         = moviproc.cd-prestador                   
                  and comcopre.in-tipo-combinacao   = 3
                  and comcopre.cd-modalidade        = 0                                  
                  and comcopre.nr-proposta          = 0                                  
                  and comcopre.cd-plano             = 0                                  
                  and comcopre.cd-tipo-plano        = 0                                  
                  and comcopre.cd-modulo            = moviproc.cd-modulo                      
                  and comcopre.cd-amb               = 0                                  
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error.      
                                                                                         
           if avail comcopre                                                             
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco                
                       lg-achou-regra-par = yes.                                         
                                                                                         
         end.                                                               /*8*/                
                                                                                         
                                                                                         
                                                                                         
    if   not lg-achou-regra-par                                                          
    then do:                                                                             
           find first comcopre where                                                     
                      comcopre.cd-local-atendimento = docrecon.cd-local-atendimento                  
                  and comcopre.cd-unidade           = moviproc.cd-unidade-prestador           
                  and comcopre.cd-prestador         = moviproc.cd-prestador                   
                  and comcopre.in-tipo-combinacao   = 3
                  and comcopre.cd-modalidade        = 0                                  
                  and comcopre.nr-proposta          = 0                                  
                  and comcopre.cd-plano             = 0                                  
                  and comcopre.cd-tipo-plano        = 0                                  
                  and comcopre.cd-modulo            = 0                                  
                  and comcopre.cd-amb               = 0                                  
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error.      
                                                                                         
           if avail comcopre                                                             
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco                
                       lg-achou-regra-par = yes.        
                                                                                         
         end.                                                                            
                                                                            /*9*/
    /**/
    
    if   not lg-achou-regra-par 
    then do:                                                                         
           find first comcopre where
                      comcopre.cd-local-atendimento = 0                                                     
                  and comcopre.cd-unidade           = moviproc.cd-unidade-prestador                          
                  and comcopre.cd-prestador         = moviproc.cd-prestador                                  
                  and comcopre.in-tipo-combinacao   = 1
                  and comcopre.cd-modalidade        = moviproc.cd-modalidade                                     
                  and comcopre.nr-proposta          = propost.nr-proposta                                       
                  and comcopre.cd-plano             = 0                                                     
                  and comcopre.cd-tipo-plano        = 0                                                     
                  and comcopre.cd-modulo            = moviproc.cd-modulo                                     
                  and comcopre.cd-amb               = cd-proc-aux
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error.                                         
    
           if avail comcopre                                                         
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco
                       lg-achou-regra-par = yes.         
                                                                                     
         end.                                                              /*10*/          
                                                                                     
    
    if   not lg-achou-regra-par                                                     
    then do:                                                                        
           find first comcopre where                                                
                      comcopre.cd-local-atendimento = 0                             
                  and comcopre.cd-unidade           = moviproc.cd-unidade-prestador      
                  and comcopre.cd-prestador         = moviproc.cd-prestador              
                  and comcopre.in-tipo-combinacao   = 1
                  and comcopre.cd-modalidade        = moviproc.cd-modalidade             
                  and comcopre.nr-proposta          = propost.nr-proposta               
                  and comcopre.cd-plano             = 0                             
                  and comcopre.cd-tipo-plano        = 0                             
                  and comcopre.cd-modulo            = moviproc.cd-modulo                 
                  and comcopre.cd-amb               = 0              
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error. 
                                                                                    
           if avail comcopre                                                        
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco           
                       lg-achou-regra-par = yes.        
                                                                          /*11*/          
         end.                                                                       
    
    
    if   not lg-achou-regra-par                                                     
    then do:                                                                        
           find first comcopre where                                                
                      comcopre.cd-local-atendimento = 0                             
                  and comcopre.cd-unidade           = moviproc.cd-unidade-prestador      
                  and comcopre.cd-prestador         = moviproc.cd-prestador   
                  and comcopre.in-tipo-combinacao   = 1
                  and comcopre.cd-modalidade        = moviproc.cd-modalidade             
                  and comcopre.nr-proposta          = propost.nr-proposta               
                  and comcopre.cd-plano             = 0                             
                  and comcopre.cd-tipo-plano        = 0                             
                  and comcopre.cd-modulo            = 0                 
                  and comcopre.cd-amb               = 0              
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error. 
                                                                                    
           if avail comcopre                                                        
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco           
                       lg-achou-regra-par = yes.    
                                                                                    
         end.                                                        /*12*/               
    
    /**/
          
    if   not lg-achou-regra-par                                                      
    then do:                                                                         
           find first comcopre where                                                 
                      comcopre.cd-local-atendimento = 0                              
                  and comcopre.cd-unidade           = moviproc.cd-unidade-prestador       
                  and comcopre.cd-prestador         = moviproc.cd-prestador     
                  and comcopre.in-tipo-combinacao   = 2
                  and comcopre.cd-modalidade        = moviproc.cd-modalidade              
                  and comcopre.nr-proposta          = 0                              
                  and comcopre.cd-plano             = propost.cd-plano                   
                  and comcopre.cd-tipo-plano        = propost.cd-tipo-plano              
                  and comcopre.cd-modulo            = moviproc.cd-modulo                  
                  and comcopre.cd-amb               = cd-proc-aux               
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error.  
                                                                                     
           if avail comcopre                                                         
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco            
                       lg-achou-regra-par = yes.      
                                                                       /*13*/              
         end.                                                                        
                                                                                     
                                                                                     
                                                                                     
    if   not lg-achou-regra-par                                                      
    then do:                                                                         
           find first comcopre where                                                 
                      comcopre.cd-local-atendimento = 0                              
                  and comcopre.cd-unidade           = moviproc.cd-unidade-prestador       
                  and comcopre.cd-prestador         = moviproc.cd-prestador   
                  and comcopre.in-tipo-combinacao   = 2
                  and comcopre.cd-modalidade        = moviproc.cd-modalidade              
                  and comcopre.nr-proposta          = 0                              
                  and comcopre.cd-plano             = propost.cd-plano                   
                  and comcopre.cd-tipo-plano        = propost.cd-tipo-plano              
                  and comcopre.cd-modulo            = moviproc.cd-modulo                  
                  and comcopre.cd-amb               = 0                              
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error.  
                                                                                     
           if avail comcopre                                                         
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco            
                       lg-achou-regra-par = yes.   
                                                                     /*14*/                
         end.                                                                        
                                                                                     
                                                                                     
    if   not lg-achou-regra-par                                                      
    then do:                                                                         
           find first comcopre where                                                 
                      comcopre.cd-local-atendimento = 0                              
                  and comcopre.cd-unidade           = moviproc.cd-unidade-prestador       
                  and comcopre.cd-prestador         = moviproc.cd-prestador               
                  and comcopre.in-tipo-combinacao   = 2
                  and comcopre.cd-modalidade        = moviproc.cd-modalidade              
                  and comcopre.nr-proposta          = 0                              
                  and comcopre.cd-plano             = propost.cd-plano                   
                  and comcopre.cd-tipo-plano        = propost.cd-tipo-plano              
                  and comcopre.cd-modulo            = 0                              
                  and comcopre.cd-amb               = 0                              
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error.  
                                                                                     
           if avail comcopre                                                         
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco            
                       lg-achou-regra-par = yes.  
                                                                                     
         end.                                                      /*15*/                  
    
    /**/
    
    if   not lg-achou-regra-par                                                     
    then do:                                                                        
           find first comcopre where                                                
                      comcopre.cd-local-atendimento = 0                             
                  and comcopre.cd-unidade           = moviproc.cd-unidade-prestador      
                  and comcopre.cd-prestador         = moviproc.cd-prestador
                  and comcopre.in-tipo-combinacao   = 3
                  and comcopre.cd-modalidade        = 0                             
                  and comcopre.nr-proposta          = 0                             
                  and comcopre.cd-plano             = 0                             
                  and comcopre.cd-tipo-plano        = 0                             
                  and comcopre.cd-modulo            = moviproc.cd-modulo                 
                  and comcopre.cd-amb               = cd-proc-aux              
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error. 
                                                                                    
           if avail comcopre                                                        
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco           
                       lg-achou-regra-par = yes.     
                                                                      /*16*/              
         end.                                                                       
                                                                                    
                                                                                    
                                                                                    
    if   not lg-achou-regra-par                                                     
    then do:                                                                        
           find first comcopre where                                                
                      comcopre.cd-local-atendimento = 0                             
                  and comcopre.cd-unidade           = moviproc.cd-unidade-prestador      
                  and comcopre.cd-prestador         = moviproc.cd-prestador    
                  and comcopre.in-tipo-combinacao   = 3
                  and comcopre.cd-modalidade        = 0                             
                  and comcopre.nr-proposta          = 0                             
                  and comcopre.cd-plano             = 0                             
                  and comcopre.cd-tipo-plano        = 0                             
                  and comcopre.cd-modulo            = moviproc.cd-modulo                 
                  and comcopre.cd-amb               = 0                             
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error. 
                                                                                    
           if avail comcopre                                                        
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco           
                       lg-achou-regra-par = yes.    
                                                                     /*17*/               
         end.                                                                       
                                                                                    
    
    if   not lg-achou-regra-par                                                     
    then do:                                                                        
           find first comcopre where                                                
                      comcopre.cd-local-atendimento = 0                             
                  and comcopre.cd-unidade           = moviproc.cd-unidade-prestador      
                  and comcopre.cd-prestador         = moviproc.cd-prestador
                  and comcopre.in-tipo-combinacao   = 3
                  and comcopre.cd-modalidade        = 0                             
                  and comcopre.nr-proposta          = 0                             
                  and comcopre.cd-plano             = 0                             
                  and comcopre.cd-tipo-plano        = 0                             
                  and comcopre.cd-modulo            = 0                             
                  and comcopre.cd-amb               = 0                             
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error. 
                                                                                    
           if avail comcopre                                                        
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco           
                       lg-achou-regra-par = yes.     
                                                                                    
         end.                                                     /*18*/                  
    
    /**/
    
    if   not lg-achou-regra-par                                                      
    then do:                                                                         
           find first comcopre where                                                 
                      comcopre.cd-local-atendimento = docrecon.cd-local-atendimento                              
                  and comcopre.cd-unidade           = 0       
                  and comcopre.cd-prestador         = 0                              
                  and comcopre.in-tipo-combinacao   = 1
                  and comcopre.cd-modalidade        = moviproc.cd-modalidade                             
                  and comcopre.nr-proposta          = propost.nr-proposta                               
                  and comcopre.cd-plano             = 0                              
                  and comcopre.cd-tipo-plano        = 0                              
                  and comcopre.cd-modulo            = moviproc.cd-modulo                  
                  and comcopre.cd-amb               = cd-proc-aux               
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error.  
                                                                                     
           if avail comcopre                                                         
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco            
                       lg-achou-regra-par = yes.   
                                                                                     
         end.                                                       /*19*/           
                                                                                     
                                                                                     
    if   not lg-achou-regra-par                                                      
    then do:                                                                         
           find first comcopre where                                                 
                      comcopre.cd-local-atendimento = docrecon.cd-local-atendimento                              
                  and comcopre.cd-unidade           = 0                    
                  and comcopre.cd-prestador         = 0                          
                  and comcopre.in-tipo-combinacao   = 1
                  and comcopre.cd-modalidade        = moviproc.cd-modalidade              
                  and comcopre.nr-proposta          = propost.nr-proposta                
                  and comcopre.cd-plano             = 0                              
                  and comcopre.cd-tipo-plano        = 0                              
                  and comcopre.cd-modulo            = moviproc.cd-modulo                  
                  and comcopre.cd-amb               = 0               
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error.  
                                                                                     
           if avail comcopre                                                         
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco            
                       lg-achou-regra-par = yes.  
                                                                                     
         end.                                                       /*20*/           
                                                                                     
     /**/                                                                            
                                                                                     
    if   not lg-achou-regra-par                                                      
    then do:                                                                         
           find first comcopre where                                                 
                      comcopre.cd-local-atendimento = docrecon.cd-local-atendimento           
                  and comcopre.cd-unidade           = 0                           
                  and comcopre.cd-prestador         = 0                         
                  and comcopre.in-tipo-combinacao   = 1
                  and comcopre.cd-modalidade        = moviproc.cd-modalidade           
                  and comcopre.nr-proposta          = propost.nr-proposta             
                  and comcopre.cd-plano             = 0                           
                  and comcopre.cd-tipo-plano        = 0                           
                  and comcopre.cd-modulo            = 0            
                  and comcopre.cd-amb               = 0            
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error.  
                                                                                     
           if avail comcopre                                                         
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco            
                       lg-achou-regra-par = yes. 
                                                                                     
         end.                                                       /*21*/            
                                                                                     
    
    if   not lg-achou-regra-par                                                         
    then do:                                                                            
           find first comcopre where                                                    
                      comcopre.cd-local-atendimento = docrecon.cd-local-atendimento                 
                  and comcopre.cd-unidade           = 0                                 
                  and comcopre.cd-prestador         = 0                    
                  and comcopre.in-tipo-combinacao   = 2
                  and comcopre.cd-modalidade        = moviproc.cd-modalidade                 
                  and comcopre.nr-proposta          = 0                   
                  and comcopre.cd-plano             = propost.cd-plano                                    
                  and comcopre.cd-tipo-plano        = propost.cd-tipo-plano                               
                  and comcopre.cd-modulo            = moviproc.cd-modulo                     
                  and comcopre.cd-amb               = cd-proc-aux                  
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error.     
                                                                                        
           if avail comcopre                                                            
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco               
                       lg-achou-regra-par = yes.      
                                                                                        
         end.                                                       /*22*/              
                                                                                        
                                                                                        
    if   not lg-achou-regra-par                                                         
    then do:                                                                            
           find first comcopre where                                                    
                      comcopre.cd-local-atendimento = docrecon.cd-local-atendimento                    
                  and comcopre.cd-unidade           = 0                                    
                  and comcopre.cd-prestador         = 0                         
                  and comcopre.in-tipo-combinacao   = 2
                  and comcopre.cd-modalidade        = moviproc.cd-modalidade                    
                  and comcopre.nr-proposta          = 0                                    
                  and comcopre.cd-plano             = propost.cd-plano                         
                  and comcopre.cd-tipo-plano        = propost.cd-tipo-plano                    
                  and comcopre.cd-modulo            = moviproc.cd-modulo                        
                  and comcopre.cd-amb               = 0                     
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error.     
                                                                                        
           if avail comcopre                                                            
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco               
                       lg-achou-regra-par = yes.   
                                                                                        
         end.                                                       /*23*/              
                                                                                        
     /**/                                                                               
                                                                                        
    if   not lg-achou-regra-par                                                         
    then do:                                                                            
           find first comcopre where                                                    
                      comcopre.cd-local-atendimento = docrecon.cd-local-atendimento                  
                  and comcopre.cd-unidade           = 0                                  
                  and comcopre.cd-prestador         = 0    
                  and comcopre.in-tipo-combinacao   = 2
                  and comcopre.cd-modalidade        = moviproc.cd-modalidade                  
                  and comcopre.nr-proposta          = 0                                  
                  and comcopre.cd-plano             = propost.cd-plano                       
                  and comcopre.cd-tipo-plano        = propost.cd-tipo-plano                  
                  and comcopre.cd-modulo            = 0                     
                  and comcopre.cd-amb               = 0                                  
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error.     
                                                                                        
           if avail comcopre                                                            
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco               
                       lg-achou-regra-par = yes.    
                                                                                        
         end.                                                       /*24*/               
    
    
    if   not lg-achou-regra-par                                                     
    then do:                                                                        
           find first comcopre where                                                
                      comcopre.cd-local-atendimento = docrecon.cd-local-atendimento             
                  and comcopre.cd-unidade           = 0                             
                  and comcopre.cd-prestador         = 0                      
                  and comcopre.in-tipo-combinacao   = 3
                  and comcopre.cd-modalidade        = 0           
                  and comcopre.nr-proposta          = 0                             
                  and comcopre.cd-plano             = 0                  
                  and comcopre.cd-tipo-plano        = 0             
                  and comcopre.cd-modulo            = moviproc.cd-modulo                 
                  and comcopre.cd-amb               = cd-proc-aux              
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error. 
                                                                                    
           if avail comcopre                                                        
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco           
                       lg-achou-regra-par = yes.  
                                                                                    
         end.                                                       /*25*/          
                                                                                    
                                                                                    
    if   not lg-achou-regra-par                                                     
    then do:                                                                        
           find first comcopre where                                                
                      comcopre.cd-local-atendimento = docrecon.cd-local-atendimento         
                  and comcopre.cd-unidade           = 0                         
                  and comcopre.cd-prestador         = 0            
                  and comcopre.in-tipo-combinacao   = 3
                  and comcopre.cd-modalidade        = 0                         
                  and comcopre.nr-proposta          = 0                         
                  and comcopre.cd-plano             = 0                         
                  and comcopre.cd-tipo-plano        = 0                         
                  and comcopre.cd-modulo            = moviproc.cd-modulo             
                  and comcopre.cd-amb               = 0          
                  and comcopre.dt-limite           >= moviproc.dt-realizacao 
                  use-index comcopre1 no-lock no-error. 
                                                                                    
           if avail comcopre                                                        
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco           
                       lg-achou-regra-par = yes.    
                                                                                    
         end.                                                       /*26*/          
                                                                                    
     /**/                                                                           
                                                                                    
    if   not lg-achou-regra-par                                                     
    then do:                                                                        
           find first comcopre where                                                
                      comcopre.cd-local-atendimento = docrecon.cd-local-atendimento           
                  and comcopre.cd-unidade           = 0                           
                  and comcopre.cd-prestador         = 0                     
                  and comcopre.in-tipo-combinacao   = 3
                  and comcopre.cd-modalidade        = 0                     
                  and comcopre.nr-proposta          = 0                           
                  and comcopre.cd-plano             = 0                           
                  and comcopre.cd-tipo-plano        = 0                           
                  and comcopre.cd-modulo            = 0              
                  and comcopre.cd-amb               = 0           
                  and comcopre.dt-limite           >= moviproc.dt-realizacao
                  use-index comcopre1 no-lock no-error. 
                                                                                    
           if avail comcopre                                                        
           then assign cd-tab-preco-cotacao-aux   = comcopre.cd-tab-preco           
                       lg-achou-regra-par = yes.  
                                                                                    
         end.                                                      /*27*/      

end procedure.

procedure localiza-filme:

   for each b-moviproc where b-moviproc.cd-unidade            = moviproc.cd-unidade        
                         and b-moviproc.cd-unidade-prestadora = moviproc.cd-unidade-prestadora
                         and b-moviproc.cd-transacao          = moviproc.cd-transacao           
                         and b-moviproc.nr-serie-doc-original = moviproc.nr-serie-doc-original  
                         and b-moviproc.nr-doc-original       = moviproc.nr-doc-original        
                         and b-moviproc.cd-esp-amb            = moviproc.cd-esp-amb             
                         and b-moviproc.cd-grupo-proc-amb     = moviproc.cd-grupo-proc-amb      
                         and b-moviproc.cd-procedimento       = moviproc.cd-procedimento        
                         and b-moviproc.dv-procedimento       = moviproc.dv-procedimento   
                             no-lock:

       if rowid(b-moviproc) = rowid(moviproc)
       then next.

       if moviproc.dt-realizacao <> b-moviproc.dt-realizacao 
       then next.

       if b-moviproc.cd-tipo-cob <> 3
       then next.

       if b-moviproc.vl-filme > 0
       then assign tmp-cpc-fp0711b-saida.vl-calculo-aux = tmp-cpc-fp0711b-saida.vl-calculo-aux + b-moviproc.vl-filme.

       if b-moviproc.vl-operacional > 0
       then assign tmp-cpc-fp0711b-saida.vl-calculo-aux = tmp-cpc-fp0711b-saida.vl-calculo-aux + b-moviproc.vl-operacional.
   end.

end procedure.

procedure localiza-maior-valor:
   
   assign vl-proc-maior-valor-aux = 0
          r-proc-maior-valor-aux  = ?.

   for each b2-moviproc where b2-moviproc.cd-unidade             = docrecon.cd-unidade           
                          and b2-moviproc.cd-unidade-prestadora  = docrecon.cd-unidade-prestadora
                          and b2-moviproc.cd-transacao           = docrecon.cd-transacao           
                          and b2-moviproc.nr-serie-doc-original  = docrecon.nr-serie-doc-original  
                          and b2-moviproc.nr-doc-original        = docrecon.nr-doc-original        
                          and b2-moviproc.nr-doc-sistema         = docrecon.nr-doc-sistema         
                              no-lock:

       if (b2-moviproc.vl-auxiliar + b2-moviproc.vl-principal) > vl-proc-maior-valor-aux
       then assign vl-proc-maior-valor-aux = (b2-moviproc.vl-auxiliar + b2-moviproc.vl-principal)
                   r-proc-maior-valor-aux  = rowid(b2-moviproc).
   end.

end procedure.

procedure verifica-rateio.

        if (propost.cd-modalidade = 30 or propost.cd-modalidade = 45)  and
            propost.cd-plano      = 15                                 and
            moviproc.vl-rateio    > 0                                  then
        do:
            if moviproc.vl-cobrado < (moviproc.vl-principal + moviproc.vl-auxiliar) then 
            do:
               create  tmp-cpc-fp0711b-saida.
               assign  tmp-cpc-fp0711b-saida.lg-undo-retry  = no
                       tmp-cpc-fp0711b-saida.vl-calculo-aux = moviproc.vl-cobrado.
               return.
            end.
            else
            do:
               create  tmp-cpc-fp0711b-saida.
               assign  tmp-cpc-fp0711b-saida.lg-undo-retry  = no
                       tmp-cpc-fp0711b-saida.vl-calculo-aux = (moviproc.vl-principal + moviproc.vl-auxiliar).
               return.
            end.
        end.

end procedure.

procedure verifica-rateio-insumo.

        if (propost.cd-modalidade = 30 or propost.cd-modalidade = 45) and
            propost.cd-plano      = 15                                and
            mov-insu.vl-rateio    > 0                                 then
        do:
            if mov-insu.vl-cobrado < mov-insu.vl-insumo then 
            do:
               create  tmp-cpc-fp0711b-saida.
               assign  tmp-cpc-fp0711b-saida.lg-undo-retry  = no
                       tmp-cpc-fp0711b-saida.vl-calculo-aux = mov-insu.vl-cobrado.
               return.
            end.
            else
            do:
               create  tmp-cpc-fp0711b-saida.
               assign  tmp-cpc-fp0711b-saida.lg-undo-retry  = no
                       tmp-cpc-fp0711b-saida.vl-calculo-aux = mov-insu.vl-insumo.
               return.
            end.
        end.
        
end procedure.        
