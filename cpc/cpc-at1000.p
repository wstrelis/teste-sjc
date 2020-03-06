{cpc/cpc-at1000.i}

define input  parameter table for tmp-cpc-at1000-entrada.
define input  parameter table for tmp-cpc-at1000-movtos.
define output parameter table for tmp-cpc-at1000-saida.

define variable c-versao        as character format "x(08)" no-undo.
assign c-versao = "7.01.000".

find first tmp-cpc-at1000-entrada no-lock no-error.

if not avail tmp-cpc-at1000-entrada
then do:
    create tmp-cpc-at1000-saida.
    assign tmp-cpc-at1000-saida.lg-undo-retry   = yes
           tmp-cpc-at1000-saida.ds-mensagem     = "Tabela de entrada da CPC-AT1000 nao foi informada".
    return.
end.


run ProcessaCPC.



/* ************************  Function Prototypes ********************** */
function AtendeRegraNaoTrafegar returns logical 
	(in-tipo-guia          AS   INTEGER) forward.

/* **********************  Internal Procedures  *********************** */

procedure PontoAntesEnviarIE:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    
    find first paramecp no-lock.

    find first guiautor no-lock
         where rowid (guiautor) = tmp-cpc-at1000-entrada.nr-rowid-guiaautor
                no-error.

    if not available guiautor
    then do:
        create tmp-cpc-at1000-saida.
        assign tmp-cpc-at1000-saida.lg-undo-retry   = yes
               tmp-cpc-at1000-saida.ds-mensagem     = substitute ("Nao foi encontrada a guia com o rowid (&1)", tmp-cpc-at1000-entrada.nr-rowid-guiaautor).
        return.        
    end.
    
    create tmp-cpc-at1000-saida. 
    assign tmp-cpc-at1000-saida.lg-undo-retry       = no               
           tmp-cpc-at1000-saida.cd-unidade-carteira = guiautor.cd-unidade-carteira.        
    
    if guiautor.in-liberado-guias   = "9"
    then do:
        assign tmp-cpc-at1000-saida.cd-unidade-carteira = paramecp.cd-unimed.
    end.

end procedure.

procedure PontoAtualizaStatus:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/

    define variable lg-deixar-guia-auditoria            as   logical            no-undo.

    find first paramecp no-lock.
    
    find first guiautor no-lock
         where rowid (guiautor) = tmp-cpc-at1000-entrada.nr-rowid-guiaautor
                no-error.

    create tmp-cpc-at1000-saida. 
    assign tmp-cpc-at1000-saida.lg-undo-retry       = no.               

    if not available guiautor
    then do:
        assign tmp-cpc-at1000-saida.lg-undo-retry   = yes
               tmp-cpc-at1000-saida.ds-mensagem     = substitute ("Nao foi encontrada a guia com o rowid (&1)", tmp-cpc-at1000-entrada.nr-rowid-guiaautor).
        return.        
    end.
    
    if guiautor.cd-unidade-carteira     = paramecp.cd-unimed
    then return.
    
    if  guiautor.in-liberado-guias      = '10' /* PENDENTE LIBERACAO */
    then do:
        ASSIGN guiautor.nm-grupo = "INT REC".
    end.    

    if lg-deixar-guia-auditoria
    then do:
        tmp-cpc-at1000-saida.in-liberado-guias  = "9".
    end.               
end procedure.

procedure PontoAutorizacaoAutomatica:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    
    find first paramecp no-lock.
    
    create tmp-cpc-at1000-saida. 
    assign tmp-cpc-at1000-saida.lg-undo-retry           = no
           tmp-cpc-at1000-saida.ds-mensagem             = "".
    
    find first guiautor no-lock
         where rowid (guiautor) = tmp-cpc-at1000-entrada.nr-rowid-guiaautor 
               no-error.
               
    if not available guiautor 
    then return.
    
    assign tmp-cpc-at1000-saida.in-liberado-guias   = guiautor.in-liberado-guias.               
    
    if tmp-cpc-at1000-entrada.cd-unidade-carteira   = paramecp.cd-unimed
    then return.
    
    if AtendeRegraNaoTrafegar (guiautor.cd-tipo-guia)
    then do:
        assign tmp-cpc-at1000-saida.in-liberado-guias   = '10'.
    end.
    

