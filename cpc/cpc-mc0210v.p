/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i CPCFONTES/CPC-MC0210V.P 1.02.00.003}  /*** 010003 ***/

&IF "{&EMSFND_VERSION}" >= "1.00" &THEN
{include/i-license-manager.i cpc-at0110c1 MCP}
&ENDIF

/*******************************************************************************************
* Programa .....: cpc-mc0210v.p                                                            *
* Data .........: 26/10/2016                                                               *
* Sistema ......: Totvs                                                                    *
* Empresa ......: Totvs                                                                    *
* Cliente ......: Unimed S∆o JosÇ dos Campos                                               *
* Analista .....: Celso Akira Tabuchi                                                      *
* Programador ..: Celso Akira Tabuchi                                                      *
* Objetivo .....: Permitir reativaá∆o de benefici†rio mesmo que o ultimo faturamento do    *
*                 benefici†rio esteja diferente do ultimo faturamento do termo.            *
********************************************************************************************
* VERSAO       DATA           RESPONSAVEL         MOTIVO                                   *
* E.1.00.000   26/10/2016     Celso Akira Tabuchi Desenvolvimento                          *
*******************************************************************************************/

DEFINE VARIABLE c-versao        AS CHARACTER                NO-UNDO.
ASSIGN c-versao = "1.00.000".

/* ------------------------ Include usada pela cpc -------------------------- */
{cpc/cpc-mc0210v.i}
{rtp/rtrowerror.i}
/*--------------------------------- Variavel que identifica magnus ou EMS ---*/
{hdp/hdsistem.i}                                                                                            

/* ----------------- Definicai dos parametros de entrada e saida ------------ */
DEFINE INPUT        PARAMETER TABLE FOR tmp-cpc-mc0210v-entrada.
DEFINE OUTPUT       PARAMETER TABLE FOR tmp-cpc-mc0210v-saida.
DEFINE INPUT-OUTPUT PARAMETER TABLE FOR rowErrors.
/*----------------------------------------------------------------------------*/

FIND FIRST tmp-cpc-mc0210v-entrada NO-LOCK NO-ERROR.

IF AVAILABLE tmp-cpc-mc0210v-entrada THEN
DO:    
    CASE tmp-cpc-mc0210v-entrada.nm-ponto-chamada-cpc:     
        WHEN "REATIVA-BENEF" THEN
        DO:
            RUN verifica-reativa.
        END.
        WHEN "SETA-DT-REAT" THEN
        DO: 
            /* Por enquanto n∆o h† execuá‰es por aqui */
        END.
        WHEN "VERIF-SIT-BENEF" THEN
        DO:
            /* Por enquanto n∆o h† execuá‰es por aqui */
        END.
    END CASE.
END.
ELSE
DO:
    CREATE  tmp-cpc-mc0210v-saida.
    ASSIGN  tmp-cpc-mc0210v-saida.lg-undo-retry     = YES
            tmp-cpc-mc0210v-saida.ds-mensagem-erro  = "Tabela temporaria de entrada indisponivel CPC-mc0210v".
    RETURN.
END.


PROCEDURE verifica-reativa.
    /* Verificar se a reativaá∆o esta dentro do prazo de 1 màs */
    FIND usuario WHERE ROWID(usuario) = tmp-cpc-mc0210v-entrada.r-usuario NO-LOCK NO-ERROR.

    FIND ter-ade WHERE ter-ade.cd-modalidade = usuario.cd-modalidade
                   AND ter-ade.nr-ter-adesao = usuario.nr-ter-adesao
                   USE-INDEX ter-ade1 NO-LOCK NO-ERROR.


                   
                   
                   
                   
    IF AVAIL usuario THEN
    DO:
        IF AVAIL ter-ade THEN
        DO:
            IF usuario.dt-exclusao-plano < (TODAY - 90) THEN.
	        ELSE
	        DO:
                IF(usuario.aa-ult-fat <> ter-ade.aa-ult-fat OR usuario.mm-ult-fat <> ter-ade.mm-ult-fat) THEN
		        DO:
                    FIND FIRST tmp-cpc-mc0210v-saida NO-LOCK NO-ERROR.

                    IF NOT AVAIL tmp-cpc-mc0210v-saida THEN
			        DO:
                        CREATE tmp-cpc-mc0210v-saida.
                    END.

                    ASSIGN tmp-cpc-mc0210v-saida.lg-reativa = YES.
		    
            
                    for each event-progdo-bnfciar exclusive-lock
                       where event-progdo-bnfciar.cd-modalidade   = usuario.cd-modalidade        
                         and event-progdo-bnfciar.nr-ter-adesao   = usuario.nr-ter-adesao
                         and event-progdo-bnfciar.cd-usuario      = usuario.cd-usuario 
                         and event-progdo-bnfciar.nr-sequencia    = 0:
                             
                         if  event-progdo-bnfciar.cd-evento = 981
                         or  event-progdo-bnfciar.cd-evento = 982
                         then delete event-progdo-bnfciar.  
                          
                    end.
                    
                    
                    
                END.
	        END.
        END.
    END.

END PROCEDURE.