end procedure.

procedure PontoConsisteMovtos:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    find first paramecp no-lock.
    
    create tmp-cpc-at1000-saida. 
    assign tmp-cpc-at1000-saida.lg-undo-retry           = no
           tmp-cpc-at1000-saida.lg-cria-guia            = yes
           tmp-cpc-at1000-saida.lg-comunica-scs         = yes
           tmp-cpc-at1000-saida.cd-local-autorizacao    = tmp-cpc-at1000-entrada.cd-local-autorizacao.               

    if tmp-cpc-at1000-entrada.cd-unidade-carteira   = paramecp.cd-unimed
    then return.
    
    if AtendeRegraNaoTrafegar (tmp-cpc-at1000-entrada.cd-tipo-guia)
    then do:
        assign tmp-cpc-at1000-saida.lg-comunica-scs = no
               tmp-cpc-at1000-saida.ds-observ-guia  = "CPC-AT1000-REGRA IED".
    end.  
end procedure.

procedure ProcessaCPC:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    message "Nome do ponto de chamada da CPC: " + tmp-cpc-at1000-entrada.nm-ponto-chamada-cpc.
    
    if  tmp-cpc-at1000-entrada.in-evento-programa   = 'INCLUI'   
    and tmp-cpc-at1000-entrada.nm-ponto-chamada-cpc = "CONSISTE-MOVTOS"
    then do:
        run PontoConsisteMovtos.
    end.    
    if  tmp-cpc-at1000-entrada.in-evento-programa   = 'INCLUI'   
    and tmp-cpc-at1000-entrada.nm-ponto-chamada-cpc = "APOS-AUTOR-AUTO"
    then do:
        run PontoAutorizacaoAutomatica.
    end.    
    if  tmp-cpc-at1000-entrada.in-evento-programa   = 'INCLUI'   
    and tmp-cpc-at1000-entrada.nm-ponto-chamada-cpc = "ATUALIZA-STATUS"
    then do:
        run PontoAtualizaStatus.
    end.    
end procedure.


/* ************************  Function Implementations ***************** */

function AtendeRegraNaoTrafegar returns logical 
	(in-tipo-guia          AS   INTEGER):
/*------------------------------------------------------------------------------
 Purpose: Verifica se a guia atende a regra que nÆo deve ser trafegada. Tratativas que impe‡am a regra  
          de trafegar deve ser inclu¡das nesta fun‡Æo.
 Notes:
------------------------------------------------------------------------------*/	
    define variable result as logical no-undo.
    
		
    PUT "PROCEDURE prEs22j" tmp-cpc-at1000-entrada.cd-tipo-guia ";" SKIP.

        /* TIPO DE GUIA */
        FOR EACH tip-guia USE-INDEX tip-gui1
           WHERE tip-guia.cd-tipo-guia   = tmp-cpc-at1000-entrada.cd-tipo-guia
             /*AND tip-guia.u-log-2        = YES /* CONFIGURADO NO es-22-j PARA RESTRINGIR A COMUNICACAO COM A UNIMED ORIGEM */*/
             NO-LOCK.

             PUT "tip-guia-yes" tip-guia.u-log-2 ";" SKIP.

              IF tip-guia.u-log-2 = YES THEN
              DO:

               PUT "tipo guia" tip-guia.cd-tipo-guia "campo" tip-guia.u-log-2 ";" SKIP.

                tmp-cpc-at1000-saida.lg-comunica-scs = NO.

                assign result   = yes.
              END.
              ELSE DO:
                 /* PROCEDIMENTO */
                  /* CONFIGURADO NO es-22-j PARA RESTRINGIR A COMUNICACAO COM A UNIMED ORIGEM */
                  FOR EACH tmp-cpc-at1000-movtos NO-LOCK.

                  PUT "proced1 " tmp-cpc-at1000-movtos.cd-procedimento ";" SKIP.

                    FOR EACH ambproce
                       WHERE (ambproce.cd-esp-amb           = INT(SUBSTRING(STRING(INT(tmp-cpc-at1000-movtos.cd-procedimento), "99999999"), 1, 2))
                         and ambproce.cd-grupo-proc-amb     = INT(SUBSTRING(STRING(INT(tmp-cpc-at1000-movtos.cd-procedimento), "99999999"), 3, 2))
                         and ambproce.cd-procedimento       = INT(SUBSTRING(STRING(INT(tmp-cpc-at1000-movtos.cd-procedimento), "99999999"), 5, 3))
                         and ambproce.dv-procedimento       = INT(SUBSTRING(STRING(INT(tmp-cpc-at1000-movtos.cd-procedimento), "99999999"), 8, 1))
                         AND ambproce.dat-fim-vigenc       >= TODAY)
                         NO-LOCK.
                         
                        PUT "ambproce.u-log-3 " ambproce.u-log-3  ";" tmp-cpc-at1000-saida.lg-comunica-scs SKIP.

                        IF ambproce.u-log-3 = YES THEN    
                        DO: 
                          PUT "procedimento es22j " ";" tmp-cpc-at1000-saida.lg-comunica-scs SKIP.
                    
                          tmp-cpc-at1000-saida.lg-comunica-scs  = NO.
                    
                          assign result   = yes.

                          PUT "procedimento es22j-02 " ";" tmp-cpc-at1000-saida.lg-comunica-scs SKIP.
                    
                        END.
                        ELSE DO:
                         /* TIPO INSUMOS */
                         /* CONFIGURADO NO es-22-j PARA RESTRINGIR A COMUNICACAO COM A UNIMED ORIGEM */
                         
                         FOR EACH tipoinsu
                             WHERE (tipoinsu.cd-tipo-insumo = tmp-cpc-at1000-movtos.cd-tipo-insumo
                               AND tipoinsu.u-log-1 = YES)
                               NO-LOCK.
                         
                             IF tipoinsu.u-log-1 = YES THEN
                             DO:
                         
                                PUT "TP insumo es22j " ";" tmp-cpc-at1000-saida.lg-comunica-scs SKIP.
                         
                                tmp-cpc-at1000-saida.lg-comunica-scs = NO.
                                
                                assign result   = yes.
                                
                             END.
                             ELSE DO:
                               /* INSUMOS */
                               /* CONFIGURADO NO es-22-j PARA RESTRINGIR A COMUNICACAO COM A UNIMED ORIGEM */
                               
                               FOR EACH insumos 
                                  WHERE (insumos.cd-tipo-insumo  = tmp-cpc-at1000-movtos.cd-tipo-insumo
                                    AND insumos.cd-insumo        = tmp-cpc-at1000-movtos.cd-insumo
                                    AND insumos.dat-fim-vigenc  >= TODAY
                                    AND insumos.u-log-1          = YES)
                                    NO-LOCK.
                               
                                     IF insumos.u-log-1 = YES THEN
                                     DO: 
                                      PUT "insumo es22j " ";" tmp-cpc-at1000-saida.lg-comunica-scs SKIP.
                               
                                      tmp-cpc-at1000-saida.lg-comunica-scs  = NO.
                               
                                      assign result   = yes.
                               
                                     END. /* INSUMOS */
                               END.
                             END. /* else do */
                         END.
                        END. /* PROCEDIMENTO */
                    END.
                  END.
              END.
        END. /* TIPO DE GUIA */
		
    return result.
end function.
